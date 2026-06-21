module ec.emit.api.APIEmitter;

import ec.all;
import common        : StringBuffer;
import common.utils  : as, firstNotNull, indexOf;

import std.stdio     : writefln;
import std.string    : toUpper;
import std.file      : write;
import std.algorithm : any, find, sort;

import ec.emit.api.StdStmtGenerator;
import ec.emit.api.StdTypeGenerator;

public {
    import ec.emit.api.LoaderGenerator;

    interface IStmtGenerator {
        alias ReturnType = Tuple!(bool, "consumed", string, "result");

        ReturnType doGenerate(Stmt stmt, APIEmitter base);
    }
    interface ITypeGenerator {
        alias ReturnType = Tuple!(bool, "consumed", string, "result");

        ReturnType doGenerate(Type type, APIEmitter base);
    }
}

final class APIEmitter : IEmitter {
public:
    enum State { LOADER, ALIASES, ENUMS, STRUCTS, UNIONS, GLOBALS }

    State state;
    string indent;

    this(string name) {
        this.name = name;
        this.stmtGenerators ~= new StdStmtGenerator(this);
        this.typeGenerators ~= new StdTypeGenerator(this);
    }
    auto addStmtGenerator(IStmtGenerator generator) {
        this.stmtGenerators ~= generator;
        return this;
    }
    auto addTypeGenerator(ITypeGenerator generator) {
        this.typeGenerators ~= generator;
        return this;
    }
    auto addLoaderGenerator(AbsLoaderGenerator loaderGenerator) {
        this.loaderGenerators ~= loaderGenerator;
        return this;
    }
    
    auto setHeaderText(string text) {
        this.headerText = text;
        return this;
    }
    auto setFooterText(string text) {
        this.footerText = text;
        return this;
    }
    auto setAliasPrefixes(string[] prefixes) {
        this.aliasPrefixes = prefixes;
        return this;
    }
    auto setTypePrefixes(string[] prefixes) {
        this.typePrefixes = prefixes;
        return this;
    }
    auto setFunctionPrefixes(string[] prefixes) {
        this.functionPrefixes = prefixes;
        return this;
    }
    auto setGlobalPrefixes(string[] prefixes) {
        this.globalPrefixes = prefixes;
        return this;
    }
    auto setExcludePrefixes(string[] prefixes) {
        this.excludePrefixes = prefixes;
        return this;
    }

    /** Implement IEmitter */
    override void emit(CFile cfile) {
        auto buf = new StringBuffer();

        void addSeparatorComment(string s) {
            auto len = s.length;
            auto w = 100;
            buf.add("\n");
            buf.add("// %s\n", repeat("=", w));
            buf.add("// %s%s\n", repeat(" ", w/2 - len/2), s);
            buf.add("// %s\n", repeat("=", w));
        }

        buf.add("%s\n", headerText);

        foreach(ch; cfile.children) {
            if(auto stmt = ch.as!Stmt) {
                extract(stmt);
            }
        }    

        // Sort
        enums.sort!((e1, e2) => e1.name < e2.name)();
        functions.sort!((f1, f2) => f1.name < f2.name)();
        structs.sort!((f1, f2) => f1.name < f2.name)();
        globals.sort!((f1, f2) => f1.name < f2.name)();

        // ================================= Load Shared Functions
        state = State.LOADER;
        foreach(loader; loaderGenerators) {
            loader.setFunctionNames(functions.map!(f => f.name).array());
            buf.add(loader.doGenerate());
        }

        // ================================= Aliases
        state = State.ALIASES;
        string[] aliasNames = aliases.keys().sort!((a,b)=>a.toLower()<b.toLower()).array();
        foreach(a; aliasNames) {
            string value = gen(aliases[a]);

            // alias name = name;
            if(a == value) continue;

            buf.add("alias %s = %s;\n", a, gen(aliases[a]));
        }

        // ================================= Enums
        if(enums.length > 0) {
            state = State.ENUMS;
            addSeparatorComment("Enums");
            foreach(en; enums) {
                buf.add("%s", gen(en));
            }
        }

        // ================================= Structs
        if(structs.length > 0) {
            state = State.STRUCTS;
            addSeparatorComment("Structs");
            foreach(s; structs) {
                if(string str = gen(s)) {
                    buf.add("%s\n", str);
                }
            }
        }

        // ================================= Unions
        if(unions.length > 0) {
            state = State.UNIONS;
            addSeparatorComment("Unions");
            foreach(u; unions) {
                if(string str = gen(u)) {
                    buf.add("%s\n", str);
                }
            }
        }

        // ================================= Global Functions
        state = State.GLOBALS;
        addSeparatorComment("Global Functions");

        Function[] windowsFunctions = functions.filter!((f) => f.callingConvention == CallingConvention.STDCALL).array();
        Function[] cFunctions = functions.filter!((f) => !f.callingConvention == CallingConvention.CDECL).array();

        if(windowsFunctions.length > 0) {
            buf.add("extern(Windows) { nothrow __gshared {\n\n");
            foreach(f; windowsFunctions) {
                buf.add("%s;\n", gen(f));
            }
            buf.add("\n}} // extern(Windows) nothrow __gshared\n\n");
        }

        if(cFunctions.length > 0) {
            buf.add("extern(C) { nothrow __gshared {\n\n");
            foreach(f; cFunctions) {
                buf.add("%s;\n", gen(f));
            }
            buf.add("\n}} // extern(C) nothrow __gshared\n\n");
        }

        if(globals.length > 0) {
            addSeparatorComment("Global Variables");
            foreach(g; globals) {
                if(g.storageClass.isStatic && g.type.modifiers.isConst && g.hasInitialiser) {
                    buf.add("enum %s %s = %s;\n", gen(g.type), g.name, gen(g.initialiser));
                } else {
                    buf.add("%s;\n", gen(g));
                }
            }
        }

        buf.add("%s\n", footerText);

        string outFile = cfile.config.targetDirectory ~ name.toLower() ~ "_api.d";
        write(outFile, buf.toString());
    }

    string gen(Stmt s) {
        foreach_reverse(g; stmtGenerators) {
            auto r = g.doGenerate(s, this);
            if(r.consumed) return r.result;
        }

        assert(false, "Unhandled stmt %s".format(s.estmt));
    }
    string gen(Type t) {
        foreach_reverse(g; typeGenerators) {
            auto r = g.doGenerate(t, this);
            if(r.consumed) return r.result;
        }

        assert(false, "Unhandled type %s".format(t.etype));
    }

    void pushIndent() {
        this.indent ~= "    ";
    }
    void popIndent() {
        assert(indent.length > 0);
        this.indent = this.indent[0..$-4];
    }

    static bool requiresSemicolon(Var v) {
        return v && !extractStruct(v.type) && !extractUnion(v.type);
    }
    static string dname(string name) {
        switch(name) {
            case "align":
            case "function":
            case "in":
            case "module":
            case "out":
            case "ref":
            case "scope":
            case "string":
            case "version":
                return name ~ "_";
            default: 
                return name;
        }
    }
    static string stringOf(Type t) {
        string s = t.modifiers.isUnsigned ? "u" : "";
        switch(t.etype) {
            case EType.BOOL: return "bool";
            case EType.CHAR: return s ~ "char";
            case EType.SHORT: return s ~ "short";
            case EType.INT: return s ~ "int";
            case EType.LONG:
            case EType.INT64: 
                return s ~ "long";
            case EType.FLOAT: return "float";
            case EType.DOUBLE: 
            case EType.LONG_DOUBLE: 
                return "double";
            case EType.VOID: return "void";
            case EType.VARARG:
                return "...";
            default: assert(false, "Handle type %s".format(t.etype));
        }
    }
    
//#####################################################################################################################
//#####################################################################################################################
//#####################################################################################################################
//#####################################################################################################################
//#####################################################################################################################
private:
    const string name;

    string headerText;
    string footerText;
    string[] aliasPrefixes;
    string[] functionPrefixes;
    string[] typePrefixes;
    string[] globalPrefixes;
    string[] excludePrefixes;
    AbsLoaderGenerator[] loaderGenerators;
    IStmtGenerator[] stmtGenerators;
    ITypeGenerator[] typeGenerators;

    // Extracted data
    Function[] functions;
    Enum[] enums;
    Struct[] structs;
    Union[] unions;
    Type[string]aliases;
    Var[] globals;

    void extract(Stmt stmt) {

        bool exclude(string name) {
            return excludePrefixes.any!(it=>name.startsWith(it));
        }
        void addAlias(string name, Type type) {
            if(!exclude(name) && aliasPrefixes.any!(it=>name.startsWith(it))) {
                aliases[name] = type;
            }
        }
        void addFunction(Function f) {
            if(functionPrefixes.any!(it=>f.name.startsWith(it))) {
                functions ~= f;
            }
        }
        void addStruct(Struct s) {
            if(!exclude(s.name) && typePrefixes.any!(it=>s.name.startsWith(it))) {

                int prevIndex = structs.indexOf((Struct it)=>it.name == s.name);

                if(prevIndex != -1) {
                    // If this is a definition then replace any previous one we have seen
                    // otherwise ignore it because we already have something as good or better
                    if(s.hasBody) {
                        structs[prevIndex] = s;
                    }    
                    return;
                } 

                structs ~= s;
            }
        }
        void addEnum(Enum e) {
            if(!exclude(e.name) && typePrefixes.any!(it=>e.name.startsWith(it))) {
                enums ~= e;
            }
        }
        void addUnion(Union u) {
            if(!exclude(u.name) && typePrefixes.any!(it=>u.name.startsWith(it))) {
                unions ~= u;
            }
        }
        void addGlobal(Var v) {
            if(!exclude(v.name) && globalPrefixes.any!(it=>v.name.startsWith(it))) {
                globals ~= v;
            }
        }

        switch(stmt.estmt) {
            case EStmt.ENUM:
                auto e = stmt.as!Enum;
                addEnum(e);
                break;
            case EStmt.FUNC:
                auto f = stmt.as!Function;
                addFunction(f);
                break;
            case EStmt.STRUCT:
                auto s = stmt.as!Struct;
                addStruct(s);
                break;
            case EStmt.TYPEDEF:
                auto td = stmt.as!Typedef;

                if(td.type.etype == EType.ENUM) {

                    Enum e = td.type.as!Enum;
                    if(auto tr = td.type.as!TypeRef) {
                        e = tr.nodeRef.as!Enum;
                    }
                    if(e) {
                        if(e.name is null) e.name = td.name;

                        // Use the typedef name for the enum
                        e.name = td.name;

                        addEnum(e);
                    } else {
                        addAlias(td.name, td.type);
                    }
                } else if(td.type.etype == EType.STRUCT) {
                    Struct s = td.type.as!Struct;

                    if(auto tr = td.type.as!TypeRef) {

                        if(!tr.typeRef && !tr.nodeRef) {
                            // This is an alias name = name;
                            addAlias(td.name, td.type);

                            s = new Struct(EStmt.STRUCT, Location());
                            s.name = tr.name;

                        } else if(tr.nodeRef) {
                            s = tr.nodeRef.as!Struct;
                        } else {
                            addAlias(td.name, td.type);
                        }
                    }
                    if(s) {
                        if(s.name is null) s.name = td.name;
                        addStruct(s);
                    }
                } else if(td.type.etype == EType.UNION) {
                    Union u = td.type.as!Union;

                    if(auto tr = td.type.as!TypeRef) {
                        u = tr.nodeRef.as!Union;
                    }
                    if(u) {
                        addUnion(u);
                    }
                } else if(auto f = td.type.as!FunctionPtr) {
                    addAlias(td.name, td.type);
                } else {
                    addAlias(td.name, td.type);
                }
                break;
            case EStmt.UNION:
                auto u = stmt.as!Union;
                addUnion(u);
                break;
            case EStmt.PRAGMA:
                break;
            case EStmt.VAR:
                addGlobal(stmt.as!Var);
                break;
            default: 
                assert(false, "Handle stmt %s".format(stmt.estmt));
        }
    }
}

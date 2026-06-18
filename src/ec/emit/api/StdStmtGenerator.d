module ec.emit.api.StdStmtGenerator;

import std.algorithm : maxElement;
import std.string    : toUpper, endsWith;
import std.conv      : to;
import ec.all;

final class StdStmtGenerator : IStmtGenerator {
public:
    // If true will emit proper bitfields, otherwise will assume bitfields are not supported 
    // and will create getters and setters instead
    bool useColonBitfields = false;

    this(APIEmitter emitter) {
        this.base = emitter;
    }

    ReturnType doGenerate(Stmt s, APIEmitter base) {
        string result;
        switch(s.estmt) {
            case EStmt.CAST: result = this.doGenerate(s.as!Cast); break;
            case EStmt.ENUM: result = this.doGenerate(s.as!Enum); break;
            case EStmt.IDENTIFIER: result = this.doGenerate(s.as!Identifier); break;
            case EStmt.INFIX: result = this.doGenerate(s.as!Infix); break;
            case EStmt.NUMBER: result = this.doGenerate(s.as!Number); break;
            case EStmt.FUNC: result = this.doGenerate(s.as!Function); break;
            case EStmt.PARENS: result = this.doGenerate(s.as!Parens); break;
            case EStmt.PREFIX: result = this.doGenerate(s.as!Prefix); break;
            case EStmt.STRUCT: result = this.doGenerate(s.as!Struct); break;
            case EStmt.UNION: result = this.doGenerate(s.as!Union); break;
            case EStmt.VAR: result = this.doGenerate(s.as!Var); break;

            default: assert(false, "Handle expr %s".format(s.estmt));
        }

        return ReturnType(true, result);
    }
private:
    APIEmitter base;

    string doGenerate(Cast c) {
        return "cast(%s)%s".format(base.gen(c.type), base.gen(c.expr));
    }
    string doGenerate(Enum e) {
        // QUALIFIED enums
        string s = "enum %s {\n".format(e.name);

        int longestName = e.members.map!(it=>it.label.length).maxElement().as!int;

        foreach(i, m; e.members) {
            if(m.exprIndex == -1) {
                s ~= "    %s,\n".format(m.label);
            } else {
                string pad     = " ".repeat(longestName - m.label.length.as!int);
                string castStr = i == 0 && !e.children[m.exprIndex].isA!Number ? "cast(int)" : "";
                s ~= "    %s%s = %s%s,\n".format(m.label, pad, castStr, base.gen(e.children[m.exprIndex].as!Expr));
            }
        }

        s ~= "}\n";

        // UNQUALIFIED enums
        if(e.members.length > 0) {

            s ~= "enum {\n";

            foreach(m; e.members) {
                string pad = " ".repeat(longestName - m.label.length.as!int);
                s ~= "    %s%s = %s.%s,\n".format(m.label, pad, e.name, m.label);
            }   

            s ~= "}\n";
        }
        s ~= "\n";

        return s;   
    }
    string doGenerate(Function f) {
        string returnTypeString = base.gen(f.returnType);
        string paramString = f.params.map!(it=>base.gen(it)).join(", ");

        return "%s function(%s) %s".format(returnTypeString, paramString, f.name);
    }
    string doGenerate(Identifier i) {
        return i.name;
    }
    string doGenerate(Infix i) {
        return "%s %s %s".format(base.gen(i.left), i.op.stringOf(), base.gen(i.right));
    }
    string doGenerate(Number n) {
        string s = n.stringValue;
        if(s.toLower().endsWith("ull")) {
            s = s[0..$-1];
        }
        return s;
    }
    string doGenerate(Parens p) {
        return "(%s)".format(base.gen(p.expr));
    }
    string doGenerate(Prefix p) {
        return "%s%s".format(p.op.stringOf(), base.gen(p.expr));
    }
    string doGenerate(Struct st) {
        string name = st.name ? "%s ".format(st.name) : "";
        string s = "struct %s{\n".format(name);

        if(!useColonBitfields && st.hasBitfields()) {
            // There are bitfields in this struct and we need to hack the bitfields (sadly)
            s ~= generateStructVarsWithBitfields(st);
        } else {
            // There are no bitfields in this struct or we are emitting proper colon bitfields

            base.pushIndent();

            foreach(m; st.body()) {

                s ~= "%s%s".format(base.indent, base.gen(m));

                if(m.isA!Var) {
                    s ~= ";";
                } 
                // if(base.requiresSemicolon(v)) s ~= ";";
                s ~= "\n";
            }

            base.popIndent();
        }

        s ~= "%s}".format(base.indent);
        return s;
    }
    string doGenerate(Union u) {
        string name = u.name ? "%s ".format(u.name) : "";
        string s = "union %s{\n".format(name);

        base.pushIndent();
        foreach(m; u.body()) {
            s ~= "%s%s".format(base.indent, base.gen(m.as!Stmt));
            if(base.requiresSemicolon(m.as!Var)) s ~= ";";
            s ~= "\n";
        }
        base.popIndent();
        s ~= "%s}".format(base.indent);
        return s;
    }
    string doGenerate(Var v) {

        bool displayName = !v.type.hasEmbeddedName && !extractStruct(v.type) && !extractUnion(v.type);

        string nameString = displayName ? " %s".format(base.dname(v.name)) : "";
        string typeString = base.gen(v.type);
        string exprString;
        string bfString = v.hasBitfield && useColonBitfields ? " : %s".format(base.gen(v.bitfield)) : "";

        if(v.isParam) {
            // (void) -> ()
            if(v.type.isVoidValue()) typeString = "";

            // Assume an array decays to a pointer 
            if(v.type.etype == EType.ARRAY && !v.type.isPtr()) { 
                if(auto ar = v.type.as!ArrayType) {
                    ar.varName = null;

                    // Slightly hacky. If the array is type[] without a size, don't emit the square brackets
                    Expr[] dims = ar.dimensionExprs();
                    if(dims.length == 1 && dims[0].isA!Number && dims[0].as!Number.stringValue == "-1") {
                        typeString = base.gen(ar.elementType());
                    } else {
                        typeString = base.gen(v.type);
                    }
                    typeString ~= "* ";
                    nameString = base.dname(v.name);
                }
            }
        } 

        if(v.hasInitialiser) {
            exprString = " = %s".format(base.gen(v.initialiser));
        } else {
            // Add zero initialiser for floats and doubles
            if(v.parent.isA!Struct && !v.type.isPtr() && (v.type.etype == EType.FLOAT || v.type.etype == EType.DOUBLE)) {
                exprString = " = 0";
            }
        }

        return "%s%s%s%s".format(typeString, nameString, bfString, exprString);
    }

    string generateStructVarsWithBitfields(Struct st) {
        string s;

        struct BF {
            Var v;
            string fieldName;
            uint startBit;
            uint numBits;
            Var storageVar;
        }

        Var[] variables = st.varRange().array();
        uint numStorageVars = 0;
        Var storageVar;
        int storageVarIndex = -1;
        uint size;
        uint bitOffset;
        BF[] bitfields;

        string bail(string msg) {
            writefln("[WARN] struct %s %s. This is not currently supported and the emitted struct will need to be manually repaired.", st.name, msg);
            return s;
        }
        int numBytes(Type t) {
            switch(t.etype) {
                case EType.BOOL: 
                case EType.CHAR: 
                    return 1;
                case EType.SHORT:
                    return 2;
                case EType.INT:
                    return 4;
                case EType.INT64:
                    return 8;        
                default: assert(false, "Handle bitfield type %s".format(t));
            }
        }

        foreach(i, v; variables) {

            string indent = "    ";

            if(v.hasBitfield) {
                if(v.hasInitialiser) {
                    return bail("has bitfields with initialisers");
                }

                string fieldName = v.name;

                if(storageVarIndex == -1) {
                    // this is the start of 1 or more bitfields  

                    storageVarIndex = i.as!int;
                    storageVar = v;
                    size = numBytes(v.type) * 8;            
                    bitOffset = 0;
                    v.name = "_bf%s".format(numStorageVars++);

                    // If the storage type is a bool we need to make it a char instead
                    bool changeStorageType = v.type.etype == EType.BOOL; 
                    if(changeStorageType) {
                        v.type.etype = EType.CHAR;
                    }

                    s ~= "%s%s;\n".format(indent, base.gen(v));

                } else {
                    // This is a subsequent bitfield

                    if(bitOffset > size) {
                        return bail("has bitfields that span multiple storage variables");
                    }

                    if(bitOffset == size) {
                        // Output the next storage var
                        storageVarIndex++;
                        storageVar = variables[storageVarIndex];
                        storageVar.name = "_bf%s".format(numStorageVars++);
                        size = numBytes(storageVar.type) * 8;                  
                        bitOffset = 0;

                        s ~= "%s%s;\n".format(indent, base.gen(storageVar));
                    }
                }

                uint numBits;
                if(v.bitfield().isA!Number) {
                    numBits = v.bitfield().as!Number.stringValue.to!int;
                } else {
                    return bail("bitfield is not a Number");
                }
                bitfields ~= BF(v, fieldName, bitOffset, numBits, storageVar);
                bitOffset += numBits;

            } else {
                // Reset 
                storageVarIndex = -1;

                s ~= "%s%s".format(indent, base.gen(v));
                if(base.requiresSemicolon(v)) s ~= ";";
                s ~= "\n";
            }
        }

        // Add bitfield getters and setters
        if(bitfields.length > 0) {
            s ~= "\n    // bitfield getters\n";

            foreach(bf; bitfields) {
                string name = base.dname(bf.fieldName);
                string storageName = base.dname(bf.storageVar.name);
                uint shr = bf.startBit;
                uint and = (1 << bf.numBits) - 1;
                name = "%s%s".format(name[0..1].toUpper(), name[1..$]);

                s ~= "    %s".format(base.gen(bf.v.type));

                s ~= " get%s".format(name);
                s ~= "() { return cast(";
                s ~= base.gen(bf.v.type);
                s ~= ")((%s >>> %s) & 0x%08x); }\n".format(storageName, shr, and);
            }

            s ~= "\n    // bitfield setters\n";
            foreach(bf; bitfields) {
                string name = base.dname(bf.fieldName);
                string storageName = base.dname(bf.storageVar.name);
                uint shr = bf.startBit;
                uint and = (1 << bf.numBits) - 1;
                name = "%s%s".format(name[0..1].toUpper(), name[1..$]);

                s ~= "    void set%s(".format(name);
                s ~= base.gen(bf.v.type);

                s ~= " value) { %s = cast(".format(storageName);
                s ~= base.gen(bf.storageVar.type);
                s ~= ")";
                s ~= "(%s & 0x%08x) | ((value & 0x%x) << %s); }\n".format(storageName, ~(and << shr), and, shr);  
            }
        }
        return s;
    }
}

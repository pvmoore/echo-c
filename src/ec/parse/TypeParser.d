module ec.parse.TypeParser;

import ec.all;

Tuple!(bool, "result", Type, "type", int, "pos") isType(Node parent, Tokens tokens, int offset = 0) {
    log("isType: %s", tokens.token());

    tokens.pushState();
    scope(exit) tokens.popState();

    tokens.pos += offset;

    if(Type t = parseType(parent, tokens, false)) {
        return tuple!("result", "type", "pos")(true, t, tokens.pos);
    }
    return tuple!("result", "type", "pos")(false, null.as!Type, 0);
}

Type parseType(Node parent, Tokens tokens, bool required = true) {
    log("parseType: %s", tokens.token());

    // this will be null if parent is not a typedef
    Typedef td = parent.as!Typedef; 

    // Parse the modifiers on the left side of the type
    TypeModifiers q = parseModifiers(tokens);

    Type type = parseSimpleType(tokens);

    if(!type && tokens.matches("struct")) {
        type = parseStruct(tokens);
    }
    if(!type && tokens.matches("union")) {
        type = parseUnion(tokens);
    }
    if(!type && tokens.matches("enum")) {
        type = parseEnum(tokens);
    }
    if(!type) {
        type = parseTypedef(tokens);
    }

    // Assume 'unsigned' is an int
    if(!type && q.isUnsigned) {
        type = new SimpleType(EType.INT);
    }

    if(!type) {
        if(required) {
            syntaxError(tokens.cfile, tokens.token(), "Expected type, got %s".format(tokens.text()));
        } else {
            return null;
        }
    }
    assert(type);

    // Parse the modifiers on the right side of the type. These are equivalent:
    //   <TYPE> const volatile unsigned signed 
    //   const volatile unsigned signed <TYPE>
    type.modifiers.mergeFrom(q);
    type.modifiers.mergeFrom(parseModifiers(tokens));

    // const*volatile*restrict***
    type.ptrs = parsePtrFlags(tokens);

    // Type name(
    // Type decl name(
    if(td !is null &&
       (tokens.matches(TKind.IDENTIFIER, TKind.LPAREN) ||
        tokens.matches(TKind.IDENTIFIER, TKind.IDENTIFIER, TKind.LPAREN))) 
    {
        // Switch type to a function declaration type
        type = parseFunctionDecl(tokens, type);
        td.nameIsEmbedded = true;
        return type;
    }

    if(tokens.matches(TKind.IDENTIFIER, TKind.LSQUARE)) {
        // Switch type to an ArrayType with the current type as the element type
        type = parseArrayType(parent, tokens, type);
        if(td !is null) {
            td.nameIsEmbedded = true;
        }
    }

    // Type (*name)(Type, Type, ...)
    if(tokens.matches(TKind.LPAREN)) {
        // Switch type to a function pointer type
        type = parseFunctionPtr(parent, tokens, type);
        if(td !is null) {
            td.nameIsEmbedded = true;
        }
    }

    log("returning type = %s", type);

    return type;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

Type parseSimpleType(Tokens tokens) {
    Type t;
    if(tokens.kind() == TKind.ELIPSIS) {
        t = new SimpleType(EType.VARARG);
        tokens.next();
        return t;
    }
    switch(tokens.text()) {
        case "void": t = new SimpleType(EType.VOID); break;
        case "bool":
        case "_Bool":   // c99
            // ms - bool is signed 
            t = new SimpleType(EType.BOOL); 
            break;
        case "char":
        case "__int8": 
            t = new SimpleType(EType.CHAR); break;
        // case "wchar_t":
        // case "__wchar_t":
        //     // ms specific
        //     q.isUnsigned = true;
        //     t = new SimpleType(EType.SHORT); 
        //     break;
        case "short":
        case "__int16": 
            t = new SimpleType(EType.SHORT); break;
        case "int":
        case "__int32": 
            t = new SimpleType(EType.INT); break;
        case "long": 
            if(tokens.text(1) == "double") {
                tokens.next();
                t = new SimpleType(EType.LONG_DOUBLE);
            } else if(tokens.text(1) == "long") {
                // long long
                tokens.next();
                t = new SimpleType(EType.INT64);
            } else {
                t = new SimpleType(EType.LONG);
            }
            break;
        case "float": t = new SimpleType(EType.FLOAT); break;
        case "double": t = new SimpleType(EType.DOUBLE); break;
        case "__int64": t = new SimpleType(EType.INT64); break;
        default: break;
    }
    if(t) tokens.next();
    return t;
}

Type parseTypedef(Tokens tokens) {
    CFile cfile = tokens.cfile;
    if(Typedef td = cfile.typedefs.get(tokens.text(), null)) {
        tokens.next();
        return new TypeRef(td.name, td.type);
    }
    return null;
}

/**
 * Type [ cc ] name '(' { Type [ name ] } ')'
 */
Type parseFunctionDecl(Tokens tokens, Type returnType) {

    auto cc = parseCallingConvention(tokens);

    Function fn = parseFunctionDeclaration(tokens, returnType, cc);

    TypeRef rt = new TypeRef(fn.name, EType.FUNCTION_DECL);
    rt.add(fn);
    rt.nodeRef = fn;

    return rt;
}

/**
 * STRUCT ::= 'struct' [ modifiers ] [ name ] [ BODY ]
 * BODY   ::= '{' { Stmt } '}'
 */
Type parseStruct(Tokens tokens) {
    tokens.skip("struct");

    auto modifiers = parseModifiers(tokens);

    string name;
    if(tokens.matches(TKind.IDENTIFIER)) {
        name = tokens.text(); tokens.next();
    }

    TypeRef type = new TypeRef(name, EType.STRUCT);
    type.modifiers = modifiers;

    if(tokens.matches(TKind.LBRACE)) {
        tokens.next();

        // This is a definition
        Struct struct_ = tokens.make!Struct();
        struct_.name = type.name;
        struct_.hasBody = true;

        type.nodeRef = struct_;

        type.add(struct_);

        while(!tokens.matches(TKind.RBRACE)) {
            parseStmt(struct_, tokens);
        }
        tokens.skip(TKind.RBRACE);
    } else {
        // This is struct <name>;
    }

    return type;
}

/**
 * UNION ::= 'union' [ modifiers ] [ name ] [ BODY ]
 * BODY   ::= '{' { Stmt } '}'
 */
Type parseUnion(Tokens tokens) {
    tokens.skip("union");

    auto modifiers = parseModifiers(tokens);

    string name;
    if(tokens.matches(TKind.IDENTIFIER)) {
        name = tokens.text(); tokens.next();
    }

    TypeRef type = new TypeRef(name, EType.UNION);
    type.modifiers = modifiers;

    if(tokens.matches(TKind.LBRACE)) {
        tokens.next();

        // This is a definition
        Union union_ = tokens.make!Union();
        union_.name = type.name;
        union_.hasBody = true;

        type.nodeRef = union_;

        type.add(union_);

        while(!tokens.matches(TKind.RBRACE)) {
            parseStmt(union_, tokens);
        }
        tokens.skip(TKind.RBRACE);
    } else {
        // This is union <name>;
    }

    return type;
}

Type parseEnum(Tokens tokens) {
    tokens.skip("enum");

    auto modifiers = parseModifiers(tokens);

    string name;
    if(tokens.matches(TKind.IDENTIFIER)) {
        name = tokens.text(); tokens.next();
    }

    TypeRef type = new TypeRef(name, EType.ENUM);
    type.modifiers = modifiers;

    if(tokens.matches(TKind.LBRACE)) {
        tokens.next();

        // This is a definition
        Enum enum_ = tokens.make!Enum();
        enum_.name = type.name;
        enum_.hasBody = true;

        type.nodeRef = enum_;

        type.add(enum_);

        while(!tokens.matches(TKind.RBRACE)) {
            if(tokens.matches(TKind.IDENTIFIER, TKind.EQUALS)) {
                Enum.Member m = {
                    label: tokens.text(),
                    exprIndex: enum_.numChildren()
                };
                enum_.members ~= m;
                tokens.next(2);
                parseExpr(enum_, tokens);
            } else {
                Enum.Member m = {
                    label: tokens.text(),
                    exprIndex: -1
                };
                enum_.members ~= m;
                tokens.next();
            }
            if(tokens.matches(TKind.COMMA)) {
                tokens.next();
            }
        }
        tokens.skip(TKind.RBRACE);
    } else {
        // This is enum <name>;
    }

    return type;
}

/**
 * Type (__cdecl* name)'(' { params } ')'
 *
 * typedef int (__cdecl* name)(void*, void const*, void const*)
 * void (*name[2])(int);
 * extern void (*signal(int, void(*)(int)))(int)
 */
Type parseFunctionPtr(Node parent, Tokens tokens, Type returnType) {
    tokens.skip(TKind.LPAREN);

    FunctionPtr fp = new FunctionPtr();
    
    // This is the Type we will return. It will be fp unless this is an array function pointer
    // in which case it will be an ArrayType with fp as the element type
    Type typeToReturn = fp;

    fp.returnType = returnType;

    fp.callingConvention = parseCallingConvention(tokens);
    fp.ptrs = parsePtrFlags(tokens);

    // Optional name if this is a parameter type
    if(tokens.kind() == TKind.IDENTIFIER) {
        fp.varName = tokens.text(); tokens.next();
    } 

    if(tokens.kind() == TKind.LSQUARE) {
        todo("parse array function pointer type");

        typeToReturn = parseArrayType(parent, tokens, fp);
        // At this point typeToReturn will be an ArrayType and 'fp' will be the element type of the array
        // but we still need to parse the parameters
    }

    tokens.skip(TKind.RPAREN);
    tokens.skip(TKind.LPAREN);

    auto p = tokens.make!Parens();
    while(!tokens.isEof() && !tokens.matches(TKind.RPAREN)) {
        parseParamVar(p, tokens);

        if(tokens.kind() == TKind.COMMA) {
            tokens.next(); // skip the comma
        }
    }
    tokens.skip(TKind.RPAREN);

    fp.params = p.children.as!(Var[]);

    // Return either fp or the array type
    return typeToReturn;
}

/**
 * Type { '[' [ Expr ] ']' }
 */
Type parseArrayType(Node parent, Tokens tokens, Type type) {

    log("parseArrayType: %s %s", type, tokens.token());

    ArrayType at = new ArrayType();

    // Set the element type as the first child
    at.add(type);

    if(tokens.matches(TKind.IDENTIFIER)) {
        at.varName = tokens.text(); tokens.next();
    }

    // Possible multiple array dimensions
    while(tokens.kind() == TKind.LSQUARE) {
        tokens.skip(TKind.LSQUARE);

        if(tokens.matches(TKind.RSQUARE)) {
            // Add a temporary -1 number here which we can replace later when we know the size
            auto num = tokens.make!Number();
            num.stringValue = "-1";
            at.add(num);
        } else {
            parseExpr(at, tokens);
        }
        tokens.skip(TKind.RSQUARE);
    }

    return at;
}

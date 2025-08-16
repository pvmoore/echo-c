module ec.parse.TypeParser;

import ec.all;

struct ParseTypeResult {
    Type type;
    string name;
    int pos;

    bool hasType() { return type !is null; }
    bool hasName() { return name !is null; }

    string toString() { return "(%s) %s name=%s".format(className(type), type, name); }
}

ParseTypeResult isType(Node parent, Tokens tokens, int offset = 0) {
    log("isType: %s", tokens.token());

    tokens.pushState();
    scope(exit) tokens.popState();

    tokens.pos += offset;

    return parseType(parent, tokens, false);
}

ParseTypeResult parseType(Node parent, Tokens tokens, bool required = true) {
    log("parseType: %s", tokens.token());

    Type type;
    string name;

    // Parse the modifiers on the left side of the type
    TypeModifiers q = parseModifiers(tokens);

    type = parseSimpleType(tokens);

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
            return ParseTypeResult();
        }
    }
    assert(type);

    // Parse the modifiers on the right side of the type. These are equivalent:
    //   <TYPE> const volatile unsigned signed 
    //   const volatile unsigned signed <TYPE>
    type.modifiers.mergeFrom(q);
    type.modifiers.mergeFrom(parseModifiers(tokens));

    // const*volatile*restrict***
    type.ptrs ~= parsePtrFlags(tokens);

    // Brackets are allowed here which makes the type look like a bit like a function ptr
    //
    // Type (*((*foo)))  (void);     -> Type  (**foo)(void)
    // Type (* ((*foo)) (void) );    -> Type* (*foo)(void)
    // Type ((*(*foo)));             -> Type** foo;
    // Type (* ((*foo)));            -> Type** foo
    //      ^
    //      |
    //    we are here
    int skipParens = 0;
    while(tokens.matches(TKind.LPAREN)) {

        if(isFunctionPtr(tokens)) {
            // Switch type to a function pointer type
            auto tan = parseFunctionPtr(parent, tokens, type);

            foreach(i; 0..skipParens) {
                tokens.skip(TKind.RPAREN);
            }
            tan.pos = tokens.pos;

            log("returning type = %s", tan);
            return tan;

        } else {
            tokens.skip(TKind.LPAREN);
            skipParens++;

            // const*volatile*restrict***
            type.ptrs ~= parsePtrFlags(tokens);
        }
    }

    log("parseType: type = %s", ParseTypeResult(type, name, tokens.pos));

    // Type name(
    // Type decl name(
    if(parent.isA!Typedef &&
       (tokens.matches(TKind.IDENTIFIER, TKind.LPAREN) ||
        tokens.matches(TKind.IDENTIFIER, TKind.IDENTIFIER, TKind.LPAREN))) 
    {
        // Switch type to a function declaration type
        auto tan = parseFunctionDecl(tokens, type);

        foreach(i; 0..skipParens) {
            tokens.skip(TKind.RPAREN);
        }
        tan.pos = tokens.pos;

        log("returning function decl = %s", tan);
        return tan;
    }

    if(tokens.matches(TKind.IDENTIFIER, TKind.LSQUARE)) {
        // Switch type to an ArrayType with the current type as the element type
        auto tan = parseArrayType(parent, tokens, type);
        type = tan.type;
        name = tan.name;
    }

    if(skipParens > 0 && tokens.matches(TKind.IDENTIFIER)) {
        name = tokens.text(); tokens.next();
    }

    foreach(i; 0..skipParens) {
        tokens.skip(TKind.RPAREN);
    }

    log("returning type %s", ParseTypeResult(type, name, tokens.pos));

    return ParseTypeResult(type, name, tokens.pos);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/**
 * (*name)( { Type params } )
 */
bool isFunctionPtr(Tokens tokens) {
    if(!tokens.matches(TKind.LPAREN)) return false;

    int end = tokens.findClosingBracket(0);
    if(end == -1) return false;

    // Look for parameter list
    return tokens.kind(end + 1) == TKind.LPAREN;
}

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
ParseTypeResult parseFunctionDecl(Tokens tokens, Type returnType) {

    auto cc = parseCallingConvention(tokens);

    Function fn = parseFunctionDeclaration(tokens, returnType, cc);

    TypeRef rt = new TypeRef(fn.name, EType.FUNCTION_DECL);
    rt.add(fn);
    rt.nodeRef = fn;

    return ParseTypeResult(rt, fn.name, tokens.pos);
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

        while(!tokens.matchesOneOf(TKind.RBRACE, TKind.NONE)) {
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

        while(!tokens.matchesOneOf(TKind.RBRACE, TKind.NONE)) {
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

        while(!tokens.matchesOneOf(TKind.RBRACE, TKind.NONE)) {
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
ParseTypeResult parseFunctionPtr(Node parent, Tokens tokens, Type returnType) {
    log("parseFunctionPtr: return type = %s %s", returnType, tokens.token());

    assert(tokens.matches(TKind.LPAREN));

    ParseTypeResult result;
    FunctionPtr fp = new FunctionPtr();

    // There may be more than one of these
    int numParens = 0;
    CallingConvention cc = CallingConvention.DEFAULT;

    while(tokens.matches(TKind.LPAREN)) {
        numParens++;
        tokens.next();

        if(auto cc2 = parseCallingConvention(tokens)) {
            cc = cc2;
        }
        fp.ptrs ~= parsePtrFlags(tokens);
    }
    
    // This is the Type we will return. It will be fp unless this is an array function pointer
    // in which case it will be an ArrayType with fp as the element type
    result.type = fp;

    fp.returnType = returnType;
    fp.callingConvention = cc;

    // Optional name if this is a parameter type
    if(tokens.kind() == TKind.IDENTIFIER) {
        fp.varName = tokens.text(); tokens.next();
        result.name = fp.varName;
    } 

    if(tokens.kind() == TKind.LSQUARE) {

        auto tan = parseArrayType(parent, tokens, fp);
        result.type = tan.type;
        // At this point result.type will be an ArrayType and 'fp' will be the element type of the array
        // but we still need to parse the parameters
    }

    // Usually there is 1 of these but there could be more
    foreach(i; 0..numParens) {
        tokens.skip(TKind.RPAREN);
    }

    // Parameters
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

    result.pos = tokens.pos;
    // Return either fp or the array type
    return result;
}

/**
 * Type { '[' [ Expr ] ']' }
 */
ParseTypeResult parseArrayType(Node parent, Tokens tokens, Type type) {
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

    return ParseTypeResult(at, at.varName, tokens.pos);
}

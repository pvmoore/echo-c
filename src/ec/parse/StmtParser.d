module ec.parse.StmtParser;

import ec.all;

void parseCFile(CFile cfile) {

    log("Parsing %s", cfile.filename);
    Tokens tokens = new Tokens(cfile);

    int count;
    int pos = 0;

    while(!tokens.isEof()) {
        log("parseStmt %s %s", count, tokens.token());
        parseStmt(cfile, tokens);
        
        throwIf(tokens.pos == pos, "we made no progress %s", tokens.token());
        pos = tokens.pos; 
        if(count++ > 5660) break;

    }
    log("done");
}
void parseStmt(Node parent, Tokens tokens) {
    log("parseStmt %s", tokens.token());

    if(tokens.kind() == TKind.SEMI_COLON) {
        // Empty statement
        tokens.next();
        return;
    }
    log("parseStmt %s", tokens.token());

    // extern | static | __declspec
    StorageClass storageClass = parseStorageClass(tokens);

    auto t = isType(parent, tokens);
    if(t.result) {
        log("parseStmt: found type %s", t.type);
        // We found a type. Move forward ...
        tokens.pos = t.pos;

        // Type id (
        // Type id id (
        bool isFunc = tokens.matches(TKind.IDENTIFIER, TKind.LPAREN) || 
                      tokens.matches(TKind.IDENTIFIER, TKind.IDENTIFIER, TKind.LPAREN);
        if(isFunc) {
            parseFunc(parent, tokens, t.type, storageClass);
            return;
        }

        // This might be a Struct, Enum or Union definition
        TypeRef tr = t.type.as!TypeRef;
        if(tr && !tokens.matches(TKind.IDENTIFIER)) {
            if(tr.hasChildren()) {
                Stmt def = t.type.first().as!Stmt;
                parent.add(def);
                return;
            } else {
                // struct <name>;
                // enum <name>;
                // union <name>;
                parent.add(tr);
                return;
            }
        }

        parseVar(parent, tokens, t.type, storageClass);
        return;
    }

    switch(tokens.kind()) {
        case TKind.IDENTIFIER:
            if(tokens.kind(1) == TKind.COLON) {
                parseLabel(parent, tokens);
                return;
            }

            switch(tokens.text()) {
                case "__pragma": parse__pragma(parent, tokens); return;
                case "typedef": parseTypedef(parent, tokens); return;
                case "return": parseReturn(parent, tokens); return;
                case "if": parseIf(parent, tokens); return;
                case "for": parseFor(parent, tokens); return;
                case "do": parseDoWhile(parent, tokens); return;
                case "while": parseWhile(parent, tokens); return;
                case "break": parseBreak(parent, tokens); return;
                case "continue": parseContinue(parent, tokens); return;
                case "switch": parseSwitch(parent, tokens); return;
                default: break;
            }
            break;
        case TKind.HASH: parseHash(parent, tokens); return;
        case TKind.LBRACE: parseScope(parent, tokens); return;
        default: break;
    }

    // if we get here then it must be an Expr
    parseExpr(parent, tokens);
}

/**
 * Type [ name ] [ , ) ]
 */
void parseParamVar(Node parent, Tokens tokens) {
    log("parseParamVar %s", tokens.token());
    Var var = tokens.make!Var();
    parent.add(var);

    var.type = parseType(var, tokens);
    var.isParam = true;

    if(var.type.isA!FunctionPtr) {
        var.name = extractVariableName(var.type);
    } else if(tokens.matches(TKind.IDENTIFIER)) {
        var.name = tokens.text(); tokens.next();
    }
}

/**
 * ReturnType [ cc ] name '(' { Type [ name ] } ')'
 */
Function parseFunctionDeclaration(Tokens tokens, Type returnType, CallingConvention cc) {
    log("parseFunctionDeclaration %s", tokens.token());

    Function fn = tokens.make!Function();

    fn.name = tokens.text(); tokens.next();
    fn.callingConvention = cc; 
    fn.returnType = returnType;

    tokens.skip(TKind.LPAREN);

    while(!tokens.matchesOneOf(TKind.RPAREN, TKind.NONE)) {
        parseParamVar(fn, tokens);

        if(tokens.matches(TKind.COMMA)) {
            tokens.next();
        }
    }
    tokens.skip(TKind.RPAREN);

    fn.numParams = fn.numChildren();

    return fn;
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/**
 * 'break'
 */
void parseBreak(Node parent, Tokens tokens) {
    Break break_ = tokens.make!Break();
    parent.add(break_);
    tokens.skip("break");
    tokens.skip(TKind.SEMI_COLON);
}

/**
 * 'continue'
 */
void parseContinue(Node parent, Tokens tokens) {
    Continue continue_ = tokens.make!Continue();
    parent.add(continue_);
    tokens.skip("continue");
    tokens.skip(TKind.SEMI_COLON);
}

/**
 * DO    ::= 'do' BODY WHILE
 * BODY  ::= ( Stmt | '{' { Stmt } '}' )
 * WHILE ::= while' '(' Expr ')' 
 */
void parseDoWhile(Node parent, Tokens tokens) {
    DoWhile do_ = tokens.make!DoWhile();
    parent.add(do_);

    tokens.skip("do");

    if(tokens.matches(TKind.LBRACE)) {
        tokens.skip(TKind.LBRACE);
        while(!tokens.isEof() && !tokens.matches(TKind.RBRACE)) {
            parseStmt(do_, tokens);
        }
        tokens.skip(TKind.RBRACE);
    } else {
        parseStmt(do_, tokens);
    }

    tokens.skip("while");
    tokens.skip(TKind.LPAREN);
    parseExpr(do_, tokens);
    tokens.skip(TKind.RPAREN);
}

/**
 * FOR       ::= 'for' '(' PRE ';' CONDITION ';' POST ')' BODY
 * PRE       ::= [ Var { ',' Var } ]
 * CONDITION ::= Expr   
 * POST      ::= [ Expr { ',' Expr } ]
 * BODY      ::= { Stmt } | '{' { Stmt } '}'
 */
void parseFor(Node parent, Tokens tokens) {
    For for_ = tokens.make!For();
    parent.add(for_);

    tokens.skip("for");
    tokens.skip(TKind.LPAREN);

    // pre
    log("for: parseStmt");
    parseStmt(for_, tokens);
    // ^^ should evaluate to one or more Vars which may be comma separated. The parseVar should handle all of them

    log("after pre");
    for_.dump();
    tokens.skip(TKind.SEMI_COLON);
    for_.conditionIndex = for_.numChildren();

    // condition
    parseExpr(for_, tokens);
    tokens.skip(TKind.SEMI_COLON);

    // post
    while(!tokens.isEof() && !tokens.matches(TKind.RPAREN)) {
        parseExpr(for_, tokens);
        if(tokens.matches(TKind.COMMA)) {
            tokens.next();
        }
    }
    tokens.skip(TKind.RPAREN);

    for_.bodyIndex = for_.numChildren();

    // body
    if(tokens.matches(TKind.LBRACE)) {
        tokens.next();
        while(!tokens.isEof() && !tokens.matches(TKind.RBRACE)) {
            parseStmt(for_, tokens);
        }
        tokens.skip(TKind.RBRACE);
    } else {
        parseStmt(for_, tokens);
    }
}

/**
 * { storage-class } Type [ cc ] name '(' params ')' [ '{' body '}'  | ';' ]
 */
void parseFunc(Node parent, Tokens tokens, Type returnType, StorageClass storageClass) {
    log("parseFunc %s", tokens.token());

    auto cc = parseCallingConvention(tokens);

    Function func = parseFunctionDeclaration(tokens, returnType, cc);
    parent.add(func);

    func.storageClass = storageClass;

    // body
    if(tokens.matches(TKind.LBRACE)) {
        func.hasBody = true;
        tokens.next();

        while(!tokens.isEof && !tokens.matches(TKind.RBRACE)) {
            parseStmt(func, tokens);
        }
        tokens.skip(TKind.RBRACE);
    } else {

        if(tokens.matches(TKind.SEMI_COLON)) {
            tokens.skip(TKind.SEMI_COLON);
        }
    }
}

void parseHash(Node parent, Tokens tokens) {
    tokens.skip(TKind.HASH);

    if(tokens.matches("pragma")) {
        parseHashPragma(parent, tokens);
    } else {
        todo("unsupported hash directive %s".format(tokens.text()));
    }
}
/**
 * 'if' Expr [ '{' body '}' | stmt ] [ 'else' [ '{' body '}' | stmt ]
 */
void parseIf(Node parent, Tokens tokens) {
    If if_ = tokens.make!If();
    parent.add(if_);

    tokens.skip("if");

    // condition
    tokens.skip(TKind.LPAREN);
    parseExpr(if_, tokens);
    tokens.skip(TKind.RPAREN);

    if(tokens.matches(TKind.LBRACE)) {
        tokens.next();
        while(!tokens.isEof() && !tokens.matches(TKind.RBRACE)) {
            parseStmt(if_, tokens);
        }
        tokens.skip(TKind.RBRACE);
    } else {
        parseStmt(if_, tokens);
    }

    if_.numThenExprs = if_.numChildren() - 1; 

    if(tokens.matches("else")) {
        tokens.next();
        if(tokens.matches(TKind.LBRACE)) {
            tokens.next();
            while(!tokens.isEof() && !tokens.matches(TKind.RBRACE)) {
                parseStmt(if_, tokens);
            }
            tokens.skip(TKind.RBRACE);
        } else {
            parseStmt(if_, tokens);
        }
    }
}

/**
 * name ':'
 */
void parseLabel(Node parent, Tokens tokens) {
    Label label = tokens.make!Label();
    parent.add(label);

    label.name = tokens.text(); tokens.next();

    tokens.skip(TKind.COLON);
}

/**
 * #pragma <tokens>
 */
void parseHashPragma(Node parent, Tokens tokens) {
    tokens.skip("pragma");

    // Ignore these:
    //  #pragma once
    //  #pragma region
    //  #pragma endregion
    if(tokens.text().isOneOf("once", "region", "endregion")) {
        tokens.skipToNextLine();
        return;
    }

    if(tokens.matches("warning")) {
        parsePragmaWarning(parent, tokens);
    } else if(tokens.matches("pack")) {
        parsePragmaPack(parent, tokens);
    } else if(tokens.matches("intrinsic")) {
        parsePragmaIntrinsic(parent, tokens);
    } else {
        todo("unsupported #pragma %s".format(tokens.text()));
    }
}
/**
    * __pragma( <tokens> )
    * ms specific
    */
void parse__pragma(Node parent, Tokens tokens) {
    tokens.skip("__pragma");
    tokens.skip(TKind.LPAREN);

    if(tokens.matches("warning")) {
        parsePragmaWarning(parent, tokens);
    } else if(tokens.matches("pack")) {
        parsePragmaPack(parent, tokens);
    } else {
        todo("unsupported __pragma %s".format(tokens.text()));
    }
    tokens.skip(TKind.RPAREN);
}
/**
 * #pragma intrinsic '(' function-name { ',' function-name } ')'
 */
void parsePragmaIntrinsic(Node parent, Tokens tokens) {
    tokens.skip("intrinsic");

    Pragma pragma_ = tokens.make!Pragma();
    parent.add(pragma_);
    pragma_.kind = Pragma.PragmaKind.INTRINSIC;

    tokens.skip(TKind.LPAREN);
    while(!tokens.matchesOneOf(TKind.RPAREN, TKind.NONE)) {

        pragma_.data.intrinsic.funcnames ~= tokens.text();
        tokens.next();

        if(tokens.matches(TKind.COMMA)) {
            tokens.next();
        }
    }
    tokens.skip(TKind.RPAREN);
}
/**
    * #pragma pack()               <-- default n = 8   
    * #pragma pack(1)              <-- n = 1  
    * #pragma pack(show)           <-- ignore this one
    * #pragma pack(push, 8)        <-- push n = 8
    * #pragma pack(pop)            <-- pop
    */
void parsePragmaPack(Node parent, Tokens tokens) {
    tokens.skip("pack");

    Pragma pragma_ = tokens.make!Pragma();
    parent.add(pragma_);
    pragma_.kind = Pragma.PragmaKind.PACK;

    tokens.skip(TKind.LPAREN);
    if(tokens.matches(TKind.RPAREN)) {
        // #pragma pack()
        pragma_.data.pack.n = 8;
    } else if(tokens.matches("show")) {
        // #pragma pack(show)
        tokens.skip("show");
    } else if(tokens.matches("push")) {
        // #pragma pack(push, 8)
        tokens.skip("push");    
        pragma_.data.pack.isPush = true;

        if(tokens.matches(TKind.COMMA)) {
            pragma_.data.pack.n = tokens.next().textToInt(); 
            tokens.next();
        } 
    } else if(tokens.matches("pop")) {
        // #pragma pack(pop, 8)
        tokens.skip("pop");
        pragma_.data.pack.isPop = true;

        if(tokens.matches(TKind.COMMA)) {
            tokens.next();
            pragma_.data.pack.n = tokens.next().textToInt(); 
            tokens.next();
        }
    } else if(tokens.kind() == TKind.NUMBER) {
        // #pragma pack(8)
        pragma_.data.pack.n = tokens.textToInt();
        tokens.next();
    } else {
        syntaxError(tokens.cfile, tokens.token(), "Expected push, pop, show or number, got %s".format(tokens.text()));
    }
    tokens.skip(TKind.RPAREN);
}
/**
    * #pragma warning( disable : 4507 4034; once : 4385; error : 164 )
    * #pragma warning( disable : 4507, justification : "This warning is disabled" )
    * #pragma warning( push [, level] ) 
    * #pragma warning( pop )
    *
    * https://learn.microsoft.com/en-us/cpp/preprocessor/warning?view=msvc-170
    */
void parsePragmaWarning(Node parent, Tokens tokens) {
    Pragma pragma_ = tokens.make!Pragma();
    parent.add(pragma_);

    tokens.skip("warning");
    tokens.skip(TKind.LPAREN);

    pragma_.kind = Pragma.PragmaKind.WARNING;

    Pragma.Warning warning;
    warning.specifier = tokens.text(); tokens.next();

    if(warning.specifier == "push") {
        warning.push = true;
        if(tokens.matches(TKind.COMMA)) {
            warning.level = tokens.next().textToInt(); 
            tokens.next();
        } 
        tokens.skip(TKind.RPAREN);
        pragma_.data.warnings ~= warning;
        return;
    } else if(warning.specifier == "pop") {
        tokens.skip(TKind.RPAREN);
        warning.pop = true;
        pragma_.data.warnings ~= warning;
        return;
    }

    tokens.skip(TKind.COLON);

    while(tokens.kind() != TKind.RPAREN) {
        if(tokens.kind() == TKind.NUMBER) {
            warning.numbers ~= tokens.text();
            tokens.next();
        } else if(tokens.kind() == TKind.COMMA) {
            tokens.next();
            if(tokens.text() == "justification") {
                tokens.next();
                tokens.skip(TKind.COLON);
                warning.justification = tokens.text(); tokens.next();
            }
        } else if(tokens.kind() == TKind.SEMI_COLON) {
            tokens.next();
            pragma_.data.warnings ~= warning;

            // Start another warning specifier
            warning = Pragma.Warning();
            warning.specifier = tokens.text(); tokens.next();
            tokens.skip(TKind.COLON);

        } else {
            todo("unsupported token %s".format(tokens.text()));
        }
    }
    tokens.skip(TKind.RPAREN);
    pragma_.data.warnings ~= warning;
}
StorageClass parseStorageClass(Tokens tokens) {
    StorageClass storageClass;
    while(true) {
        if(tokens.matches("extern")) {
            storageClass.isExtern = true;
            tokens.next();
        } else if(tokens.matches("static")) {
            storageClass.isStatic = true;
            tokens.next();
        } else if(tokens.matches("__inline") || tokens.matches("inline")) {
            storageClass.inline = true;
            tokens.next();
        } else if(tokens.matches("__forceinline")) {
            storageClass.forceInline = true;
            tokens.next();
        } else if(tokens.matches("__declspec")) {
            tokens.next();
            tokens.skip(TKind.LPAREN);

            if(tokens.matches("noreturn")) {
                tokens.skip("noreturn");
                storageClass.__declspec_noreturn = true;
            } else if(tokens.matches("dllimport")) {
                tokens.skip("dllimport");
                storageClass.__declspec_dllimport = true;
            } else if(tokens.matches("dllexport")) {
                tokens.skip("dllexport");
                storageClass.__declspec_dllexport = true;
            } else if(tokens.matches("noinline")) {
                tokens.skip("noinline");
                storageClass.__declspec_noinline = true;
            } else if(tokens.matches("deprecated")) {
                tokens.skip("deprecated");
                storageClass.__declspec_deprecated = true;
                if(tokens.matches(TKind.LPAREN)) {
                    tokens.skip(TKind.LPAREN);
                    while(!tokens.matches(TKind.RPAREN)) {
                        storageClass.deprecationMsg ~= tokens.text(); 
                        tokens.next();
                    }
                    tokens.skip(TKind.RPAREN);
                }
            } else if(tokens.matches("allocator")) {
                tokens.skip("allocator");
                storageClass.__declspec_allocator = true;
            } else if(tokens.matches("restrict")) {
                tokens.skip("restrict");
                storageClass.__declspec_restrict = true;    
            } else {
                todo("unsupported __declspec %s".format(tokens.text()));
            }
            tokens.skip(TKind.RPAREN);
        } else {
            break;
        }
    }
    return storageClass;
}


/**
 * 'return' [ Expr ] ';'
 */
void parseReturn(Node parent, Tokens tokens) {
    Return ret = tokens.make!Return();
    parent.add(ret);

    tokens.skip("return");

    if(!tokens.matches(TKind.SEMI_COLON)) {
        parseExpr(ret, tokens);
    }

    tokens.skip(TKind.SEMI_COLON);
}

void parseScope(Node parent, Tokens tokens) {
    Scope s = tokens.make!Scope();
    parent.add(s);

    tokens.skip(TKind.LBRACE);

    while(!tokens.isEof() && !tokens.matches(TKind.RBRACE)) {
        parseStmt(s, tokens);
    }
    tokens.skip(TKind.RBRACE);
}

/**
 * 'typedef' type name { ',' { '*' } name } ';'
 */
void parseTypedef(Node parent, Tokens tokens) {
    log("parseTypedef %s", tokens.text());
    tokens.skip("typedef");

    Typedef td = tokens.make!Typedef();
    Typedef first = td;
    parent.add(td);

    td.type = parseType(td, tokens);

    // If this is a function pointer then we take the name from the function pointer
    if(td.type.isA!FunctionPtr || td.nameIsEmbedded) {
        td.name = extractVariableName(td.type);
    } else if(tokens.matches(TKind.IDENTIFIER)) {
        td.name = tokens.text(); tokens.next();
    }

    log("typedef %s name = %s", td.type, td.name);

    parent.getCFile().registerTypedef(td);

    // subsequent declarations
    while(tokens.matches(TKind.COMMA)) {
        tokens.skip(TKind.COMMA);
        
        first.inList = true;
        first.firstInList = true;

        // Clone the type and remove the pointers
        auto type = td.type.clone();

        // If any qualifiers are specified then they replace the original qualifiers
        TypeQualifiers qualifiers = parseQualifiers(tokens);
        if(qualifiers.any()) {
            type.qualifiers = qualifiers;
        }

        // Add pointer information
        type.ptrs = parsePtrFlags(tokens);  

        td = tokens.make!Typedef();
        parent.add(td);
        td.inList = true;
        td.type = type;
        td.name = tokens.text(); tokens.next();

        parent.getCFile().registerTypedef(td);
    }

    td.lastInList = td.inList;

    log("end of typedef %s", td.name);

    tokens.skip(TKind.SEMI_COLON);
}

/**
 * Type name [ '=' Expr ] ';'
 */
void parseVar(Node parent, Tokens tokens, Type type, StorageClass storageClass) {
    log("parseVar %s", tokens.text());
    Var var = tokens.make!Var();
    Var firstVar = var;
    parent.add(var);

    var.type = type;
    var.storageClass = storageClass;

    if(var.type.isA!FunctionPtr) {
        var.name = extractVariableName(var.type);
    } else if(tokens.matches(TKind.IDENTIFIER)) {
        var.name = tokens.text(); tokens.next();
    }

    // if(string n = extractVariableName(var.type)) {
    //     var.name = n;
    // } else {
    //     var.name = tokens.text(); tokens.next();
    // }

    // bitfield
    if(tokens.matches(TKind.COLON)) {
        tokens.next();
        var.hasBitfield = true;
        parseExpr(var, tokens);
    }

    if(tokens.matches(TKind.EQUALS)) {
        tokens.next();
        var.hasInitialiser = true;
        parseExpr(var, tokens);
    }

    // subsequent declarations
    while(tokens.matches(TKind.COMMA)) {
        tokens.skip(TKind.COMMA);

        firstVar.inList = true;
        firstVar.firstInList = true;

        // Clone the type and remove the pointers
        type = type.clone();

        // If any qualifiers are specified then they replace the original qualifiers
        TypeQualifiers qualifiers = parseQualifiers(tokens);
        if(qualifiers.any()) {
            type.qualifiers = qualifiers;
        }

        // Add pointer information
        type.ptrs = parsePtrFlags(tokens);  

        var = tokens.make!Var();
        parent.add(var);
        var.inList = true;
        var.type = type;
        var.name = tokens.text(); tokens.next();

        // bitfield
        if(tokens.matches(TKind.COLON)) {
            tokens.next();
            var.hasBitfield = true;
            parseExpr(var, tokens);
        }

        if(tokens.matches(TKind.EQUALS)) {
            tokens.next();
            var.hasInitialiser = true;
            parseExpr(var, tokens);
        }
    }

    var.lastInList = var.inList;
}

/**
 * WHILE ::= 'while' '(' Expr ')' BODY
 * BODY  ::= { Stmt | '{ { Stmt } '}' 
 */
void parseWhile(Node parent, Tokens tokens) {
    While w = tokens.make!While();
    parent.add(w);

    tokens.skip("while");
    
    // condition
    tokens.skip(TKind.LPAREN);
    parseExpr(w, tokens);
    tokens.skip(TKind.RPAREN);

    // body
    if(tokens.matches(TKind.LBRACE)) {
        tokens.next();
        while(!tokens.isEof() && !tokens.matches(TKind.RBRACE)) {
            parseStmt(w, tokens);
        }
        tokens.skip(TKind.RBRACE);
    } else {
        parseStmt(w, tokens);
    }
}

/**
 * SWICTH    ::= 'switch' '(' CONDITION ')' '{' ( CASE | DEFAULT ) '}''
 * CONDITION ::= Expr
 * CASE      ::= 'case' Expr ':' { Stmt }
 * DEFAULT   ::= 'default' ':' { Stmt }
 */
void parseSwitch(Node parent, Tokens tokens) {
    Switch s = tokens.make!Switch();
    parent.add(s);

    tokens.skip("switch");

    tokens.skip(TKind.LPAREN);
    parseExpr(s, tokens);
    tokens.skip(TKind.RPAREN);

    tokens.skip(TKind.LBRACE);

    while(!tokens.isEof() && !tokens.matches(TKind.RBRACE)) {
        if(tokens.matches("case")) {
            tokens.skip("case");

            Switch.Case c = {
                isDefault: false,
                childIndex: s.numChildren()
            };
            s.cases ~= c;

            parseExpr(s, tokens);

            tokens.skip(TKind.COLON);

            while(!tokens.isEof() && !tokens.matches(TKind.RBRACE) && !tokens.matchesOneOf("case", "default")) {
                parseStmt(s, tokens);
            }
            
        } else if(tokens.matches("default")) {
            tokens.skip("default");

            Switch.Case c = {
                isDefault: true,
                childIndex: s.numChildren()
            };
            s.cases ~= c;

            tokens.skip(TKind.COLON);

            while(!tokens.isEof() && !tokens.matches(TKind.RBRACE) && !tokens.matchesOneOf("case", "default")) {
                parseStmt(s, tokens);
            }
            
        } else {
            syntaxError(tokens, "Expected 'case' or 'default'");
        }
    }
    tokens.skip(TKind.RBRACE);
}

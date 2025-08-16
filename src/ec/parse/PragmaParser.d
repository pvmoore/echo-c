module ec.parse.PragmaParser;

import ec.all;

/**
 * PRAGMA    ::= ( __pragma '( PAYLOAD )' | #pragma PAYLOAD ) 
 * PAYLOAD   ::= ( INTRINSIC | PACK | WARNING )  
 *
 * INTRINSIC ::= 'intrinsic' '(' ... ')'
 * PACK      ::= 'pack' '(' ... ')'
 * WARNING   ::= 'warning' '(' ... ')'
 */
Pragma parseAndReturnPragma(Tokens tokens) 
in {
    assert(tokens.matchesOneOf("__pragma", TKind.HASH));
} 
do {
    Parens parent = tokens.make!Parens();
    parsePragma(parent, tokens);

    assert(parent.numChildren() == 1);
    assert(parent.first().isA!Pragma);
    return parent.first().as!Pragma;
}

void parsePragma(Node parent, Tokens tokens) 
in {
    assert(tokens.matchesOneOf("__pragma", TKind.HASH));
} 
do {
    if(tokens.matches("__pragma")) {
        parse__pragma(parent, tokens);
    } else if(tokens.matches(TKind.HASH)) {
        tokens.skip(TKind.HASH);
        parseHashPragma(parent, tokens);
    } 
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

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
        parsePragmaWarning(parent, tokens, true);
    } else if(tokens.matches("pack")) {
        parsePragmaPack(parent, tokens, true);
    } else if(tokens.matches("intrinsic")) {
        parsePragmaIntrinsic(parent, tokens, true);
    } else if(tokens.matches("deprecated")) {
        parsePragmaDeprecated(parent, tokens, true);
    } else if(tokens.matches("comment")) {
        parsePragmaComment(parent, tokens, true);
    } else {
        todo("unsupported #pragma %s".format(tokens.text()));
    }
}
/**
 * __pragma( <tokens> )
 * ms specific?
 */
void parse__pragma(Node parent, Tokens tokens) {
    tokens.skip("__pragma");
    tokens.skip(TKind.LPAREN);

    if(tokens.matches("warning")) {
        parsePragmaWarning(parent, tokens, false);
    } else if(tokens.matches("pack")) {
        parsePragmaPack(parent, tokens, false);
    } else if(tokens.matches("deprecated")) {
        parsePragmaDeprecated(parent, tokens, false);
    } else if(tokens.matches("comment")) {
        parsePragmaComment(parent, tokens, false);
    } else {
        todo("unsupported __pragma %s".format(tokens.text()));
    }
    tokens.skip(TKind.RPAREN);
}

/**
 * #pragma comment( comment-type [ , "comment-string" ] )
 */
void parsePragmaComment(Node parent, Tokens tokens, bool isHash) {
    tokens.skip("comment");

    Pragma pragma_ = tokens.make!Pragma();
    parent.add(pragma_);
    pragma_.kind = Pragma.PragmaKind.COMMENT;
    pragma_.isHash = isHash;

    tokens.skip(TKind.LPAREN);
    while(!tokens.matchesOneOf(TKind.RPAREN, TKind.NONE)) {
        pragma_.data.comment.comments ~= tokens.text();
        tokens.next();
    }
    tokens.skip(TKind.RPAREN);
}

/**
 *  #pragma deprecated( identifier1 [ , identifier2 ... ] )
 */
void parsePragmaDeprecated(Node parent, Tokens tokens, bool isHash) {
    tokens.skip("deprecated");

    Pragma pragma_ = tokens.make!Pragma();
    parent.add(pragma_);
    pragma_.kind = Pragma.PragmaKind.DEPRECATED;
    pragma_.isHash = isHash;

    tokens.skip(TKind.LPAREN);
    while(!tokens.matchesOneOf(TKind.RPAREN, TKind.NONE)) {

        pragma_.data.deprecated_.funcNames ~= tokens.text();
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
void parsePragmaPack(Node parent, Tokens tokens, bool isHash) {
    tokens.skip("pack");

    Pragma pragma_ = tokens.make!Pragma();
    parent.add(pragma_);
    pragma_.kind = Pragma.PragmaKind.PACK;
    pragma_.isHash = isHash;

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
void parsePragmaWarning(Node parent, Tokens tokens, bool isHash) {
    Pragma pragma_ = tokens.make!Pragma();
    parent.add(pragma_);

    tokens.skip("warning");
    tokens.skip(TKind.LPAREN);

    pragma_.kind = Pragma.PragmaKind.WARNING;
    pragma_.isHash = isHash;

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

/**
 * #pragma intrinsic '(' function-name { ',' function-name } ')'
 */
void parsePragmaIntrinsic(Node parent, Tokens tokens, bool isHash) {
    tokens.skip("intrinsic");

    Pragma pragma_ = tokens.make!Pragma();
    parent.add(pragma_);
    pragma_.kind = Pragma.PragmaKind.INTRINSIC;
    pragma_.isHash = isHash;

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

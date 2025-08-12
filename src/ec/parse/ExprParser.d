module ec.parse.ExprParser;

import ec.all;

void parseExpr(Node parent, Tokens tokens) {
    log("parseExpr %s", tokens.token());
    parseLHS(parent, tokens);
    parseRHS(parent, tokens);
}

/**
 * Parse an expression with the upper bound being 'parent'.
 * This ensures expressions with lower priority are not moved above parent in the AST.
 */
void parseExprWithUpperBound(Node parent, Tokens tokens) {
    log("parseExprWithUpperBound %s", tokens.token());
    
    // Use Parens as an upper bound ceiling
    auto p = tokens.make!Parens();
    
    parseExpr(p, tokens);

    assert(p.numChildren() == 1);
    parent.add(p.first());
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void parseLHS(Node parent, Tokens tokens) {
    switch(tokens.kind()) {
        case TKind.STRING:
            parseStringLiteral(parent, tokens);
            return;
        case TKind.NUMBER:
            parseNumber(parent, tokens);
            return;
        case TKind.IDENTIFIER: 
            if(tokens.kind(1) == TKind.LPAREN) {
                parseCall(parent, tokens);
            } else {
                parseIdentifier(parent, tokens);
            }
            return;
        case TKind.AMPERSAND:
            parseAddressof(parent, tokens);
            return;
        case TKind.LPAREN:
            // Handle cast
            auto t = isType(parent, tokens, 1);
            if(t.result) {
                tokens.pos = t.pos;
                parseCast(parent, tokens, t.type);
            } else {
                parseParens(parent, tokens);
            }
            return;
        case TKind.STAR:
            parseValueOf(parent, tokens);
            return;
        case TKind.EXCLAMATION_MARK:
        case TKind.MINUS:
        case TKind.PLUS:
        case TKind.TILDE:
        case TKind.PLUS2:
        case TKind.MINUS2:
            parsePrefix(parent, tokens);
            return;
        case TKind.LBRACE:
            parseInitialiser(parent, tokens);
            return;
        default: 
            todo("unsupported token %s".format(tokens.text()));
            break;
    }

    todo();
}

void parseRHS(Node parent, Tokens tokens) {
    while(!tokens.isEof()) {
        switch(tokens.kind()) {
            case TKind.NONE:
            case TKind.LBRACE:
            case TKind.RBRACE:
            case TKind.LPAREN:
            case TKind.RPAREN:
            case TKind.RSQUARE:
            case TKind.SEMI_COLON:
            case TKind.COMMA:
            case TKind.NUMBER:
            case TKind.STRING:
            case TKind.HASH:
            case TKind.IDENTIFIER:
            case TKind.COLON:
                return;
            case TKind.PLUS:
            case TKind.MINUS:
            case TKind.FWD_SLASH:
            case TKind.STAR:
            case TKind.PERCENT:
            case TKind.AMPERSAND:
            case TKind.PIPE:
            case TKind.CARET:
            case TKind.TILDE:
            case TKind.AMPERSAND2:  // &&
            case TKind.PIPE2:       // ||
            case TKind.LANGLE:      // <
            case TKind.RANGLE:      // >
            case TKind.LANGLE2:     // <<
            case TKind.RANGLE2:     // >>
            case TKind.LANGLE_EQ:   // <=
            case TKind.RANGLE_EQ:   // >=
            case TKind.LANGLE2_EQ:  // <<=
            case TKind.RANGLE2_EQ:  // >>=
            case TKind.EQUALS2:     // ==
            case TKind.EXCLAMATION_MARK_EQ: // !=
            case TKind.EQUALS:      // =
            {
                auto b = parseAndReturnInfix(tokens);
                parent = attachAndRead(parent, b, tokens, true);
                break;
            }
            case TKind.QUESTION_MARK: {
                auto t = parseAndReturnTernary(tokens);
                parent = attachAndRead(parent, t, tokens, false);
                break;
            }
            case TKind.PLUS2: // ++
            case TKind.MINUS2: // --
            {
                parsePostfix(parent, tokens);
                break;
            }
            case TKind.DOT:
            case TKind.RT_ARROW:
            {
                auto d = parseAndReturnDotOrArrow(tokens);
                parent = attachAndRead(parent, d, tokens, true);
                break;
            }
            default:
                throwIf(true, "Unexpected RHS token %s".format(tokens.text()));
        }
    }
}


Expr attachAndRead(Node parent, Expr newExpr, Tokens tokens, bool andRead) {

    Node prev = parent;

    // Swap expressions according to operator precedence
    if(Expr prevExpr = prev.as!Expr) {

        // Adjust to account for operator precedence
        while(prevExpr.parent && newExpr.precedence() >= prevExpr.precedence()) {

            if(!prevExpr.parent.isA!Expr) {
                prev = prevExpr.parent;
                break;
            }

            prevExpr = prevExpr.parent.as!Expr;
            prev     = prevExpr;
        }
    }

    newExpr.add(prev.last());

    prev.add(newExpr);

    if(andRead) {
        parseLHS(newExpr, tokens);
    }

    return newExpr;
}

Infix parseAndReturnInfix(Tokens tokens) {

    Infix infix = tokens.make!Infix();
    infix.op = parseInfixOperator(tokens);

    return infix;
}

/**
 * Expr ? Expr : Expr
 */
Ternary parseAndReturnTernary(Tokens tokens) {

    Ternary ternary = tokens.make!Ternary();

    // Skip the '?'
    tokens.skip(TKind.QUESTION_MARK);

    parseExprWithUpperBound(ternary, tokens);

    // Skip the ':'
    tokens.skip(TKind.COLON);

    parseExprWithUpperBound(ternary, tokens);

    return ternary;
}

/**
 * expr '.' expr
 * expr '->' expr
 */
Dot parseAndReturnDotOrArrow(Tokens tokens) {
    Dot dot = tokens.make!Dot();

    if(tokens.matches(TKind.DOT)) {
        tokens.skip(TKind.DOT);
    } else {
        tokens.skip(TKind.RT_ARROW);
        dot.isArrow = true;
    }

    return dot;
}

/**
 * '&' Expr
 */
void parseAddressof(Node parent, Tokens tokens) {
    Addressof addr = tokens.make!Addressof();
    parent.add(addr);

    tokens.skip(TKind.AMPERSAND);

    parseExpr(addr, tokens);
}

/**
 *  name '(' { Expr } ')' 
 */
void parseCall(Node parent, Tokens tokens) {
    Call call = tokens.make!Call();
    parent.add(call);

    call.name = tokens.text(); tokens.next(); 

    tokens.skip(TKind.LPAREN); 

    while(!tokens.isEof() && !tokens.matches(TKind.RPAREN)) {
        parseExprWithUpperBound(call, tokens);

        if(tokens.kind() == TKind.COMMA) {
            tokens.next(); 
        }
    }
    tokens.skip(TKind.RPAREN); 
}

/**
 * '(' Type ')' Expr
 */
void parseCast(Node parent, Tokens tokens, Type type) {
    // We start at the end of the Type
    assert(tokens.kind() == TKind.RPAREN);
    tokens.skip(TKind.RPAREN);

    Cast c = tokens.make!Cast();
    parent.add(c);

    c.type = type;

    parseExpr(c, tokens);
}

/**
 * identifier
 */
 void parseIdentifier(Node parent, Tokens tokens) {
    Identifier id = tokens.make!Identifier();
    parent.add(id);

    id.name = tokens.text(); tokens.next();
}

/**
 * INITIALISER ::= '{' (ARRAY_INIT | STRUCT_INIT | SINGLE_INIT) '}'
 * ARRAY_INIT  ::= '{' [ Expr { ',' Expr } ] '}'
 * STRUCT_INIT ::= '{' [ { .field = Expr } ] '}'
 * SINGLE_INIT ::= '{' Expr '}'
 */
void parseInitialiser(Node parent, Tokens tokens) {
    Initialiser init = tokens.make!Initialiser();
    parent.add(init);

    tokens.skip(TKind.LBRACE);

    

    while(!tokens.isEof() && !tokens.matches(TKind.RBRACE)) {

        if(tokens.matches(TKind.DOT, TKind.IDENTIFIER, TKind.EQUALS)) {
            // We must be in a struct initialiser
            
            tokens.skip(TKind.DOT);
            string label = tokens.text(); tokens.next();
            tokens.skip(TKind.EQUALS);

            // label_expr
            Initialiser.Element ele = {
                kind: Initialiser.ElementKind.LABEL_EXPR,
                exprIndex: init.numChildren(),
                label: label
            };
            init.elements ~= ele;

            parseExpr(init, tokens);

        } else if(tokens.matches(TKind.LSQUARE)) {
            // We must be in an array initialiser
            tokens.skip(TKind.LSQUARE);

            Initialiser.Element ele = {
                kind: Initialiser.ElementKind.INDEX_EXPR,
                arrayIndex: init.numChildren(),
                exprIndex: init.numChildren() + 1
            };
            init.elements ~= ele;

            parseExpr(init, tokens);

            tokens.skip(TKind.RSQUARE);
            tokens.skip(TKind.EQUALS);

            parseExpr(init, tokens);

        } else {
            // This must be a simple expr
            Initialiser.Element ele = {
                kind: Initialiser.ElementKind.EXPR,
                exprIndex: init.numChildren(),
            };
            init.elements ~= ele;

            parseExpr(init, tokens);
        }

        if(tokens.kind() == TKind.COMMA) {
            tokens.next();
        }
    }

    tokens.skip(TKind.RBRACE);
}

/**
 * number
 */
void parseNumber(Node parent, Tokens tokens) {
    Number n = tokens.make!Number();
    parent.add(n);

    n.stringValue = tokens.text(); tokens.next();
}

/**
 * ( Expr )
 */
void parseParens(Node parent, Tokens tokens) {
    Parens parens = tokens.make!Parens();
    parent.add(parens);

    tokens.skip(TKind.LPAREN); 

    parseExpr(parens, tokens);

    tokens.skip(TKind.RPAREN); 
}

void parsePrefix(Node parent, Tokens tokens) {
    Prefix prefix = tokens.make!Prefix();
    parent.add(prefix);

    prefix.op = parsePrefixOperator(tokens);

    parseExpr(prefix, tokens);
}

void parsePostfix(Node parent, Tokens tokens) {
    Postfix postfix = tokens.make!Postfix();
    postfix.op = parsePostfixOperator(tokens);

    Node prev = parent.last();
    postfix.add(prev);
    parent.add(postfix);
}

/**
 * "string" "append me"
 */
void parseStringLiteral(Node parent, Tokens tokens) {
    StringLiteral str = tokens.make!StringLiteral();
    parent.add(str);

    while(tokens.matches(TKind.STRING)) {
        str.value ~= tokens.text()[1..$-1]; 
        tokens.next();
    }
}

/**
 * '*' Expr
 */
void parseValueOf(Node parent, Tokens tokens) {
    Valueof v = tokens.make!Valueof();
    parent.add(v);

    tokens.skip(TKind.STAR);

    parseExpr(v, tokens);
}

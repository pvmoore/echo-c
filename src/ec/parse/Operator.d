module ec.parse.Operator;

import ec.all;

enum Operator {
    ADD,                // +
    SUB,                // -
    MUL,                // *
    DIV,                // /
    MOD,                // %
    BIT_NOT,            // ~
    BIT_AND,            // &
    BIT_OR,             // |
    BIT_XOR,            // ^
    SHL,                // <<
    SHR,                // >>

    ASSIGN,             // =

    PREFIX_POS,         // +
    PREFIX_NEG,         // -
    PREFIX_INC,         // ++
    PREFIX_DEC,         // --

    POSTFIX_INC,        // ++
    POSTFIX_DEC,        // --

    BOOL_NOT,           // !
    BOOL_EQ,            // ==
    BOOL_NEQ,           // !=
    BOOL_LT,            // <
    BOOL_GT,            // >
    BOOL_LTE,           // <=
    BOOL_GTE,           // >=
    BOOL_AND,           // &&
    BOOL_OR,            // ||
}

string stringOf(Operator op) {
    final switch(op) with(Operator) {
        case ADD: return "+";
        case SUB: return "-";
        case MUL: return "*";
        case DIV: return "/";
        case MOD: return "%";
        case BIT_AND: return "&";
        case BIT_OR: return "|";
        case BIT_XOR: return "^";
        case BIT_NOT: return "~";
        case SHL: return "<<";
        case SHR: return ">>";

        case PREFIX_POS: return "+";
        case PREFIX_NEG: return "-";
        case PREFIX_INC: return "++";
        case PREFIX_DEC: return "--";
        case POSTFIX_INC: return "++";
        case POSTFIX_DEC: return "--";

        case ASSIGN: return "=";

        case BOOL_NOT: return "!";
        case BOOL_EQ: return "==";
        case BOOL_NEQ: return "!=";
        case BOOL_LT: return "<";
        case BOOL_GT: return ">";
        case BOOL_LTE: return "<=";
        case BOOL_GTE: return ">=";
        case BOOL_AND: return "&&";
        case BOOL_OR: return "||";
    }
}

Operator parseInfixOperator(Tokens tokens) {
    Operator op;
    switch(tokens.kind()) {
        case TKind.PLUS: op = Operator.ADD; break;
        case TKind.MINUS: op = Operator.SUB; break;
        case TKind.STAR: op = Operator.MUL; break;
        case TKind.FWD_SLASH: op = Operator.DIV; break;
        case TKind.PERCENT: op = Operator.MOD; break;
        case TKind.TILDE: op = Operator.BIT_NOT; break;
        case TKind.AMPERSAND: op = Operator.BIT_AND; break;
        case TKind.PIPE: op = Operator.BIT_OR; break;
        case TKind.CARET: op = Operator.BIT_XOR; break;
        case TKind.LANGLE2: op = Operator.SHL; break;
        case TKind.RANGLE2: op = Operator.SHR; break;

        case TKind.EQUALS: op = Operator.ASSIGN; break;

        case TKind.LANGLE: op = Operator.BOOL_LT; break;
        case TKind.RANGLE: op = Operator.BOOL_GT; break;
        case TKind.EXCLAMATION_MARK: op = Operator.BOOL_NOT; break;
        case TKind.EQUALS2: op = Operator.BOOL_EQ; break;
        case TKind.EXCLAMATION_MARK_EQ: op = Operator.BOOL_NEQ; break;
        case TKind.LANGLE_EQ: op = Operator.BOOL_LTE; break;
        case TKind.RANGLE_EQ: op = Operator.BOOL_GTE; break;
        case TKind.AMPERSAND2: op = Operator.BOOL_AND; break;
        case TKind.PIPE2: op = Operator.BOOL_OR; break;


        default:
            syntaxError(tokens.cfile, tokens.token(), "Unexpected infix operator '%s'".format(tokens.kind()));
    }
    tokens.next();
    return op;
}

Operator parsePrefixOperator(Tokens tokens) {
    Operator op;
    switch(tokens.kind()) {
        case TKind.PLUS: op = Operator.PREFIX_POS; break;
        case TKind.MINUS: op = Operator.PREFIX_NEG; break;
        case TKind.TILDE: op = Operator.BIT_NOT; break;
        case TKind.EXCLAMATION_MARK: op = Operator.BOOL_NOT; break;
        case TKind.PLUS2: op = Operator.PREFIX_INC; break;
        case TKind.MINUS2: op = Operator.PREFIX_DEC; break;

        default:
            syntaxError(tokens.cfile, tokens.token(), "Unexpected prefix operator '%s'".format(tokens.kind()));
    }
    tokens.next();
    return op;
}

Operator parsePostfixOperator(Tokens tokens) {
    Operator op;
    switch(tokens.kind()) {
        case TKind.PLUS2: op = Operator.POSTFIX_INC; break;
        case TKind.MINUS2: op = Operator.POSTFIX_DEC; break;

        default:
            syntaxError(tokens.cfile, tokens.token(), "Unexpected postfix operator '%s'".format(tokens.kind()));
    }
    tokens.next();
    return op;
}

int precedenceOf(Operator op) {
    final switch(op) with(Operator) {
        // call, dot, index, rtarrow -> 1
        case POSTFIX_INC:
        case POSTFIX_DEC:   
            return 1;

        // addressof,  -> 2
        case BIT_NOT:
        case BOOL_NOT:  
        case PREFIX_POS:
        case PREFIX_NEG:
        case PREFIX_INC:
        case PREFIX_DEC:
            return 2;

        case MUL: 
        case DIV: 
        case MOD: 
            return 3;

        case ADD: 
        case SUB: 
            return 4;

        case SHL:
        case SHR:
            return 5;

        case BOOL_LT:
        case BOOL_LTE:
        case BOOL_GT:
        case BOOL_GTE:
            return 6;    

        case BOOL_EQ:
        case BOOL_NEQ:
            return 7;

        case BIT_AND:
            return 8;

        case BIT_XOR:
            return 9;

        case BIT_OR:
            return 10;

        case BOOL_AND:
            return 11;

        case BOOL_OR:
            return 12;

        // case TERNARY:
        //     return 13;

        case ASSIGN: 
            return 14;
    }
}

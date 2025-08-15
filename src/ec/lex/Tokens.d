module ec.lex.Tokens;

import ec.all;

final class Tokens {
public:
    CFile cfile;
    Token[] tokens;
    int pos;

    this(CFile cfile) {
        this.cfile = cfile;
        this.tokens = cfile.tokens;
    }
    void pushState() {
        posStack ~= pos;
    }
    void popState() {
        assert(posStack.length > 0);
        pos = posStack[$-1];
        posStack.length--;
    }

    Token token(int offset = 0) {
        if(pos + offset >= tokens.length) return NO_TOKEN;
        return tokens[pos + offset];
    }
    TKind kind(int offset = 0) {
        return token(offset).kind;
    }
    string text(int offset = 0) {
        return token(offset).text;
    }
    int textToInt(int offset = 0) {
        import std.conv : to;
        return text(offset).to!int;
    }
    Tokens next(int count = 1) {
        pos += count;
        return this;
    }
    bool isEof() {
        return pos >= tokens.length;
    }
    void skip(TKind k) {
        if(kind() != k) syntaxError(cfile, token(), "Expected '%s' got '%s'".format(stringOf(k), token()));
        pos++;
    }
    void skip(string s) {
        if(text() != s) syntaxError(cfile, token(), "Expected '%s' got '%s'".format(s, token()));
        pos++;
    }
    void skipToNextLine() {
        int line = token().line;
        while(!isEof() && token().line == line) {
            pos++;
        }
    }
    /**
     * Find the offset of the closing bracket for the opening bracket at the given offset.
     * Returns -1 if not found.
     *
     * eg.
     *     offsetOfOpeningBracket = 4 
     *     | 
     *     v
     * blah(some{thing},[here])
     * ^                      ^ 
     * |                      | 
     * pos                    return 23
     */
    int findClosingBracket(int offsetOfOpeningBracket) 
    in {
        assert(kind(offsetOfOpeningBracket) == TKind.LPAREN);
    }
    do {
        int i = offsetOfOpeningBracket + 1;
        int braceCount = 0;
        int parensCount = 0;
        int squareCount = 0;

        lp:while(pos + i < tokens.length) {
            switch(kind(i)) {
                case TKind.NONE: break lp;
                case TKind.LBRACE: braceCount++; break;
                case TKind.LSQUARE: squareCount++; break;
                case TKind.LPAREN: parensCount++; break;
                case TKind.RBRACE: braceCount--; break;
                case TKind.RSQUARE: squareCount--; break;
                case TKind.RPAREN: 
                    if(parensCount == 0) return i;
                    parensCount--; 
                    break;
                default: break;
            }
            i++;
        }
        return -1;
    }
    bool matchesOneOf(Args...)(Args array) {
        static foreach(k; array) {
            static if(is(typeof(k) == TKind)) {
                if(kind() == k) return true;
            } else static if(is(typeof(k) == string)) {
                if(kind() == TKind.IDENTIFIER && text() == k) return true;
            } else static assert(false);
        }
        return false;
    }
    bool matches(Args...)(Args array) {
        static foreach(i, k; array) {
            static if(is(typeof(k) == TKind)) {
                if(kind(i.as!int) != k) return false;
            } else static if(is(typeof(k) == string)) {
                if(kind(i.as!int) != TKind.IDENTIFIER || text(i.as!int) != k) return false;
            } else static assert(false);
        }
        return true;
    }

    T make(T : Stmt)() {
        T t;
        Token tok = token();
        auto loc = Location(tok.line, tok.column, tok.originalLine, tok.originalFilenameIndex);
        static if(is(T == Pragma)) t = new T(EStmt.PRAGMA, loc);
        else static if(is(T == Return)) t = new T(EStmt.RETURN, loc);
        else static if(is(T == Typedef)) t = new T(EStmt.TYPEDEF, loc);
        else static if(is(T == Var)) t = new T(EStmt.VAR, loc);
        else static if(is(T == Function)) t = new T(EStmt.FUNC, loc);
        else static if(is(T == Struct)) t = new T(EStmt.STRUCT, loc);
        else static if(is(T == Addressof)) t = new T(EStmt.ADDRESSOF, loc);
        else static if(is(T == Identifier)) t = new T(EStmt.IDENTIFIER, loc);
        else static if(is(T == Call)) t = new T(EStmt.CALL, loc);
        else static if(is(T == Parens)) t = new T(EStmt.PARENS, loc);
        else static if(is(T == Valueof)) t = new T(EStmt.VALUEOF, loc);
        else static if(is(T == Cast)) t = new T(EStmt.CAST, loc);
        else static if(is(T == Number)) t = new T(EStmt.NUMBER, loc);
        else static if(is(T == Infix)) t = new T(EStmt.INFIX, loc);
        else static if(is(T == Ternary)) t = new T(EStmt.TERNARY, loc);
        else static if(is(T == If)) t = new T(EStmt.IF, loc);
        else static if(is(T == Prefix)) t = new T(EStmt.PREFIX, loc);
        else static if(is(T == Scope)) t = new T(EStmt.SCOPE, loc);
        else static if(is(T == Initialiser)) t = new T(EStmt.INITIALISER, loc);
        else static if(is(T == StringLiteral)) t = new T(EStmt.STRING_LITERAL, loc);
        else static if(is(T == For)) t = new T(EStmt.FOR, loc);
        else static if(is(T == Postfix)) t = new T(EStmt.POSTFIX, loc);
        else static if(is(T == DoWhile)) t = new T(EStmt.DO_WHILE, loc);
        else static if(is(T == While)) t = new T(EStmt.WHILE, loc);
        else static if(is(T == Break)) t = new T(EStmt.BREAK, loc);
        else static if(is(T == Continue)) t = new T(EStmt.CONTINUE, loc);
        else static if(is(T == Label)) t = new T(EStmt.LABEL, loc);
        else static if(is(T == Dot)) t = new T(EStmt.DOT, loc);
        else static if(is(T == Enum)) t = new T(EStmt.ENUM, loc);
        else static if(is(T == Union)) t = new T(EStmt.UNION, loc);
        else static if(is(T == Switch)) t = new T(EStmt.SWITCH, loc);
        else static if(is(T == Index)) t = new T(EStmt.INDEX, loc);

        else {
            static assert(false, "Unsupported statement type %s".format(T.stringof));
        }
        return t;
    }

private:
    int[] posStack;
}

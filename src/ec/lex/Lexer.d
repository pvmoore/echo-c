module ec.lex.Lexer;

import ec.all;

final class Lexer {
public:
    this(string relativeFilename, string source) {
        this.relativeFilename = relativeFilename;
        this.source = source;
    }
    Token[] tokenise() {

        while(pos < source.length) {
            char ch = peek();
            if(ch < 33) {
                consumeWhitespace();
            } else switch(ch) {
                case '"':
                    consumeString();
                    break;
                case '\'':
                    consumeChar();
                    break;
                case '/':
                    if(peek(1) == '/') {
                        consumeLineComment();
                    } else if(peek(1) == '*') {
                        consumeMultiLineComment();
                    } else if(peek(1) == '=') {
                        addToken(TKind.FWD_SLASH_EQ);
                    } else {
                        addToken(TKind.FWD_SLASH);
                    }
                    break;
                case '*':
                    if(peek(1) == '=') {
                        addToken(TKind.STAR_EQ);
                    } else {
                        addToken(TKind.STAR);
                    }
                    break;
                case '%':
                    if(peek(1) == '=') {
                        addToken(TKind.PERCENT_EQ);
                    } else {
                        addToken(TKind.PERCENT);
                    }
                    break;
                case '+':
                    if(peek(1) == '+') {
                        addToken(TKind.PLUS2);
                    } else if(peek(1) == '=') {
                        addToken(TKind.PLUS_EQ);
                    } else {
                        addToken(TKind.PLUS);
                    }
                    break;
                case '-':
                    if(tokenStart==pos && peek(1).isDigit()) {
                        // This is a negative number, not an operator
                        pos++;
                    } else if(peek(1) == '>') {
                        addToken(TKind.RT_ARROW);
                    } else if(peek(1) == '-') {
                        addToken(TKind.MINUS2);
                    } else if(peek(1) == '=') {
                        addToken(TKind.MINUS_EQ);
                    } else {
                        addToken(TKind.MINUS);
                    }
                    break;
                case '=':
                    if(peek(1) == '=') {
                        addToken(TKind.EQUALS2);
                    } else {
                        addToken(TKind.EQUALS);
                    }
                    break;
                case '!':
                    if(peek(1) == '=') {
                        addToken(TKind.EXCLAMATION_MARK_EQ);
                    } else {
                        addToken(TKind.EXCLAMATION_MARK);
                    }
                    break;
                case '&':
                    if(peek(1) == '=') {
                        addToken(TKind.AMPERSAND_EQ);
                    } else if(peek(1) == '&') {
                        addToken(TKind.AMPERSAND2);
                    } else {
                        addToken(TKind.AMPERSAND);
                    }
                    break;
                case '|':
                    if(peek(1) == '=') {
                        addToken(TKind.PIPE_EQ);
                    } else if(peek(1) == '|') {
                        addToken(TKind.PIPE2);
                    } else {
                        addToken(TKind.PIPE);
                    }
                    break;
                case '^':
                    if(peek(1) == '=') {
                        addToken(TKind.CARET_EQ);
                    } else {
                        addToken(TKind.CARET);
                    }
                    break;
                case '~':
                    if(peek(1) == '=') {
                        addToken(TKind.TILDE_EQ);
                    } else {
                        addToken(TKind.TILDE);
                    }
                    break;
                case '<':
                    if(peek(1) == '=') {
                        addToken(TKind.LANGLE_EQ);
                    } else if(peek(1) == '<' && peek(2) == '=') {
                        addToken(TKind.LANGLE2_EQ);
                    } else if(peek(1) == '<') {
                        addToken(TKind.LANGLE2);
                    } else {
                        addToken(TKind.LANGLE);
                    }
                    break;
                case '>':
                    if(peek(1) == '=') {
                        addToken(TKind.RANGLE_EQ);
                    } else if(peek(1) == '>' && peek(2) == '=') {
                        addToken(TKind.RANGLE2_EQ);
                    } else if(peek(1) == '>') {
                        addToken(TKind.RANGLE2);
                    } else {
                        addToken(TKind.RANGLE);
                    }
                    break;
                case '.':
                    if(tokenStart == pos && peek(1).isDigit()) {
                        // This is the start of a real number
                        pos++;
                    } else if(isDigit(peek(-1)) && isDigit(peek(1))) {
                        // Assume this is in the middle of a real number
                        pos++;
                    } else if(peek(1) == '.' && peek(2) == '.') {
                        addToken(TKind.ELIPSIS);
                    } else {
                        addToken(TKind.DOT);
                    }
                    break;
                case ',':
                    addToken(TKind.COMMA);
                    break;
                case ';':
                    addToken(TKind.SEMI_COLON);
                    break;
                case ':':
                    addToken(TKind.COLON);
                    break;
                case '?':
                    addToken(TKind.QUESTION_MARK);
                    break;
                case '#':
                    if(peek(1) == 'l' && peek(2) == 'i' && peek(3) == 'n' && peek(4) == 'e') {
                        consumeLineDirective();
                    } else {
                        addToken(TKind.HASH);
                    }
                    break;
                case '(':
                    addToken(TKind.LPAREN);
                    break;
                case ')':
                    addToken(TKind.RPAREN);
                    break;
                case '[':
                    addToken(TKind.LSQUARE);
                    break;
                case ']':
                    addToken(TKind.RSQUARE);
                    break;
                case '{':
                    addToken(TKind.LBRACE);
                    break;
                case '}':
                    addToken(TKind.RBRACE);
                    break;
                default:
                    pos++;
                    break;
            }
        }
        addToken();
        return tokens;
    }
private:
    string relativeFilename;
    string source;
    int pos;
    int line = 1;
    int tokenStart;
    int lineStart;
    Token[] tokens;
    uint originalLine;
    uint originalFilenameIndex;

    char peek(int offset = 0) {
        if(pos + offset >= source.length) return 0;
        return source[pos + offset];
    }
    void addToken(TKind tk = TKind.NONE) {
        if(pos > tokenStart) {
            string text = source[tokenStart..pos];
            int column  = tokenStart - lineStart;
            
            // Identify the token type
            auto tk2 = TKind.IDENTIFIER;
            char ch1 = text[0];
            char ch2 = text.length > 1 ? text[1] : 0;

            if(ch1 == '\'') tk2 = TKind.NUMBER;
            else if(ch1 == '"') tk2 = TKind.STRING;
            else if(isDigit(ch1) || (ch1=='-' && isDigit(ch2)) || (ch1=='.' && isDigit(ch2))) tk2 = TKind.NUMBER;
        
            tokens ~= Token(tk2, text, line, column, 
                originalLine, originalFilenameIndex);
        }
        if(tk != TKind.NONE) {
            int len = lengthOf(tk);
            string text = source[pos..pos+len];
            int column  = pos - lineStart;

            tokens ~= Token(tk, text, line, column, 
                originalLine, originalFilenameIndex); 
            pos += len;
        }
        // Reset the token start position
        tokenStart = pos;
    }
    void consumeLineDirective() {
        addToken();
        assert(peek() == '#');
        pos += 5; // skip "#line"
        int start = pos;

        // Skip to the end of the line
        while(pos < source.length) {
            if(isEol()) {
                eol();
                break;
            }
            pos++;
        }
        tokenStart = pos; 

        extractLineNumberAndFilename(start);
    }
    void extractLineNumberAndFilename(int start) {
        import std.conv : to;

        while(start < source.length && source[start] < 33) { start++; }
        int end = start;
        while(end < source.length && source[end] > 32) { end++; }

        string lineStr = source[start..end];
        string filenameStr = source[end..pos].strip()[1..$-1]; // strip quotes
        
        this.originalLine = lineStr.to!uint;

        uint* ptr = filenameStr in g_originalFilenames;
        if(ptr) {
            this.originalFilenameIndex = *ptr;
        } else {
            this.originalFilenameIndex = g_originalFilenamesArray.length.as!uint;
            
            g_originalFilenames[filenameStr] = g_originalFilenamesArray.length.as!uint;
            g_originalFilenamesArray ~= filenameStr;
        }
    }
    void consumeWhitespace() {
        addToken();
        while(pos < source.length) {
            if(isEol()) {
                eol();
            } else if(peek() < 33) {
                pos++;
            } else {
                break;
            }
        }
        tokenStart = pos;
    }
    void consumeString() {
        addToken();
        assert(peek()=='"');
        pos++;
        while(pos < source.length) {
            if(peek()=='"') {
                break;
            } else if(peek()=='\\' && peek(1)=='"') {
                pos+=2;
            } else {
                pos++;
            }
        }
        assert(peek()=='"');
        pos++;
        addToken();
    }
    void consumeChar() {
        addToken();
        assert(peek()=='\'');

        if(peek(1)=='\'') {
            syntaxError(relativeFilename, line, pos - lineStart, "Empty character literal");
        }

        pos++;
        if(peek()=='\\') {
            pos+=2;
        } else {
            pos++;
        }
        assert(peek()=='\'');
        pos++;
        addToken();
    }
    void consumeLineComment() {
        addToken();
        while(pos < source.length) {
            if(isEol()) {
                eol();
                break;
            }
            pos++;
        }
        tokenStart = pos;
    }
    void consumeMultiLineComment() {
        addToken();
        while(pos < source.length) {
            if(isEol()) {
                eol();
            } else if(peek()=='*' && peek(1)=='/') {
                pos+=2;
                break;
            } else {
                pos++;
            }
        }
        tokenStart = pos;
    }
    bool isEol() {
        return peek().isOneOf(10, 13);
    }
    void eol() {
        // can be 13,10 or just 10
        if(peek()==13) pos++;
        if(peek()==10) pos++;
        line++;
        lineStart = pos;
    }
}

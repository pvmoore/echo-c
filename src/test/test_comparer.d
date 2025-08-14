module test.test_comparer;

import std.stdio  : writefln;
import std.file   : read;
import std.format : format;

import common.utils;

final class TestComparer {
public:
    bool compare(string srcFile, string targetFile) {
        auto src = read(srcFile).as!string;
        auto target = read(targetFile).as!string;

        auto srcTokens = tokenise(src);
        auto targetTokens = tokenise(target);

        // writefln("Src tokens:");
        // foreach(i; 0..10) {
        //     writefln("%s", srcTokens[i].toString());
        // }
        // writefln("Target tokens:");
        // foreach(i; 0..10) {
        //     writefln("%s", targetTokens[i].toString());
        // }

        if(srcTokens.length != targetTokens.length) {
            writefln("Token count mismatch: %s != %s", srcTokens.length, targetTokens.length);
        }

        auto count = srcTokens.length < targetTokens.length ? srcTokens.length : targetTokens.length;
        foreach(i; 0..count) {

            string srcToken = srcTokens[i].text;
            string targetToken = targetTokens[i].text;

            bool equal = srcToken == targetToken;
            string estr = equal ? "==" : "!=";

            if(!equal) {
                writefln("[%s %s] %s %s %s", srcTokens[i].line, targetTokens[i].line, srcToken, estr, targetToken);
                return false;
            }
        }
        return true;
    }

private:
    enum Kind { NONE, STRING, PUNCTUATION, NUMBER, IDENTIFIER }
    
    static struct Token {
        Kind kind;
        string text;
        uint pos;
        uint line;

        string toString() {
            return format("[%s] %s %s", line, kind, text);
        }
    }

    static Token[] tokenise(string str) {
        int pos = 0;
        int eot = 0;
        int line = 1;
        int lineStart = 0;
        bool ecIgnore = false;
        Token[] tokens;

        bool isDigit(char c) {
            return c >= '0' && c <= '9';
        }
        char peek(int offset = 0) {
            return pos + offset >= str.length ? 0 : str[pos + offset];
        }
        bool isEol() {
            return peek() == 10 || peek() == 13;
        }
        void eol() {
            // can be 13,10 or just 10
            if(peek()==13) pos++;
            if(peek()==10) pos++;
            line++;
            lineStart = pos;
        }
        void addToken(char op = 0) {
            if(ecIgnore) {
                eot = pos;
                pos += op !=0 ? 1 : 0;
                return;
            } 
            if(pos > eot) {
                string text = str[eot..pos];
                Kind k = Kind.IDENTIFIER;
                char ch1 = text[0];
                char ch2 = text.length > 1 ? text[1] : 0;

                if(ch1 == '\'') k = Kind.NUMBER;
                else if(ch1 == '"') k = Kind.STRING;
                else if(isDigit(ch1) || (ch1=='-' && isDigit(ch2)) || (ch1=='.' && isDigit(ch2))) k = Kind.NUMBER;
        
                tokens ~= Token(k, text, eot, line);
            }
            if(op != 0) {
                string text = str[pos..pos+1];
                tokens ~= Token(Kind.PUNCTUATION, text, pos, line);
                pos++;
            }
            eot = pos;
        }
        void consumeLineDirective() {
            addToken();
            while(pos < str.length) {
                if(isEol()) {
                    eol();
                    break;
                }
                pos++;
            }
            eot = pos;
        }
        void consumeWhitespace() {
            addToken();
            while(pos < str.length) {
                if(isEol()) {
                    eol();
                } else if(peek() < 33) {
                    pos++;
                } else {
                    break;
                }
            }
            eot = pos;
        }
        void consumeLineComment() {
            addToken();
            // if(str[pos..pos+21] == "//__ec_ignore_start__") {
            //     ecIgnore = true;
            // } else if(str[pos..pos+19] == "//__ec_ignore_end__") {
            //     ecIgnore = false;
            // }

            while(pos < str.length) {
                if(isEol()) {
                    eol();
                    break;
                }
                pos++;
            }
            eot = pos;
        }
        void consumeMultiLineComment() {
            addToken();
            while(pos < str.length) {
                if(isEol()) {
                    eol();
                } else if(peek()=='*' && peek(1)=='/') {
                    pos+=2;
                    break;
                } else {
                    pos++;
                }
            }
            eot = pos;
        }
        void consumeString() {
            addToken();
            assert(peek()=='"');
            pos++;
            while(pos < str.length) {
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
            assert(peek() == '\'');
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

        while(pos < str.length) {
            char ch = peek();
            //writefln("[%s] ch = %s", pos, ch);
            switch(ch) {
                case 0: ..case 32:
                    consumeWhitespace();
                    break;
                case 33: // !
                    addToken(ch);
                    break; 
                case 34: // "
                    consumeString();
                    break;
                case 35: // #
                    if(peek(1) == 'l' && peek(2) == 'i' && peek(3) == 'n' && peek(4) == 'e') {
                        consumeLineDirective();
                    } else {
                        addToken(ch);
                    }
                    break;
                case 36: .. case 38: // $ .. &
                    addToken(ch);
                    break;
                case 39: // '
                    consumeChar();
                    break;
                case 40: .. case 44: // ( .. ,
                    addToken(ch);
                    break;
                case '-': // 45
                    addToken(ch);
                    break;
                case '.': // 46
                    addToken(ch);
                    break;    
                case '/': // 47
                    if(peek(1) == '/') {
                        consumeLineComment();
                    } else if(peek(1) == '*') {
                        consumeMultiLineComment();
                    } else {
                        addToken(ch);
                    }
                    break;
                case 58: .. case 64: // : .. @
                    addToken(ch);
                    break;
                case 91: .. case 94: // [ .. ^
                    addToken(ch);
                    break;
                case 95: // _
                    pos++;
                    break;
                case 96: // `
                    addToken(ch);
                    break;
                case 123: .. case 126: // { .. ~
                    addToken(ch);
                    break;    
                default:
                    // anything else we will assume is an identifier char
                    pos++;
                    break;
            }
        }

        return tokens;
    }
}

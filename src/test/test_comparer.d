module test.test_comparer;

import std.stdio     : writefln;
import std.file      : read;
import std.format    : format;
import std.typecons  : Tuple, tuple;
import std.algorithm : map;
import std.range     : array, join;

import common.utils;

final class TestComparer {
public:
    bool compareStrict(string srcFile, string targetFile) {
        auto src = read(srcFile).as!string;
        auto target = read(targetFile).as!string;

        auto srcTokens = tokenise(src);
        auto targetTokens = tokenise(target);

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
    bool compareRelaxed(string expectedFile, string genFile) {
        string expected = read(expectedFile).as!string;
        string gen      = read(genFile).as!string;

        Token[] expTokens = tokenise(expected);
        Token[] genTokens = tokenise(gen);

        int expPos;
        int genPos;

        string peekExpected(int offset, bool simplify = false) {
            if(expPos + offset >= expTokens.length) return "";
            string s = expTokens[expPos + offset].text;
            if(simplify) {
                if(s[0] == '\"') s = "<string>";
            }
            return s;
        }
        string peekGenerated(int offset, bool simplify = false) {
            if(genPos + offset >= genTokens.length) return "";
            string s = genTokens[genPos + offset].text;
            if(simplify) {
                if(s[0] == '\"') s = "<string>";
            }
            return s;
        }
        bool expMatches(string[] t...) {
            foreach(i; 0..t.length) {
                string s = peekExpected(i.as!int, true);
                if(s != t[i]) return false;
            }
            return true;
        }
        bool genMatches(string[] t...) {
            foreach(i; 0..t.length) {
                string s = peekGenerated(i.as!int, true);
                if(s != t[i]) return false;
            }
            return true;
        }
        bool eitherMatches(string[] text...) {
            return expMatches(text) || genMatches(text);
        }
        void skipToNextExpectedLine() {
            int line = expTokens[expPos].line;
            do{
                expPos++;
            }while(expPos < expTokens.length && expTokens[expPos].line == line);
        }
        struct AllowedMatch {
            string[] expValues;
            string[] genValues; // if different
            bool anyOrder;

            this(string[] values, bool anyOrder) {
                this.expValues = values;
                this.genValues = values;
                this.anyOrder = anyOrder;
            }
            this(string[] expValues, string[] genValues, bool anyOrder) {
                this.expValues = expValues;
                this.genValues = genValues;
                this.anyOrder = anyOrder;
            }

            bool isMatch() {
                if(anyOrder) {
                    return matchesAnyOrder();
                }
                return matchesInOrder(); 
            }
            bool matchesInOrder() {
                return(expMatches(expValues) && genMatches(genValues));
            }
            bool matchesAnyOrder() {
                bool[string] expSeen;
                bool[string] genSeen;

                foreach(i; 0..expValues.length) {
                    expSeen[peekExpected(i.as!int, true)] = true;
                }
                foreach(i; 0..genValues.length) {
                    genSeen[peekGenerated(i.as!int, true)] = true;
                }
                foreach(v; expValues) {
                    if(v !in expSeen) {
                        return false;
                    }
                }
                foreach(v; genValues) {
                    if(v !in genSeen) {
                        return false;
                    }
                }
                return true;
            }
            string toString() {
                return "exp: %s gen: %s anyOrder: %s".format(expValues, genValues, anyOrder);
            }
        }
        AllowedMatch NO_ALLOWED_MATCH = AllowedMatch([], [], false);
        AllowedMatch[] allowedMatches = [
            AllowedMatch(["__int64"], 
                         ["long", "long"], false),
            AllowedMatch(["const", "wchar_t"], true),
            AllowedMatch(["const", "_locale_t"], true),
            AllowedMatch(["const", "size_t"], true),
            AllowedMatch(["const", "int"], true),
            AllowedMatch(["const", "char"], true),
            AllowedMatch(["const", "fpos_t"], true),
            AllowedMatch(["const", "void"], true),

            AllowedMatch(["const", "unsigned", "short"], true),
            AllowedMatch(["__declspec", "(", "noinline", ")", "__inline", "unsigned", "__int64"], 
                         ["__declspec", "(", "noinline", ")", "__inline", "unsigned", "long", "long"], true),

            AllowedMatch(["__inline", "int", "__cdecl", "__declspec", "(", "deprecated", "(", "<string>", "<string>", "<string>", "<string>", ")", ")"], true),            
        ];
        Tuple!(bool, "isMatch", AllowedMatch, "match") checkAllowedMatches() {
            foreach(m; allowedMatches) {
                if(m.isMatch()) return tuple!("isMatch", "match")(true, m);
            }
            return tuple!("isMatch", "match")(false, NO_ALLOWED_MATCH);
        }

        while(expPos < expTokens.length && genPos < genTokens.length) {

            // Skip #pragma once in the expected stream
            if(expMatches("#", "pragma", "once")) {
                writefln("Skipping #pragma once");
                skipToNextExpectedLine();
                continue;
            }
            // Skip #pragma region in the expected stream
            if(expMatches("#", "pragma", "region")) {
                writefln("Skipping #pragma region");
                skipToNextExpectedLine();
                continue;
            }
            // Skip #pragma endregion in the expected stream
            if(expMatches("#", "pragma", "endregion")) {
                writefln("Skipping #pragma endregion");
                skipToNextExpectedLine();
                continue;
            }
            // unsigned -> unsigned int match
            if(genMatches("unsigned", "int") && expMatches("unsigned") && expTokens[expPos+1].text != "int") {
                writefln("Skipping unsigned -> unsigned int match");
                expPos++;
                genPos+=2;
                continue;
            }

            string expToken = peekExpected(0);
            string genToken = peekGenerated(0);

            bool equal = expToken == genToken;
            
            if(!equal) {
                auto m = checkAllowedMatches();
                if(m.isMatch) {
                    writefln("    Allowed match @ line exp.%s, gen.%s:", expTokens[expPos].line, genTokens[genPos].line);
                    writefln("     exp: %s", expTokens[expPos..expPos + m.match.expValues.length].map!(t=>t.text).join(" "));
                    writefln("          %s", m.match.expValues);
                    writefln("     gen: %s", genTokens[genPos..genPos + m.match.genValues.length].map!(t=>t.text).join(" "));
                    writefln("          %s", m.match.genValues);
                    expPos += m.match.expValues.length;
                    genPos += m.match.genValues.length;
                    continue;
                }

                writefln("expected[%s '%s'] != generated[%s '%s']", expTokens[expPos].line, expToken, genTokens[genPos].line, genToken);
                return false;
            }

            expPos++;
            genPos++;
        }

        if(expPos < expTokens.length || genPos < genTokens.length) {
            writefln("Token length mismatch: %s != %s", expPos, genPos);
            return false;
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

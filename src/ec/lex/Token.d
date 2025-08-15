module ec.lex.Token;

import ec.all;

__gshared const NO_TOKEN = Token(TKind.NONE, null, 0, 0);
__gshared uint[string] g_originalFilenames; // original filenames to index
__gshared string[] g_originalFilenamesArray; 

struct Token {
    TKind kind;
    string text;
    uint line;
    uint column;
    uint originalLine;          // line in original source file, before preprocessing
    uint originalFilenameIndex; // index into g_originalFilenames

    string toString() {
        string s;
        if(lengthOf(kind) == 0) {
            string t = text;
            if(t.length > 30) t = t[0..30] ~ "...";
            t = t.replace("%s", "%%");
            s = format("%s:%s", t, kind);
        } else  {
            s = "'" ~ stringOf(kind) ~ "'";
        }
        return "%s %s:%s (%s:%s)".format(s, line, column, originalLine, originalFilenameIndex);
    }
}

string toString(Token[] tokens) {
    string s = "[";
    foreach(t; tokens) {
        s ~= "\n  %s ".format(t.toString());
    }
    return "%s\n]".format(s);
}

enum TKind {
    NONE,
    IDENTIFIER,
    NUMBER,
    STRING,
    CHAR,

    FWD_SLASH,
    STAR,
    PERCENT,
    PLUS,
    MINUS,
    EQUALS,
    EXCLAMATION_MARK,
    AMPERSAND,
    PIPE,
    CARET,
    TILDE,

    PLUS2,   // ++
    MINUS2,  // --

    RT_ARROW, // ->
    DOT,
    COMMA,
    SEMI_COLON,
    COLON,
    QUESTION_MARK,
    HASH, 
    ELIPSIS,    // ...

    LPAREN,     // (
    RPAREN,     // )
    LSQUARE,    // [
    RSQUARE,    // ]
    LBRACE,     // {
    RBRACE,     // }
    LANGLE,     // <
    RANGLE,     // >
    LANGLE2,    // <<
    RANGLE2,    // >>
    AMPERSAND2, // &&
    PIPE2,      // ||

    FWD_SLASH_EQ,           // /=   
    STAR_EQ,                // *=
    PERCENT_EQ,             // %=
    PLUS_EQ,                // +=
    MINUS_EQ,               // -=
    EQUALS2,                // ==
    EXCLAMATION_MARK_EQ,    // !=
    AMPERSAND_EQ,           // &=
    PIPE_EQ,                // |=
    CARET_EQ,               // ^=
    TILDE_EQ,               // ~=
    LANGLE_EQ,              // <=
    RANGLE_EQ,              // >=
    LANGLE2_EQ,             // <<=
    RANGLE2_EQ,             // >>=
}

string stringOf(TKind t) {
    final switch(t) {
        case TKind.NONE: return "NONE";
        case TKind.IDENTIFIER: return "IDENTIFIER";
        case TKind.NUMBER: return "NUMBER";
        case TKind.STRING: return "STRING";
        case TKind.CHAR: return "CHAR";

        case TKind.FWD_SLASH: return "/";
        case TKind.STAR: return "*";
        case TKind.PERCENT: return "%";
        case TKind.PLUS: return "+";
        case TKind.MINUS: return "-";
        case TKind.EQUALS: return "=";
        case TKind.EXCLAMATION_MARK: return "!";
        case TKind.AMPERSAND: return "&";
        case TKind.PIPE: return "|";
        case TKind.CARET: return "^";
        case TKind.TILDE: return "~";
        case TKind.RT_ARROW: return "->";
        case TKind.DOT: return ".";
        case TKind.COMMA: return ",";
        case TKind.SEMI_COLON: return ";";
        case TKind.COLON: return ":";
        case TKind.LPAREN: return "(";
        case TKind.RPAREN: return ")";
        case TKind.LSQUARE: return "[";
        case TKind.RSQUARE: return "]";
        case TKind.LBRACE: return "{";
        case TKind.RBRACE: return "}";
        case TKind.LANGLE: return "<";
        case TKind.RANGLE: return ">";
        case TKind.QUESTION_MARK: return "?";
        case TKind.HASH: return "#";
        case TKind.LANGLE2: return "<<";
        case TKind.RANGLE2: return ">>";
        case TKind.ELIPSIS: return "...";
        case TKind.AMPERSAND2: return "&&";
        case TKind.PIPE2: return "||";
        case TKind.PLUS2: return "++";
        case TKind.MINUS2: return "--";

        case TKind.FWD_SLASH_EQ: return "/=";
        case TKind.STAR_EQ: return "*=";
        case TKind.PERCENT_EQ: return "%=";
        case TKind.PLUS_EQ: return "+=";
        case TKind.MINUS_EQ: return "-=";
        case TKind.EQUALS2: return "==";
        case TKind.EXCLAMATION_MARK_EQ: return "!=";
        case TKind.AMPERSAND_EQ: return "&=";
        case TKind.PIPE_EQ: return "|=";
        case TKind.CARET_EQ: return "^=";
        case TKind.TILDE_EQ: return "~=";
        case TKind.LANGLE_EQ: return "<=";
        case TKind.RANGLE_EQ: return ">=";
        case TKind.LANGLE2_EQ: return "<<=";
        case TKind.RANGLE2_EQ: return ">>=";
    }
}

int lengthOf(TKind t) {
    final switch(t) {
        case TKind.NONE: 
        case TKind.IDENTIFIER: 
        case TKind.NUMBER: 
        case TKind.STRING: 
        case TKind.CHAR: 
            return 0;
            
        case TKind.FWD_SLASH: 
        case TKind.STAR: 
        case TKind.PERCENT:
        case TKind.PLUS: 
        case TKind.MINUS: 
        case TKind.EQUALS: 
        case TKind.DOT: 
        case TKind.COMMA: 
        case TKind.SEMI_COLON: 
        case TKind.COLON: 
        case TKind.LPAREN: 
        case TKind.RPAREN: 
        case TKind.LSQUARE: 
        case TKind.RSQUARE: 
        case TKind.LBRACE: 
        case TKind.RBRACE: 
        case TKind.QUESTION_MARK: 
        case TKind.EXCLAMATION_MARK: 
        case TKind.AMPERSAND: 
        case TKind.PIPE: 
        case TKind.CARET: 
        case TKind.TILDE: 
        case TKind.HASH:
        case TKind.LANGLE: 
        case TKind.RANGLE:
            return 1;
        case TKind.FWD_SLASH_EQ: 
        case TKind.STAR_EQ: 
        case TKind.PERCENT_EQ: 
        case TKind.PLUS_EQ: 
        case TKind.MINUS_EQ: 
        case TKind.EQUALS2: 
        case TKind.EXCLAMATION_MARK_EQ: 
        case TKind.AMPERSAND_EQ: 
        case TKind.PIPE_EQ: 
        case TKind.CARET_EQ: 
        case TKind.TILDE_EQ: 
        case TKind.LANGLE_EQ: 
        case TKind.RANGLE_EQ:
        case TKind.LANGLE2: 
        case TKind.RANGLE2: 
        case TKind.AMPERSAND2: 
        case TKind.PIPE2:
        case TKind.PLUS2:
        case TKind.MINUS2:
        case TKind.RT_ARROW:
            return 2;
        case TKind.LANGLE2_EQ: 
        case TKind.RANGLE2_EQ: 
        case TKind.ELIPSIS:
            return 3;
    }
}

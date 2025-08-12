module ec.parse.stmt.Stmt;

import ec.all;

abstract class Stmt : Node {
    const EStmt estmt;
    const Location location;

    this(EStmt estmt, Location location) {
        this.estmt = estmt;
        this.location = location;
    }
}

struct Location {
    int line;
    int column;
    int originalLine;
    uint originalFilenameIndex;

    string originalFilename() const {
        return g_originalFilenamesArray[originalFilenameIndex];
    }

    string toString() const {
        return "%s:%s".format(line, column);
    }
}

enum EStmt {
    UNKNOWN,

    // expr
    ADDRESSOF,
    CALL,
    CAST,
    DOT,
    IDENTIFIER,
    INFIX,
    INITIALISER, 
    NUMBER,
    PARENS,
    PREFIX,
    POSTFIX,
    STRING_LITERAL, 
    TERNARY,
    VALUEOF,

    // stmt
    BREAK,
    CONTINUE,
    DO_WHILE,
    ENUM,
    FOR,
    FUNC,
    IF,
    LABEL, 
    PRAGMA,
    RETURN,
    SCOPE,
    STRUCT,
    SWITCH,
    TYPEDEF,
    UNION,
    VAR,
    WHILE,
}

module ec.parse.stmt.Enum;

import ec.all;

/**
 * Enum
 *   { Expr }   optional initialisers
 *
 */
final class Enum : Stmt {
public:
    string name;
    bool hasBody;
    Member[] members;
    bool hasTrailingComma; // true if the last member has a comma after it

    TypeModifiers modifiers;

    static struct Member {
        string label;
        int exprIndex;  // the expr index in children (or -1 if none)
    }

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override string toString() {
        return "enum %s".format(name);
    }
}

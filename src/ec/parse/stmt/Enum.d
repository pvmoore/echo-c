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

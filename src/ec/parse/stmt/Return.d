module ec.parse.stmt.Return;

import ec.all;

/**
 * Return
 *   [ Expr ]
 */
final class Return : Stmt {
public:

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    bool hasExpr() { return hasChildren(); }
    Expr expr() { assert(hasExpr()); return first().as!Expr; }

    override string toString() {
        return "return";
    }
}

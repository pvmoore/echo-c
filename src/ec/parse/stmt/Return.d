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

    bool hasExpr() { return children.length > 0; }
    Expr expr() { assert(hasExpr()); return children[0].as!Expr; }

    override string toString() {
        return "return";
    }
}

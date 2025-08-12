module ec.parse.expr.Addressof;

import ec.all;

/**
 * Addressof
 *    Expr
 */
final class Addressof : Expr {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr expr() { return children[0].as!Expr; }

    override int precedence() {
        return 2;
    }

    override string toString() {
        return "&";
    }
}

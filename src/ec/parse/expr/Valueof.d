module ec.parse.expr.Valueof;

import ec.all;

/**
 * Valueof
 *   Expr
 */
final class Valueof : Expr {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr expr() { return first().as!Expr; }

    override int precedence() { return 2; }

    override string toString() {
        return "*";
    }
}

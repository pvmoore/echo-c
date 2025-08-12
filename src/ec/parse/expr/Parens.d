module ec.parse.expr.Parens;

import ec.all;

/**
 * Parens
 *   Expr
 */
final class Parens : Expr {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr expr() { return children[0].as!Expr; }

    override int precedence() { return 15; }

    override string toString() {
        return "()";
    }
}

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

    Expr expr() { return first().as!Expr; }

    override int precedence() { return PRECEDENCE_PARENS; }

    override string toString() {
        return "()";
    }
}

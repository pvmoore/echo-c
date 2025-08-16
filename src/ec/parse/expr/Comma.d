module ec.parse.expr.Comma;

import ec.all;

/**
 * Comma
 *    Expr lhs
 *    Expr rhs
 */
final class Comma : Expr {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr left() { return first().as!Expr; }
    Expr right() { return last().as!Expr; }

    override int precedence() { return 15; }

    override string toString() {
        return ",";
    }
}

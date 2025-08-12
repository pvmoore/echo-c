module ec.parse.expr.Infix;

import ec.all;

/**
 * Infix
 *   Expr
 *   Expr
 */
final class Infix : Expr {
public:
    Operator op;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr left() { return first().as!Expr; }
    Expr right() { return last().as!Expr; }

    override int precedence() { return precedenceOf(op); }

    override string toString() {
        return "Infix(%s)".format(op.stringOf());
    }
}

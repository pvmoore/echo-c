module ec.parse.expr.Postfix;

import ec.all;

/**
 * Postfix
 *    Expr
 */
final class Postfix : Expr {
public:
    Operator op;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override int precedence() { return precedenceOf(op); }

    Expr expr() { return first().as!Expr; }

    override string toString() {
        return "Postfix(%s)".format(op.stringOf());
    }
}

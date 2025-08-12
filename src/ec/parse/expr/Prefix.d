module ec.parse.expr.Prefix;

import ec.all;

/**
 * Prefix
 *   Expr expr
 */
final class Prefix : Expr {
public:
    Operator op;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }
    Expr expr() { return children[0].as!Expr; } 

    override int precedence() { return precedenceOf(op); }

    override string toString() {
        return "Prefix(%s)".format(op.stringOf());
    }
}

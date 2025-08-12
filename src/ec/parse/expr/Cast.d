module ec.parse.expr.Cast;

import ec.all;

/**
 * Cast
 *   Expr
 */
final class Cast : Expr {
public:
    Type type;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr expr() { return children[0].as!Expr; }

    override int precedence() { return 2; }

    override string toString() {
        return "Cast to %s".format(type);
    }
}

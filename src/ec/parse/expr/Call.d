module ec.parse.expr.Call;

import ec.all;

/**
 * Call
 *   { Expr } args
 */
final class Call : Expr {
public:
    string name;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr[] args() { return children.map!(c => c.as!Expr).array(); }

    override int precedence() { return 1; }

    override string toString() {
        return "Call %s".format(name);
    }
}

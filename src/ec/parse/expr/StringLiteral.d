module ec.parse.expr.StringLiteral;

import ec.all;

final class StringLiteral : Expr {
public:
    string value;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override int precedence() { return 15; }

    override string toString() {
        return "\"%s\"".format(value);
    }
}

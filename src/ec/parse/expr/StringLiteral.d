module ec.parse.expr.StringLiteral;

import ec.all;

/**
 * StringLiteral
 */
final class StringLiteral : Expr {
public:
    string[] values;    // consecutive string literals 

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override int precedence() { return 15; }

    override string toString() {
        return "%s".format(values);
    }
}

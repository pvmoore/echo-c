module ec.parse.expr.Number;

import ec.all;

/**
 * Number
 *   Expr
 */
final class Number : Expr {
public:
    string stringValue;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }  

    override int precedence() { return 15; }

    override string toString() {
        return "Number(%s)".format(stringValue);
    }
}

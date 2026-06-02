module ec.parse.expr.Identifier;

import ec.all;

/**
 * Identifier
 */
final class Identifier : Expr {
public:
    string name;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override int precedence() {
        return PRECEDENCE_LITERAL;
    }

    override string toString() {
        return name;
    }
}

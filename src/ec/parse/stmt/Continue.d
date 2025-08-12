module ec.parse.stmt.Continue;

import ec.all;

/**
 * Continue
 */
final class Continue : Stmt {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override string toString() {
        return "Continue";
    }
}

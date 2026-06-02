module ec.parse.stmt.Goto;

import ec.all;

/**
 * Goto
 *    Label label
 */
final class Goto : Stmt {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override string toString() {
        return "Goto";
    }
}

module ec.parse.stmt.Break;

import ec.all;

/**
 * Break
 */
final class Break : Stmt {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override string toString() {
        return "Break";
    }
}

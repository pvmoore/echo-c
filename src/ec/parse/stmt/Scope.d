module ec.parse.stmt.Scope;

import ec.all;

/**
 * Scope
 *   { Stmt } stmts
 */
final class Scope : Stmt {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Stmt[] stmts() {
        return children.map!(c => c.as!Stmt).array();
    }

    override string toString() {
        return "{}";
    }
}

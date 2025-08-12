module ec.parse.stmt.Label;

import ec.all;

/**
 * Label
 */
final class Label : Stmt {
public:
    string name;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override string toString() {
        return "Label: " ~ name;
    }
}

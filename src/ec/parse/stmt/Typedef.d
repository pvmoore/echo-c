module ec.parse.stmt.Typedef;

import ec.all;

/**
 * Typedef
 *    [ Struct ]    // if this is present then 'type' must be a StructType pointing to this struct
 */
final class Typedef : Stmt {
    Type type;
    string name;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override string toString() {
        return "Typedef(%s %s)".format(type, name);
    }
}

module ec.parse.stmt.Typedef;

import ec.all;

/**
 * Typedef
 *    [ Struct ]    // if this is present then 'type' must be a StructType pointing to this struct
 */
final class Typedef : Stmt {
    Type type;
    string name;

    // Several Typedefs declared on the same line eg. typedef signed char INT8, *PINT8;
    bool firstInList;   // true if this is the first in the list
    bool inList;        // true if this is one of a comma separated list of vars
    bool lastInList;    // true if this is the last in the list

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    override string toString() {
        return "Typedef(%s %s)".format(type, name);
    }
}

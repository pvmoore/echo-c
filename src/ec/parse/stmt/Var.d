module ec.parse.stmt.Var;

import ec.all;

/**
 * Variable
 *    Expr initialiser
 */
final class Var : Stmt {
public:
    Type type;
    string name;
    StorageClass storageClass;
    bool isParam;

    // Several Vars declared on the same line eg. int a, b, *c;
    bool firstInList;   // true if this is the first in the list
    bool inList;        // true if this is one of a comma separated list of vars
    bool lastInList;    // true if this is the last in the list

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    bool isGlobal() { return parent.isA!CFile; }

    bool hasInitialiser() { return children.length > 0; }

    Expr initialiser() { assert(hasInitialiser()); return children[0].as!Expr; }

    override bool isResolved() {
        return type.isResolved();
    }

    override string toString() {
        return "%s %s".format(type, name);
    }
}

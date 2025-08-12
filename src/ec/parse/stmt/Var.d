module ec.parse.stmt.Var;

import ec.all;

/**
 * Variable
 *    [ Expr ] Bitfield
 *    [ Expr ] initialiser
 */
final class Var : Stmt {
public:
    Type type;
    string name;
    StorageClass storageClass;
    bool isParam;
    bool hasInitialiser;// true if there is an init Expr
                        // If true then last() is the initialiser Expr   

    bool hasBitfield;   // if this is true then first() is the bitfield Expr
                        // which is usually just a number but could be an Expr

    // Several Vars declared on the same line eg. int a, b, *c;
    bool firstInList;   // true if this is the first in the list
    bool inList;        // true if this is one of a comma separated list of vars
    bool lastInList;    // true if this is the last in the list

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    bool isGlobal() { return parent.isA!CFile; }

    Expr bitfield() { assert(hasBitfield); return first().as!Expr; }
    Expr initialiser() { assert(hasInitialiser); return last().as!Expr; }

    override bool isResolved() {
        return type.isResolved();
    }

    override string toString() {
        string bf = hasBitfield ? " : BITFIELD" : "";
        return "%s %s%s".format(type, name, bf);
    }
}

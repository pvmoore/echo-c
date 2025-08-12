module ec.parse.stmt.Switch;

import ec.all;

/**
 * Switch
 *    Expr          expression to switch on
 *    { Stmt }      case expressions and statements
 *
 */
final class Switch : Stmt {
public:
    Case[] cases;

    static struct Case {
        bool isDefault;
        uint childIndex;
    }

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr condition() { return first().as!Expr; }

    override string toString() {
        return "Switch";
    }
}

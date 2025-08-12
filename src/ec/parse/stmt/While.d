module ec.parse.stmt.While;

import ec.all;

/**
 * While
 *    Expr      condition
 *    { Stmt }  body
 *
 */
final class While : Stmt {
public:

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr condition() { return first().as!Expr; }
    Stmt[] body() { return children[1..$].map!(it => it.as!Stmt).array(); }

    override string toString() {
        return "While";
    }
}

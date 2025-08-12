module ec.parse.stmt.DoWhile;

import ec.all;

/**
 * Do
 *    { Stmt }  body
 *    Expr      condition
 *
 */
final class DoWhile : Stmt {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Stmt[] body() { return children[0..$-1].map!(it => it.as!Stmt).array(); }
    Expr condition() { return last().as!Expr; }

    override string toString() {
        return "Do";
    }
}

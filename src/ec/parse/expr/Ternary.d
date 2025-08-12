module ec.parse.expr.Ternary;

import ec.all;

/**
 * Ternary
 *   Expr trueExpr
 *   Expr falseExpr
 *   Expr condition     
 */
final class Ternary : Expr {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr condition() { return children[2].as!Expr; }
    Expr trueExpr() { return children[0].as!Expr; }
    Expr falseExpr() { return children[1].as!Expr; }

    override int precedence() { return 13; }

    override string toString() {
        return "? :";
    }
}

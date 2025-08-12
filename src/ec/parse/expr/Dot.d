module ec.parse.expr.Dot;

import ec.all;

/**
 * Dot
 *   Expr
 *   Expr
 */
final class Dot : Expr {
public:
    bool isArrow;   // true if this is a->x otherwise a.x

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr left() { return first().as!Expr; }
    Expr right() { return last().as!Expr; }

    override int precedence() { return 1; }

    override string toString() {
        return "Dot";
    }
}

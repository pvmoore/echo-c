module ec.parse.expr.Expr;

import ec.all;

abstract class Expr : Stmt {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    abstract int precedence();
}

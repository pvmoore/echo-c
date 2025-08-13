module ec.parse.expr.Index;

import ec.all;

/**
 * Index
 *   { Expr }   index exprs
 *   Expr       array|pointer expr
 */
final class Index : Expr {
public:
    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr pointer() { return last().as!Expr; }
    Expr[] exprs() { return children[0..$-1].as!(Expr[]); }

    override int precedence() { return 1; }

    override string toString() { 
        return "Index"; 
    }
}

module ec.parse.stmt.If;

import ec.all;

/**
 * If
 *   Expr       condition
 *   { Stmt }   thenExprs
 *   { Stmt }   elseExprs (optional)
 */
final class If : Stmt {
public:
    int numThenExprs; 
    bool hasThenBraces; // true if thenExprs are in a brace scope
    bool hasElseBraces; // true if elseExprs are in a brace scope

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Expr condition() { 
        return children[0].as!Expr; 
    }
    Stmt[] thenStmts() { 
        return children[1..1+numThenExprs].map!(c => c.as!Stmt).array(); 
    }
    Stmt[] elseStmts() {
        return children[1+numThenExprs..$].map!(c => c.as!Stmt).array();
    }
    bool hasElse() {
        return (1 + numThenExprs) < children.length;
    }

    override string toString() {
        return "if";
    }
}

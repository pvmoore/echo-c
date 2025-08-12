module ec.parse.stmt.For;

import ec.all;

/**
 * For
 *   { Var }   init vars
 *   Expr       condition
 *   { Expr }   post exprs
 *   { Stmt }   body
 */
final class For : Stmt {
public:
    int conditionIndex;
    int bodyIndex;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Var[] initVars() { return children[0..conditionIndex].map!(it => it.as!Var).array(); }
    Expr condition() { return children[conditionIndex].as!Expr; }
    Expr[] postExprs() { return children[conditionIndex + 1..bodyIndex].map!(it => it.as!Expr).array(); }
    Stmt[] body() { return children[bodyIndex..$].map!(it=>it.as!Stmt).array(); }

    override string toString() {
        return "For";
    }
}

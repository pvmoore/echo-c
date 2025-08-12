module ec.parse.expr.Initialiser;

import ec.all;

/**
 * Initialiser
 *    { Expr }
 *
 * struct:
 * {
 *   .a = 1, 7, .b = 2
 * }
 * 
 * array:
 * { 0, 1, 2 }
 * { 0, [2] = 3, 5 }
 *
 * simple expr:
 * { 0 }
 */
final class Initialiser : Expr {
public:
    Element[] elements;

    enum ElementKind {
        EXPR,       // expr
        LABEL_EXPR, // .a = expr
        INDEX_EXPR  // [index] = expr
    }

    static struct Element {
        ElementKind kind;

        uint exprIndex;     // the expr index in children         
        uint arrayIndex;    // the [index] if this is an INDEX_EXPR
        string label;       // the label if this is a LABEL_EXPR
    }     

    this(EStmt estmt, Location location) {
        super(estmt, location);
    } 

    Expr[] exprs() { return children.map!(it=>it.as!Expr).array(); }

    override int precedence() { return 15; }

    override string toString() {
        return "{init}";
    }
}

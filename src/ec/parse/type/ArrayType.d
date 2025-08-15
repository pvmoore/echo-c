module ec.parse.type.ArrayType;

import ec.all;

/**
 * ArrayType
 *   Type       elementType 
 *   { Expr }   dimensions
 *
 */
final class ArrayType : Type {
public:
    string varName;    // the variable name (if any)

    this() {
        this.etype = EType.ARRAY;
    }

    Type elementType() { return children[0].as!Type; }
    Expr[] dimensionExprs() { return children[1..$].map!(c => c.as!Expr).array(); }

    override Type clone() {
        ArrayType t = new ArrayType();
        t.ptrs = ptrs.dup;
        t.modifiers = modifiers;
        t.varName = varName;
        return t;
    }

    override string toString() {
        return "Array of %s".format(elementType.toString());
    }
}

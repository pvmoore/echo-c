module ec.parse.type.FunctionPtr;

import ec.all;

/**
 *
 *
 *
 */
final class FunctionPtr : Type {
public:
    string varName; // the variable name (if any)
    Var[] params;
    Type returnType;
    CallingConvention callingConvention;

    this() {
        this.etype = EType.FUNCTION_PTR;
    }

    override Type clone() {
        FunctionPtr t = new FunctionPtr();
        t.ptrs = ptrs.dup;
        t.qualifiers = qualifiers;
        t.varName = varName;
        t.params = params.dup;
        t.returnType = returnType;
        return t;
    }

    override string toString() {
        return "%s(%s, %s)".format(returnType, getPtrString(), params.map!(it=>it.toString()).join(", "));
    }
}

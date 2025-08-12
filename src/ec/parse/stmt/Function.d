module ec.parse.stmt.Function;

import ec.all;

/**
 * Function
 *   { Var }   params
 *   { Stmt }   body
 */
final class Function : Stmt {
public:
    string name;
    Type returnType;
    CallingConvention callingConvention;
    StorageClass storageClass;
    int numParams;
    bool hasBody;   // true if this is a definition, otherwise this is a declaration

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Var[] params() { return children[0..numParams].map!(c => c.as!Var).array(); }

    Stmt[] body() { assert(hasBody); return children[numParams..$].map!(c => c.as!Stmt).array(); }

    override string toString() {
        return "Function(%s %s(%s))".format(returnType, name, params);
    }
}

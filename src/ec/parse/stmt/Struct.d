module ec.parse.stmt.Struct;

import ec.all;

/**
 * StructDef
 *    { Stmt }    members
 */
final class Struct : Stmt {
public:
    string name;    // this may be optional if the Struct is inside a typedef eg.
                    // typedef struct <noname> { int x; } MyType;
                    // In this case the typedef has the name

    bool hasBody;   // true if this is a definition, otherwise this is a declaration

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Stmt[] body() { assert(hasBody); return children.map!(c => c.as!Stmt).array(); }

    override string toString() {
        return "Struct(%s)".format(name);
    }
private:
}

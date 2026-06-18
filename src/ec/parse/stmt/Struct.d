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

    TypeModifiers modifiers;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    auto varRange() { return children.map!(c => c.as!Var).filter!(v=>v !is null); }

    bool hasBitfields() { return varRange().any!(v => v.hasBitfield); }

    Stmt[] body() { return children.map!(c => c.as!Stmt).array(); }

    override string toString() {
        return "Struct(%s)".format(name);
    }
private:
}

module ec.parse.stmt.Union;

import ec.all;

/**
 * Union
 *    { Stmt }  members
 *
 */
final class Union : Stmt {
public:
    string name;    // this may be optional if the Union is inside a typedef eg.
                    // typedef union <noname> { int x; } MyType;
                    // In this case the typedef has the name

    bool hasBody;   // true if this is a definition, otherwise this is a declaration

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    Stmt[] body() { assert(hasBody); return children.map!(c => c.as!Stmt).array(); }

    override string toString() {
        return "Union(%s)".format(name);
    }
}

module ec.parse.type.TypeRef;

import ec.all;

/**
 * TypeRef
 *    Struct | Union | Enum     optional Type definition
 */
final class TypeRef : Type {
    string name;
    Type type;      // points to the Type or null if the type is a child (Struct, Union, Enum) of this node

    this() {}
    this(string name, Type type) {
        assert(type);
        this.name = name;
        this.type = type;
        this.etype = type.etype;
    }

    override Type clone() {
        throwIf(type is null, "todo - handle clone TypeRef with child");
        TypeRef t = new TypeRef(name, type);
        t.ptrs = ptrs.dup;
        t.qualifiers = qualifiers;
        return t;
    }

    override string toString() {
        if(type is null) {
            if(!hasChildren()) {
                // [ const ] struct <name>;
                // [ const ] enum <name>;
                // [ const ] union <name>;
                string t = "%s".format(etype).toLower();
                return "%s%s %s".format(qualifiers, t, name);
            }
        }
        return "%s%s%s".format(qualifiers, name, getPtrString());
    }
}

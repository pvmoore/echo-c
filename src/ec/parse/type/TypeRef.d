module ec.parse.type.TypeRef;

import ec.all;

/**
 * TypeRef
 *    Struct | Union | Enum | Function    optional Type definition
 */
final class TypeRef : Type {
    string name;

    Type typeRef;    // points to the Type
    Stmt nodeRef;    // points to the Struct, Union, Enum or Function definition 
                     // (may be a child node but could be a child of another TypeRef)

    this(string name, EType etype) {
        this.name = name;
        this.etype = etype;
    }
    this(string name, Type type) {
        this.name = name;
        this.typeRef = type;
        this.etype = type.etype;
    }

    override Type clone() {
        TypeRef t = new TypeRef(name, etype);
        t.typeRef = typeRef;
        t.nodeRef = nodeRef;
        t.ptrs = ptrs.dup;
        t.modifiers = modifiers;
        return t;
    }

    override string toString() {
        if(typeRef is null) {
            // [ const ] struct <name>;
            // [ const ] enum <name>;
            // [ const ] union <name>;
            // storage-class Type <name>(Params);
            if(etype == EType.FUNCTION_DECL) {
                return name;
            }
            string t = "%s".format(etype).toLower();
            return "%s%s %s%s".format(modifiers, t, name, getPtrString());
        }
        return "%s%s%s".format(modifiers, name, getPtrString());
    }
}

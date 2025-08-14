module ec.parse.type.SimpleType;

import ec.all;

final class SimpleType : Type {
    this(EType etype) {
        this.etype = etype;
    }

    override Type clone() {
        SimpleType t = new SimpleType(etype);
        t.ptrs = ptrs.dup;
        t.modifiers = modifiers;
        return t;
    }

    override string toString() {
        return "%s%s%s".format(modifiers, stringOf(etype), getPtrString());
    }
}

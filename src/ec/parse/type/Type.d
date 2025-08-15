module ec.parse.type.Type;

import ec.all;

abstract class Type : Node {
public:
    EType etype;
    PtrFlags[] ptrs;    // one per level of indirection
    TypeModifiers modifiers;

    final int ptrDepth() { return ptrs.length.as!int; }
    final bool isPtr() { return ptrs.length > 0; }

    abstract Type clone();

    final string getPtrString() {
        return ptrs.map!(c => stringOf(c)).join("");
    }
}

bool hasEmbeddedName(Type t) {
    if(auto at = t.as!ArrayType) {
        return true;
    } else if(auto fp = t.as!FunctionPtr) {
        return true;
    } else if(auto tr = t.as!TypeRef) {
        if(tr.nodeRef) return tr.nodeRef.isA!Function; 
    }
    return false;
}

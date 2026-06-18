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

bool isVoidValue(Type t) {
    return t.isA!SimpleType && t.etype == EType.VOID && !t.isPtr();
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

Struct extractStruct(Type t) {
    if(t.isA!TypeRef && t.as!TypeRef.nodeRef.isA!Struct) {
        return t.as!TypeRef.nodeRef.as!Struct;
    }
    return null;
}
Union extractUnion(Type t) {
    if(t.isA!TypeRef && t.as!TypeRef.nodeRef.isA!Union) {
        return t.as!TypeRef.nodeRef.as!Union;
    }
    return null;
}

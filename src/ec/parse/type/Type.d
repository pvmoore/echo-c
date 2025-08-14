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
        // I assume __restrict is an ms keyword. visual studio does not like 'restrict'
        string s;
        foreach(c; ptrs) {
            string f = "*";
            if(c & PtrFlags.VOLATILE) f ~= "volatile ";
            if(c & PtrFlags.CONST) f ~= "const ";
            if(c & PtrFlags.RESTRICT) f ~= "__restrict ";
            if(c & PtrFlags.PTR32) f ~= "__ptr32 ";
            if(c & PtrFlags.PTR64) f ~= "__ptr64 ";
            if(c & PtrFlags.UNALIGNED) f ~= "__unaligned ";
            s ~= f.strip();
        }
        return s;
    }
}

/**
 * Extract the name from a FunctionPtr or ArrayType.
 */
string extractVariableName(Type t) {
    if(auto at = t.as!ArrayType) {
        if(auto fp = at.elementType().as!FunctionPtr) {
            return fp.varName;
        } 
        return at.varName;
    } else if(auto fp = t.as!FunctionPtr) {
       return fp.varName;
    } else if(auto tr = t.as!TypeRef) {
        if(tr.etype.isOneOf(EType.FUNCTION_DECL, EType.FUNCTION_PTR)) {
            return tr.name;
        }
    }
    return null;
}

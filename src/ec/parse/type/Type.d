module ec.parse.type.Type;

import ec.all;

abstract class Type : Node {
public:
    EType etype;
    PtrFlags[] ptrs;    // one per level of indirection
    TypeQualifiers qualifiers;

    final int ptrDepth() { return ptrs.length.as!int; }
    final bool isPtr() { return ptrs.length > 0; }

    abstract Type clone();

    final string getPtrString() {
        // I assume __restrict is an ms keyword. visual studio does not like 'restrict'
        string s;
        foreach(c; ptrs) {
            string f = "*";
            if(c & PtrFlags.CONST) f ~= "const ";
            if(c & PtrFlags.VOLATILE) f ~= "volatile ";
            if(c & PtrFlags.RESTRICT) f ~= "__restrict ";
            s ~= f.strip();
        }
        return s;
    }
}

enum PtrFlags {
    STD       = 0,
    CONST     = 1,
    VOLATILE  = 2,
    RESTRICT  = 4
}

enum EType {
    VOID,
    BOOL,
    CHAR,
    SHORT,
    INT,            // assume 32 bits
    LONG,           // >= 32 bits (usually 32 bits)
    INT64,          // 64 bits (usually 64 bits)
    FLOAT,
    DOUBLE,
    LONG_DOUBLE,    // >= 64 bits (usually 64 bits)
    VARARG,         // ... (param only)

    ARRAY,
    ENUM,
    STRUCT,
    UNION,
    FUNCTION_PTR,
}

string stringOf(EType t) {
    final switch(t) {
        case EType.VOID: return "void";
        case EType.BOOL: return "bool";
        case EType.CHAR: return "char";
        case EType.SHORT: return "short";
        case EType.INT: return "int";
        case EType.LONG: return "long"; 
        case EType.INT64: return "long long";
        case EType.FLOAT: return "float";
        case EType.DOUBLE: return "double";
        case EType.LONG_DOUBLE: return "long double";
        case EType.VARARG: return "...";
        case EType.STRUCT: return "struct";
        case EType.FUNCTION_PTR: return "function pointer";
        case EType.ARRAY: return "array";
        case EType.ENUM: return "enum";
        case EType.UNION: return "union";
    }
}

struct TypeQualifiers {
    bool isConst;  
    bool isSigned;
    bool isUnsigned;
    bool isVolatile;
    bool isRestrict;

    bool any() {
        return isConst || isSigned || isUnsigned || isVolatile || isRestrict;
    }

    void mergeFrom(TypeQualifiers other) {
        isConst |= other.isConst;
        isSigned |= other.isSigned;
        isUnsigned |= other.isUnsigned;
        isVolatile |= other.isVolatile;
        isRestrict |= other.isRestrict;
    }

    string toString() {
        string s;
        if(isConst) s ~= "const ";
        if(isSigned) s ~= "signed ";
        if(isUnsigned) s ~= "unsigned ";
        if(isVolatile) s ~= "volatile ";
        if(isRestrict) s ~= "restrict ";
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
    } 
    return null;
}

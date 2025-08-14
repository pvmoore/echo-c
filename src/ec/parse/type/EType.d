module ec.parse.type.EType;

import ec.all;

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
    FUNCTION_DECL,
    FUNCTION_PTR,
}

string stringOf(EType t) {
    final switch(t) {
        case EType.VOID: return "void";
        case EType.BOOL: return "_Bool";
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
        case EType.FUNCTION_DECL: return "function declaration";
        case EType.FUNCTION_PTR: return "function pointer";
        case EType.ARRAY: return "array";
        case EType.ENUM: return "enum";
        case EType.UNION: return "union";
    }
}

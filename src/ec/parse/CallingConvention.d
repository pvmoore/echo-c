module ec.parse.CallingConvention;

import ec.all;

enum CallingConvention {
    DEFAULT = 0,    // default calling convention
    CDECL,          // __cdecl caller cleans the stack
    CLRCALL,        // __clrcall
    STDCALL,        // __stdcall win32 callee cleans the stack
    FASTCALL,       // __fastcall 
    THISCALL,       // __thiscall
    VECTORCALL,     // __vectorcall
}

CallingConvention parseCallingConvention(Tokens tokens) {
    CallingConvention cc = CallingConvention.DEFAULT;
    switch(tokens.text()) {
        case "__cdecl": cc = CallingConvention.CDECL; break;
        case "__clrcall": cc = CallingConvention.CLRCALL; break;
        case "__stdcall": cc = CallingConvention.STDCALL; break;
        case "__fastcall": cc = CallingConvention.FASTCALL; break;
        case "__thiscall": cc = CallingConvention.THISCALL; break;
        case "__vectorcall": cc = CallingConvention.VECTORCALL; break;
        default: break;
    }
    if(cc != CallingConvention.DEFAULT) {
        tokens.next();
    }
    return cc;
}

string stringOf(CallingConvention c) {
    final switch(c) {
        case CallingConvention.DEFAULT: return "";
        case CallingConvention.CDECL: return "__cdecl ";
        case CallingConvention.CLRCALL: return "__clrcall ";
        case CallingConvention.STDCALL: return "__stdcall ";
        case CallingConvention.FASTCALL: return "__fastcall ";
        case CallingConvention.THISCALL: return "__thiscall ";
        case CallingConvention.VECTORCALL: return "__vectorcall ";
    }
}

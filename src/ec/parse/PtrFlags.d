module ec.parse.PtrFlags;

import ec.all;

enum PtrFlags {
    STD       = 0,
    CONST     = 1,
    VOLATILE  = 2,
    RESTRICT  = 4,  // restrict | __restrict
    PTR32     = 8,  // __ptr32
    PTR64     = 16, // __ptr64
    UNALIGNED = 32, // __unaligned
}

PtrFlags[] parsePtrFlags(Tokens tokens) {
    PtrFlags[] flags;

    while(tokens.kind() == TKind.STAR) {
        tokens.next();

        PtrFlags flag = PtrFlags.STD; 
        lp:while(true) {
            switch(tokens.text()) {
                case "const": flag |= PtrFlags.CONST; break;
                case "volatile": flag |= PtrFlags.VOLATILE; break;
                case "restrict": flag |= PtrFlags.RESTRICT; break;
                case "_ptr32":
                case "__ptr32": flag |= PtrFlags.PTR32; break;
                case "_ptr64":
                case "__ptr64": flag |= PtrFlags.PTR64; break;
                case "_unaligned":
                case "__unaligned": flag |= PtrFlags.UNALIGNED; break;
                default: break lp;
            }
            tokens.next();
        } 

        flags ~= flag;  // add a pointer level
    }
    return flags;
}

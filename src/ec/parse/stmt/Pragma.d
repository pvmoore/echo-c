module ec.parse.stmt.Pragma;

import ec.all;

/**
 * Pragma
 *
 */
final class Pragma : Stmt {
    PragmaKind kind;
    Data data;

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    enum PragmaKind {
        PACK,
        WARNING,
        INTRINSIC
    }
    static union Data {
        Warning[] warnings;
        Pack pack;
        Intrinsic intrinsic;
    }
    static struct Warning {
        string specifier;       // disable, once, error, etc.
        string[] numbers;       // 4507, 4034, etc.
        string justification;   // eg. "This warning is disabled because i don't like it"
        bool push;              // #pragma warning( push [, level] ) 
        bool pop;               // #pragma warning( pop )
        uint level;             // set if push is true and a level is specified    

        string toString() {
            if(push) return "warning(push%s)".format(level != 0 ? ", %s".format(level) : "");
            if(pop) return "warning(pop)";
            return "warning(%s : %s%s)".format(specifier, numbers, justification ? ", " ~ justification : "");
        }
    }
    static struct Pack {
        bool isPush;    // #pragma pack(push, n)
        bool isPop;     // #pragma pack(pop)
        uint n;         // n, this can still be set if !isPush && !isPop --> #pragma pack(n)
        
        string toString() {
            return "pack(%s%s)".format(isPush ? "push " : isPop ? "pop " : "", n);
        }
    }
    static struct Intrinsic {
        string[] funcnames;
    }

    override string toString() {
        if(kind == PragmaKind.INTRINSIC) {
            return "Pragma(INTRINSIC, %s)".format(data.intrinsic.funcnames);
        }
        if(kind == PragmaKind.WARNING) {
            string s = "Pragma(WARNING, ";
            foreach(i, w; data.warnings) {
                if(i != 0) s ~= "; ";
                s ~= w.toString();
            }
            return s ~ ")";
        } else if(kind == PragmaKind.PACK) {
            return "Pragma(PACK, %s)".format(data.pack.toString());
        }
        return "Pragma(%s, %s)".format(kind, data);
    }
}

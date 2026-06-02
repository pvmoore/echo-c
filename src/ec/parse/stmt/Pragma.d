module ec.parse.stmt.Pragma;

import ec.all;

/**
 * Pragma
 *
 */
final class Pragma : Stmt {
    PragmaKind kind;
    Data data;
    bool isHash;    // #pragma vs __pragma

    this(EStmt estmt, Location location) {
        super(estmt, location);
    }

    enum PragmaKind {
        COMMENT,
        DEPRECATED,
        PACK,
        WARNING,
        INTRINSIC
    }
    static union Data {
        Warning[] warnings;
        Pack pack;
        Intrinsic intrinsic;
        Deprecated deprecated_;
        Comment comment;
    }
    /**
     * comment( comment-type [ , "comment-string" ] )
     */
    static struct Comment {
        string[] comments;
    }
    /** 
     * deprecated( function_1 [, function_2 ... ] )
     */
    static struct Deprecated {
        string[] funcNames;
    }
    /**
     *   warning(
     *      specifier : numbers [ , justification : string-literal]
     *      [; specifier : numbers ... ] 
     *   )
     *   warning( push [ , n ] )
     *   warning( pop )
     */
    static struct Warning {
        string specifier;       // disable, once, error, etc.
        string[] numbers;       // 4507, 4034, etc.
        string justification;   // eg. "This warning is disabled because i don't like it"
        bool push;              // #pragma warning( push [, level] ) 
        bool pop;               // #pragma warning( pop )
        uint level;             // set if push is true and a level is specified    
    }
    /**
     * pack( show )
     * pack( push [ , identifier ] [ , n ] )
     * pack( pop [ , { identifier | n } ] )
     * pack( [ n ] )
     */
    static struct Pack {
        bool isPush;    // #pragma pack(push, n)
        bool isPop;     // #pragma pack(pop)
        uint n;         // n, this can still be set if !isPush && !isPop --> #pragma pack(n)
    }
    /** 
     * intrinsic( function_1 [, function_2 ... ] )
     */
    static struct Intrinsic {
        string[] funcnames;
    }

    override string toString() {

        string str = isHash ? "#pragma " : "__pragma(";

        final switch(kind) {
            case Pragma.PragmaKind.WARNING: 
                str ~= "warning(";
                foreach(i, w; data.warnings) {
                    if(i > 0) str ~= "; ";

                    if(w.push) {
                        str ~= "push";
                        if(w.level > 0) str ~= ", %s".format(w.level);
                    } else if(w.pop) {
                        str ~= "pop";
                    } else {
                        string j = w.justification ? ", justification: %s".format(w.justification) : "";
                        str ~= "%s : %s%s".format(w.specifier, w.numbers.join(" "), j);
                    }
                }
                str ~= ")";
                break;
            case Pragma.PragmaKind.PACK: {
                auto pack = data.pack;
                str ~= "pack(";
                if(pack.isPush && pack.n > 0) {
                    str ~= "push, %s".format(pack.n);
                } else if(pack.isPush && pack.n == 0) {
                    str ~= "push";
                } else if(pack.isPop) {
                    str ~= "pop";
                } else {
                    str ~= "%s".format(pack.n);
                }
                str ~= ")";
                break;
            }
            case Pragma.PragmaKind.INTRINSIC: {
                auto i = data.intrinsic;
                str ~= "intrinsic(%s)".format(i.funcnames.join(", "));
                break;
            }
            case Pragma.PragmaKind.DEPRECATED:
                str ~= "deprecated(%s)".format(data.deprecated_.funcNames.join(", "));
                break;
            case Pragma.PragmaKind.COMMENT:
                str ~= "comment(%s)".format(data.comment.comments.join(", "));
                break;
        }

        if(!isHash) str ~= ")";
        return str;
    }
}

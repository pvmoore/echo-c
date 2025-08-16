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
    static struct Comment {
        string[] comments;

        /** 
         * comment( comment_1 [, comment_2 ... ] )
         */
        string toString() {
            return "comment(%s)".format(comments.join(", "));
        }
    }
    static struct Deprecated {
        string[] funcNames;

        /** 
         * deprecated( function_1 [, function_2 ... ] )
         */
        string toString() {
            return "deprecated(%s)".format(funcNames.join(", "));
        }
    }
    static struct Warning {
        string specifier;       // disable, once, error, etc.
        string[] numbers;       // 4507, 4034, etc.
        string justification;   // eg. "This warning is disabled because i don't like it"
        bool push;              // #pragma warning( push [, level] ) 
        bool pop;               // #pragma warning( pop )
        uint level;             // set if push is true and a level is specified    

        /*
        warning(
           specifier : numbers [ , justification : string-literal]
           [; specifier : numbers ... ] 
        )

        warning( push [ , n ] )

        warning( pop )
        */
        string toString() {
            if(push) return "push%s".format(level != 0 ? ", %s".format(level) : "");
            if(pop) return "pop";
            string n = numbers.join(", ");
            string j = justification ? ", justification: %s".format(justification) : "";
            return "%s : %s%s".format(specifier, n, j);
        }
    }
    static struct Pack {
        bool isPush;    // #pragma pack(push, n)
        bool isPop;     // #pragma pack(pop)
        uint n;         // n, this can still be set if !isPush && !isPop --> #pragma pack(n)
        
        /**
         * pack( show )
         * pack( push [ , identifier ] [ , n ] )
         * pack( pop [ , { identifier | n } ] )
         * pack( [ n ] )
         */
        string toString() {
            return "pack(%s%s)".format(isPush ? "push " : isPop ? "pop " : "", n);
        }
    }
    static struct Intrinsic {
        string[] funcnames;

        /** 
         * intrinsic( function_1 [, function_2 ... ] )
         */
        string toString() {
            return "intrinsic(%s)".format(funcnames.join(", "));
        }
    }

    override string toString() {
        string str = isHash ? "#pragma " : "__pragma(";

        if(kind == PragmaKind.INTRINSIC) {
            str ~= "%s".format(data.intrinsic.toString());
        } else if(kind == PragmaKind.WARNING) {
            string s = "warning( ";
            foreach(i, w; data.warnings) {
                if(i != 0) s ~= "; ";
                s ~= w.toString();
            }
            s ~= " )";
            str ~= s;
        } else if(kind == PragmaKind.PACK) {
            str ~= data.pack.toString();
        } else if(kind == PragmaKind.DEPRECATED) {
            str ~= data.deprecated_.toString();
        } else if(kind == PragmaKind.COMMENT) {
            str ~= data.comment.toString();
        }

        if(!isHash) str ~= ")";
        return str;
    }
}

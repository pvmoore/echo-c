module test.FuzzyMatch;

import std.stdio     : writefln;
import std.format    : format;
import std.algorithm : all, any, map;
import std.typecons  : Tuple, tuple;
import common.utils;
import test.CompareRelaxed;

struct FuzzyMatch {
public:
    string[] expValues;
    string[] genValues;
    bool anyOrder;

    static FuzzyMatch NONE = FuzzyMatch([], [], false);

    string toString() {
        return "exp: %s gen: %s anyOrder: %s".format(expValues, genValues, anyOrder);
    }

    static
    Tuple!(bool, "found", 
           FuzzyMatch, "match", 
           int, "expLength", 
           int, "genLength") 
    findFirstMatch(CompareRelaxed comparer) {
        foreach(m; MATCHES) {
            auto p = m.isMatch(comparer);
            if(p[0]) return tuple!("found", "match", "expLength", "genLength")(true, m, p[1], p[2]);
        }
        return tuple!("found", "match", "expLength", "genLength")(false, FuzzyMatch.NONE, 0, 0);
    }
private:
    static FuzzyMatch[] MATCHES = [
        // in order matches
        FuzzyMatch(["typedef", "ENCLAVE_TARGET_FUNCTION", "(", "*", "PENCLAVE_TARGET_FUNCTION", ")"], 
                   ["typedef", "ENCLAVE_TARGET_FUNCTION", "*", "PENCLAVE_TARGET_FUNCTION"], false),
        FuzzyMatch(["__int64"], ["long", "long"], false),
        FuzzyMatch(["__int32"], ["int"], false),

        // any order matches
        FuzzyMatch(["const", "unsigned", "short"], true),
        FuzzyMatch(["<declspec-noinline>", "__inline", "unsigned", "__int64"], 
                   ["<declspec-noinline>", "__inline", "unsigned", "long", "long"], true),

        FuzzyMatch(["void", "__stdcall", "<declspec-dllimport>", "<declspec-noreturn>"], true),

        FuzzyMatch(["void", "__stdcall", "<declspec-deprecated>", "<declspec-dllimport>"], true),
        FuzzyMatch(["BOOL", "__stdcall", "<declspec-deprecated>", "<declspec-dllimport>"], true),
        FuzzyMatch(["DWORD", "__stdcall", "<declspec-deprecated>", "<declspec-dllimport>"], true),

        FuzzyMatch(["__inline", "wchar_t", "static", "<declspec-deprecated-4>"], true),            

        FuzzyMatch(["struct", "<declspec-align>"], true),
        FuzzyMatch(["union", "<declspec-align>"], true),

        FuzzyMatch(["struct", "<declspec-align>", "<pragma-warning-push>", "<pragma-warning-disable-1>", "<declspec-no-init-all>", "<pragma-warning-pop>"], true),

        FuzzyMatch(["struct", "<declspec-deprecated-1>"], true),

        FuzzyMatch(["const", "struct", "_SMB_SHARE_FLUSH_AND_PURGE_INPUT"], true),
        FuzzyMatch(["const", "struct", "_SMB_SHARE_FLUSH_AND_PURGE_OUTPUT"], true),

        FuzzyMatch(["extern", "const", "<declspec-dllimport>"], true),

        FuzzyMatch(["const", "volatile", "void"], true),
        FuzzyMatch(["const", "volatile", "BOOLEAN"], true),
        FuzzyMatch(["const", "volatile", "BYTE"], true),
        FuzzyMatch(["const", "volatile", "CHAR"], true),
        FuzzyMatch(["const", "volatile", "char"], true),
        FuzzyMatch(["const", "volatile", "SHORT"], true),
        FuzzyMatch(["const", "volatile", "WORD"], true),
        FuzzyMatch(["const", "volatile", "DWORD"], true),
        FuzzyMatch(["const", "volatile", "DWORD64"], true),
        FuzzyMatch(["const", "volatile", "INT32"], true),
        FuzzyMatch(["const", "volatile", "UINT32"], true),
        FuzzyMatch(["const", "volatile", "LONG"], true),
        FuzzyMatch(["const", "volatile", "LONG64"], true),
        FuzzyMatch(["const", "volatile", "PVOID"], true),
        
        FuzzyMatch(["const", "wchar_t"], true),
        FuzzyMatch(["const", "_locale_t"], true),
        FuzzyMatch(["const", "size_t"], true),
        FuzzyMatch(["const", "int"], true),
        FuzzyMatch(["const", "char"], true),
        FuzzyMatch(["const", "fpos_t"], true),
        FuzzyMatch(["const", "void"], true),
        FuzzyMatch(["const", "SHORT"], true),
        FuzzyMatch(["const", "LONG"], true),
        FuzzyMatch(["const", "LONG64"], true),
        FuzzyMatch(["const", "CHAR"], true),
        FuzzyMatch(["const", "BYTE"], true),
        FuzzyMatch(["const", "WORD"], true),
        FuzzyMatch(["const", "DWORD"], true),
        FuzzyMatch(["const", "DWORD64"], true),
        FuzzyMatch(["const", "rsize_t"], true),
        FuzzyMatch(["const", "TOUCHINPUT"], true),
        FuzzyMatch(["const", "MENUINFO"], true),
        FuzzyMatch(["const", "MENUITEMINFOA"], true),
        FuzzyMatch(["const", "MENUITEMINFOW"], true),
        FuzzyMatch(["const", "SCROLLINFO"], true),
        FuzzyMatch(["const", "GESTUREINFO"], true),
        FuzzyMatch(["const", "WINDOW_ACTION"], true),
        FuzzyMatch(["const", "LPCWSTR"], true),

        FuzzyMatch(["volatile", "BOOLEAN"], true),
        FuzzyMatch(["volatile", "BYTE"], true),
        FuzzyMatch(["volatile", "CHAR"], true),
        FuzzyMatch(["volatile", "char"], true),
        FuzzyMatch(["volatile", "SHORT"], true),
        FuzzyMatch(["volatile", "WORD"], true),
        FuzzyMatch(["volatile", "DWORD"], true),
        FuzzyMatch(["volatile", "DWORD64"], true),
        FuzzyMatch(["volatile", "INT32"], true),
        FuzzyMatch(["volatile", "UINT32"], true),
        FuzzyMatch(["volatile", "LONG"], true),
        FuzzyMatch(["volatile", "LONG64"], true),
        FuzzyMatch(["volatile", "PVOID"], true),

        FuzzyMatch(["__int32", "PVOID"], true),

        FuzzyMatch(["__unaligned", "struct", "tagMETARECORD"], true),
        FuzzyMatch(["__unaligned", "struct", "tagMETAHEADER"], true),

        FuzzyMatch(["__unaligned", "void"], true),
        FuzzyMatch(["__unaligned", "WCHAR"], true),
        FuzzyMatch(["__unaligned", "UCSCHAR"], true),
        FuzzyMatch(["__unaligned", "IMAGE_SYMBOL"], true),
        FuzzyMatch(["__unaligned", "IMAGE_SYMBOL_EX"], true),
        FuzzyMatch(["__unaligned", "IMAGE_AUX_SYMBOL_TOKEN_DEF"], true),
        FuzzyMatch(["__unaligned", "IMAGE_AUX_SYMBOL"], true),
        FuzzyMatch(["__unaligned", "IMAGE_AUX_SYMBOL_EX"], true),
        FuzzyMatch(["__unaligned", "IMAGE_RELOCATION"], true),
        FuzzyMatch(["__unaligned", "IMAGE_LINENUMBER"], true),
        FuzzyMatch(["__unaligned", "IMAGE_BASE_RELOCATION"], true),
        FuzzyMatch(["__unaligned", "IMAGE_IMPORT_DESCRIPTOR"], true),
        FuzzyMatch(["__unaligned", "IMAGE_PROLOGUE_DYNAMIC_RELOCATION_HEADER"], true),
        FuzzyMatch(["__unaligned", "IMAGE_EPILOGUE_DYNAMIC_RELOCATION_HEADER"], true),
        FuzzyMatch(["__unaligned", "IMAGE_IMPORT_CONTROL_TRANSFER_DYNAMIC_RELOCATION"], true),
        FuzzyMatch(["__unaligned", "IMAGE_IMPORT_CONTROL_TRANSFER_ARM64_RELOCATION"], true),
        FuzzyMatch(["__unaligned", "IMAGE_INDIR_CONTROL_TRANSFER_DYNAMIC_RELOCATION"], true),
        FuzzyMatch(["__unaligned", "IMAGE_SWITCHTABLE_BRANCH_DYNAMIC_RELOCATION"], true),
        FuzzyMatch(["__unaligned", "IMAGE_FUNCTION_OVERRIDE_HEADER"], true),

        
    ];

    static string[][string] SPECIALS = [
        // __declspec(deprecated)
        "<declspec-deprecated>": [
            "__declspec", "(", "deprecated", ")"
        ],
        // __declspec(deprecated(<string>))
        "<declspec-deprecated-1>": [
            "__declspec", "(", "deprecated", "(",
            "<string>",
            ")", ")"
        ],
        // __declspec(deprecated(<string> <string> <string> <string>))
        "<declspec-deprecated-4>": [
            "__declspec", "(", "deprecated", "(",
            "<string>",
            "<string>",
            "<string>",
            "<string>",
            ")", ")"
        ],
        // __declspec(align(<any>))
        "<declspec-align>": [
            "__declspec", "(", "align", "(", "<any>", ")", ")"
        ],
        // __pragma(warning(push))
        "<pragma-warning-push>": [
            "__pragma", "(", "warning", "(", "push", ")", ")"
        ],
        // __pragma(warning(disable:<any>))
        "<pragma-warning-disable-1>": [
            "__pragma", "(", "warning", "(", "disable", ":", "<any>", ")", ")"
        ],
        // __declspec(no_init_all)
        "<declspec-no-init-all>": [
            "__declspec", "(", "no_init_all", ")",
        ],
        // __pragma(warning(pop))
        "<pragma-warning-pop>": [
            "__pragma", "(", "warning", "(", "pop", ")", ")"
        ],
        // __declspec(noinline)
        "<declspec-noinline>": [
            "__declspec", "(", "noinline", ")",
        ],
        //__declspec(dllimport)
        "<declspec-dllimport>": [
            "__declspec", "(", "dllimport", ")",
        ],
        //__declspec(noreturn)
        "<declspec-noreturn>": [
            "__declspec", "(", "noreturn", ")",
        ],
        //__declspec(dllexport)
        "<declspec-dllexport>": [
            "__declspec", "(", "dllexport", ")",
        ],
    ];

    this(string[] values, bool anyOrder) {
        this(values, values, anyOrder);
    }
    this(string[] expValues, string[] genValues, bool anyOrder) {
        this.expValues = expValues;
        this.genValues = genValues;
        this.anyOrder = anyOrder;
    }

    Tuple!(bool, int, int) 
    isMatch(CompareRelaxed comparer) {
        if(anyOrder) {
            return matchesAnyOrder(comparer);
        }
        return matchesInOrder(comparer);
    }

    Tuple!(bool, int, int)
    matchesInOrder(CompareRelaxed comparer) {
        bool m = comparer.expMatches(expValues) && 
                 comparer.genMatches(genValues);
        return tuple(
            m, 
            expValues.length.as!int, 
            genValues.length.as!int);
    }

    Tuple!(bool, int, int) 
    matchesAnyOrder(CompareRelaxed comparer) {

        // bool dbg = comparer.peekExpectedLine() == 13418;
        enum dbg = false;

        int inner(string delegate(int, bool) peek, string[] values) {
            int i = 0;
            bool[] seen = new bool[values.length];
            int numSeen;
            lp: while(numSeen < values.length) {

                if(dbg) writefln("-> [%s] %s", i, peek(i, false));

                lp2: foreach(v; 0 .. values.length) {
                    if(seen[v]) continue;   

                    if(auto special = values[v] in SPECIALS) {
                        int j = i;
                        foreach(s; *special) {
                            if(s == "<any>") { j++; continue; }
                            if(peek(j++, true) != s) continue lp2;
                        }
                        seen[v] = true;
                        numSeen++;
                        i = j;
                        continue lp;
                    }
                    else if(values[v][0]=='<') {
                        assert(false, "probable typo: %s".format(values[v]));
                    }
                    else if(values[v] == peek(i, false)) {
                        seen[v] = true;
                        numSeen++;
                        i++;
                        continue lp;
                    }
                }
                return 0;
            }
            return seen.all!(it => it == true) ? i : 0;
        }

        int expLength = inner(&comparer.peekExpected, expValues);
        if(expLength == 0) return tuple(false, 0, 0);

        int genLength = inner(&comparer.peekGenerated, genValues);
        if(genLength == 0) return tuple(false, 0, 0);

        return tuple(true, expLength, genLength);
    }
}

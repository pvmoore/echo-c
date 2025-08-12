module ec.parse.StorageClass;

import ec.all;

/**
 * https://learn.microsoft.com/en-us/cpp/c-language/c-storage-classes?view=msvc-170
 */

struct StorageClass {
    bool isExtern;
    bool isStatic;
    bool inline;
    bool forceInline;
    bool __declspec_noreturn;
    bool __declspec_dllimport;
    bool __declspec_dllexport;
    bool __declspec_noinline;
    bool __declspec_deprecated;
    bool __declspec_allocator;
    bool __declspec_restrict;

    string[] deprecationMsg;
    
    string toString() {
        string s;
        if(isExtern) s ~= "extern ";
        if(isStatic) s ~= "static ";
        if(inline) s ~= "inline ";
        if(forceInline) s ~= "__forceinline ";
        if(__declspec_noreturn) s ~= "__declspec(noreturn) ";
        if(__declspec_dllimport) s ~= "__declspec(dllimport) ";
        if(__declspec_dllexport) s ~= "__declspec(dllexport) ";
        if(__declspec_noinline) s ~= "__declspec(noinline) ";
        if(__declspec_deprecated) s ~= "__declspec(deprecated%s)\n".format(deprecationMsg.length > 0 ? "(%s)".format(deprecationMsg.join(" ")) : "");
        if(__declspec_allocator) s ~= "__declspec(allocator) ";
        if(__declspec_restrict) s ~= "__declspec(restrict) ";
        return s;
    }
}

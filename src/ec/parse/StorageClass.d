module ec.parse.StorageClass;

import ec.all;

/**
 * https://learn.microsoft.com/en-us/cpp/c-language/c-storage-classes?view=msvc-170
 */

struct StorageClass {
    bool isExtern;
    bool isStatic;
    bool inline;                // function only
    bool forceInline;           // function only

    Declspec[] declspecs;

    string toString() {
        string s;
        if(isExtern) s ~= "extern ";
        if(isStatic) s ~= "static ";
        if(inline) s ~= "__inline ";
        if(forceInline) s ~= "__forceinline ";
        foreach(d; declspecs) {
            s ~= "%s ".format(d.toString());
        }
        return s;
    }
}

StorageClass parseStorageClass(Tokens tokens, StorageClass sc) {
    while(true) {
        switch(tokens.text()) {
            case "extern": sc.isExtern = true; tokens.next(); break;
            case "static": sc.isStatic = true; tokens.next(); break;
            case "inline": 
            case "__inline": sc.inline = true; tokens.next(); break;
            case "__forceinline": sc.forceInline = true; tokens.next(); break;
            case "__declspec": sc.declspecs ~= parseDeclspecs(tokens); break;
            default: return sc;
        }
    }
    assert(false);
} 

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

StorageClass parseStorageClass(Tokens tokens, StorageClass storageClass) {
    while(true) {
        if(tokens.matches("extern")) {
            storageClass.isExtern = true;
            tokens.next();
        } else if(tokens.matches("static")) {
            storageClass.isStatic = true;
            tokens.next();
        } else if(tokens.matches("__inline") || tokens.matches("inline")) {
            storageClass.inline = true;
            tokens.next();
        } else if(tokens.matches("__forceinline")) {
            storageClass.forceInline = true;
            tokens.next();
        } else if(tokens.matches("__declspec")) {
            storageClass.declspecs ~= parseDeclspecs(tokens);
        } else {
            break;
        }
    }
    return storageClass;
}

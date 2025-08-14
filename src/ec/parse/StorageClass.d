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
    bool __declspec_noreturn;   // function only
    bool __declspec_noinline;   // function only
    bool __declspec_restrict;   // function only (returning a pointer type)
    bool __declspec_allocator;  // function only

    // Applicable to types. May also appear as a TypeModifier
    bool __declspec_dllimport;
    bool __declspec_dllexport;
    bool __declspec_deprecated;
    bool __declspec_align;

    string[] deprecationValue;
    uint alignValue;            // set if __declspec_align is true
    
    string toString() {
        string s;
        if(isExtern) s ~= "extern ";
        if(isStatic) s ~= "static ";
        if(inline) s ~= "__inline ";
        if(forceInline) s ~= "__forceinline ";
        if(__declspec_noreturn) s ~= "__declspec(noreturn) ";
        if(__declspec_dllimport) s ~= "__declspec(dllimport) ";
        if(__declspec_dllexport) s ~= "__declspec(dllexport) ";
        if(__declspec_noinline) s ~= "__declspec(noinline) ";
        if(__declspec_deprecated) s ~= "__declspec(deprecated%s)\n".format(deprecationValue.length > 0 ? "(%s)".format(deprecationValue.join(" ")) : "");
        if(__declspec_allocator) s ~= "__declspec(allocator) ";
        if(__declspec_restrict) s ~= "__declspec(restrict) ";
        if(__declspec_align) s ~= "__declspec(align(%s)) ".format(alignValue);
        return s;
    }
}

StorageClass parseStorageClass(Tokens tokens) {
    StorageClass storageClass;
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
            tokens.next();
            tokens.skip(TKind.LPAREN);

            if(tokens.matches("noreturn")) {
                tokens.skip("noreturn");
                storageClass.__declspec_noreturn = true;
            } else if(tokens.matches("dllimport")) {
                tokens.skip("dllimport");
                storageClass.__declspec_dllimport = true;
            } else if(tokens.matches("dllexport")) {
                tokens.skip("dllexport");
                storageClass.__declspec_dllexport = true;
            } else if(tokens.matches("noinline")) {
                tokens.skip("noinline");
                storageClass.__declspec_noinline = true;
            } else if(tokens.matches("deprecated")) {
                tokens.skip("deprecated");
                storageClass.__declspec_deprecated = true;
                if(tokens.matches(TKind.LPAREN)) {
                    tokens.skip(TKind.LPAREN);
                    while(!tokens.matches(TKind.RPAREN)) {
                        storageClass.deprecationValue ~= tokens.text(); 
                        tokens.next();
                    }
                    tokens.skip(TKind.RPAREN);
                }
            } else if(tokens.matches("allocator")) {
                tokens.skip("allocator");
                storageClass.__declspec_allocator = true;
            } else if(tokens.matches("restrict")) {
                tokens.skip("restrict");
                storageClass.__declspec_restrict = true;   
            } else if(tokens.matches("align")) {
                tokens.skip("align");
                tokens.skip(TKind.LPAREN);
                storageClass.alignValue = tokens.textToInt(); tokens.next();
                tokens.skip(TKind.RPAREN);
                storageClass.__declspec_align = true; 
            } else {
                todo("unsupported __declspec %s".format(tokens.text()));
            }
            tokens.skip(TKind.RPAREN);
        } else {
            break;
        }
    }
    return storageClass;
}

module ec.parse.DeclspecParser;

import ec.all;

struct Declspec {
    enum Kind {
        ALIGN,
        ALLOCATOR,
        DEPRECATED,
        DLLEXPORT,
        DLLIMPORT,
        NO_INIT_ALL,
        NOINLINE,
        NORETURN,
        RESTRICT,
    }
    Kind kind;
    union {
        uint alignment;
        string[] deprecations;
    }
    string toString() {
        final switch(kind) with(Kind) {
            case ALIGN: return "__declspec(align(%s))".format(alignment);
            case ALLOCATOR: return "__declspec(allocator)";
            case DEPRECATED: return "__declspec(deprecated%s)".format(deprecations.length > 0 ? "(%s)".format(deprecations.join(" ")) : "");
            case DLLEXPORT: return "__declspec(dllexport)";
            case DLLIMPORT: return "__declspec(dllimport)";
            case NO_INIT_ALL: return "__declspec(no_init_all)";
            case NOINLINE: return "__declspec(noinline)";
            case NORETURN: return "__declspec(noreturn)";
            case RESTRICT: return "__declspec(restrict)";
        }
    }
}

Declspec[] parseDeclspecs(Tokens tokens) {
    Declspec[] specs;
    while(tokens.matches("__declspec")) {
        Declspec d;
        tokens.skip("__declspec");
        tokens.skip(TKind.LPAREN);

        if(tokens.matches("align")) {
            tokens.skip("align");
            d.kind = Declspec.Kind.ALIGN;
            tokens.skip(TKind.LPAREN);
            d.alignment = tokens.textToInt(); tokens.next();
            tokens.skip(TKind.RPAREN);
        } else if(tokens.matches("allocator")) {
            tokens.skip("allocator");
            d.kind = Declspec.Kind.ALLOCATOR;
        } else if(tokens.matches("deprecated")) {
            tokens.skip("deprecated");
            d.kind = Declspec.Kind.DEPRECATED;
            if(tokens.matches(TKind.LPAREN)) {
                tokens.skip(TKind.LPAREN);
                while(!tokens.matches(TKind.RPAREN)) {
                    d.deprecations ~= tokens.text(); 
                    tokens.next();
                }
                tokens.skip(TKind.RPAREN);
            }
        } else if(tokens.matches("dllexport")) {
            tokens.skip("dllexport");
            d.kind = Declspec.Kind.DLLEXPORT;    
        } else if(tokens.matches("dllimport")) {
            tokens.skip("dllimport");
            d.kind = Declspec.Kind.DLLIMPORT;  
        } else if(tokens.matches("no_init_all")) {
            tokens.skip("no_init_all");
            d.kind = Declspec.Kind.NO_INIT_ALL;
        } else if(tokens.matches("noinline")) {
            tokens.skip("noinline");
            d.kind = Declspec.Kind.NOINLINE;
        } else if(tokens.matches("noreturn")) {
            tokens.skip("noreturn");
            d.kind = Declspec.Kind.NORETURN;
        } else if(tokens.matches("restrict")) {
            tokens.skip("restrict");
            d.kind = Declspec.Kind.RESTRICT;
        } else {
            todo("unsupported __declspec %s".format(tokens.token()));
        }
        tokens.skip(TKind.RPAREN);
        specs ~= d;
    }
    return specs;
}

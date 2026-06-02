module ec.parse.TypeModifiers;

import ec.all;

struct TypeModifiers {
    bool isConst;  
    bool isSigned;
    bool isUnsigned;
    bool isVolatile;
    bool isUnaligned; // __unaligned (ms specific). I think the technically has no effect before the *
                      // but I have seen it used so here it is

    // These also appear as StorageClasses 
    bool __declspec_dllimport;
    bool __declspec_dllexport;
    bool __declspec_align;   
    bool __declspec_no_init_all;   
    Pragma[] pragmas;           // 0..many __pragma declarations          

    uint alignValue;            // set if __declspec_align is true   

    struct Deprecation {
        string[] values;
    }
    Deprecation[] deprecations;

    bool any() {
        return isConst || isSigned || isUnsigned || isVolatile || isUnaligned ||
               __declspec_dllimport || __declspec_dllexport || __declspec_align || 
               __declspec_no_init_all || 
               pragmas.length > 0 ||
               deprecations.length > 0;
    }

    void mergeFrom(TypeModifiers other) {
        isConst |= other.isConst;
        isSigned |= other.isSigned;
        isUnsigned |= other.isUnsigned;
        isVolatile |= other.isVolatile;
        isUnaligned |= other.isUnaligned;
        __declspec_dllimport |= other.__declspec_dllimport;
        __declspec_dllexport |= other.__declspec_dllexport;
        __declspec_align |= other.__declspec_align;
        __declspec_no_init_all |= other.__declspec_no_init_all;

        alignValue |= other.alignValue; 
        deprecations ~= other.deprecations;
        pragmas ~= other.pragmas;
    }

    string toString() {
        string s;
        if(isConst) s ~= "const ";
        if(isSigned) s ~= "signed ";
        if(isUnsigned) s ~= "unsigned ";
        if(isVolatile) s ~= "volatile ";
        if(isUnaligned) s ~= "__unaligned ";
        if(__declspec_dllimport) s ~= "__declspec(dllimport) ";
        if(__declspec_dllexport) s ~= "__declspec(dllexport) ";
        if(__declspec_align) s ~= "__declspec(align(%s)) ".format(alignValue);
        if(__declspec_no_init_all) s ~= "__declspec(no_init_all) ";
        
        foreach(d; deprecations) {
            s ~= "__declspec(deprecated%s)\n".format(d.values.length > 0 ? "(%s)".format(d.values.join(" ")) : "");
        }
        foreach(p; pragmas) {
            s ~= "%s ".format(p.toString());
        }
        return s;
    }
}

TypeModifiers parseModifiers(Tokens tokens) {
    TypeModifiers q;

    while(true) {
        switch(tokens.text()) {
            case "const": q.isConst = true; tokens.next(); break;
            case "signed": q.isSigned = true; tokens.next(); break;
            case "unsigned": q.isUnsigned = true; tokens.next(); break;
            case "volatile": q.isVolatile = true; tokens.next(); break;
            case "_unaligned":
            case "__unaligned": q.isUnaligned = true; tokens.next(); break;
            case "__declspec": 
                parseDeclspec(tokens, q); 
                break;
            case "__pragma":
                q.pragmas ~= parseAndReturnPragma(tokens); 
                break;
            default: return q;
        }
    }
    assert(false);
}

private:

void parseDeclspec(Tokens tokens, ref TypeModifiers q) {
    tokens.skip("__declspec");
    tokens.skip(TKind.LPAREN);

    if(tokens.matches("dllimport")) {
        tokens.skip("dllimport");
        q.__declspec_dllimport = true;
    } else if(tokens.matches("dllexport")) {
        tokens.skip("dllexport");
        q.__declspec_dllexport = true;
    } else if(tokens.matches("deprecated")) {
        tokens.skip("deprecated");
        TypeModifiers.Deprecation d;
        if(tokens.matches(TKind.LPAREN)) {
            tokens.skip(TKind.LPAREN);
            while(!tokens.matches(TKind.RPAREN)) {
                d.values ~= tokens.text(); 
                tokens.next();
            }
            tokens.skip(TKind.RPAREN);
        }  
        q.deprecations ~= d;
    } else if(tokens.matches("align")) {
        tokens.skip("align");
        tokens.skip(TKind.LPAREN);
        q.alignValue = tokens.textToInt(); tokens.next();
        tokens.skip(TKind.RPAREN);
        q.__declspec_align = true; 
    } else if(tokens.matches("no_init_all")) {
        tokens.skip("no_init_all");
        q.__declspec_no_init_all = true;
    } else {
        todo("unsupported __declspec %s".format(tokens.token()));
    }
    tokens.skip(TKind.RPAREN);
}

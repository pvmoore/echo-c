module ec.parse.TypeModifiers;

import ec.all;

struct TypeModifiers {
    bool isConst;  
    bool isSigned;
    bool isUnsigned;
    bool isVolatile;
    bool isUnaligned; // __unaligned (ms specific). I think the technically has no effect before the *
                      // but I have seen it used so here it is

    Declspec[] declspecs;
    Pragma[] pragmas;                     

    bool any() {
        return isConst || isSigned || isUnsigned || isVolatile || isUnaligned ||
               declspecs.length > 0 ||
               pragmas.length > 0;
    }

    void mergeFrom(TypeModifiers other) {
        isConst |= other.isConst;
        isSigned |= other.isSigned;
        isUnsigned |= other.isUnsigned;
        isVolatile |= other.isVolatile;
        isUnaligned |= other.isUnaligned;

        declspecs ~= other.declspecs;
        pragmas ~= other.pragmas;
    }

    string toString() {
        string s;
        if(isConst) s ~= "const ";
        if(isSigned) s ~= "signed ";
        if(isUnsigned) s ~= "unsigned ";
        if(isVolatile) s ~= "volatile ";
        if(isUnaligned) s ~= "__unaligned ";
        
        foreach(d; declspecs) {
            s ~= "%s ".format(d.toString());
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
                q.declspecs ~= parseDeclspecs(tokens); 
                break;
            case "__pragma":
                q.pragmas ~= parseAndReturnPragma(tokens); 
                break;
            default: return q;
        }
    }
    assert(false);
}


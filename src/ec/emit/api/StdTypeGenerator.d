module ec.emit.api.StdTypeGenerator;

import ec.all;

final class StdTypeGenerator : ITypeGenerator {
public:
    this(APIEmitter emitter) {
        this.base = emitter;
    }
    ReturnType doGenerate(Type t, APIEmitter base) {
        string result;
        if(auto tr = t.as!TypeRef) {
            result = this.doGenerate(tr);
        } else {
            switch(t.etype) {
                case EType.VOID:..case EType.VARARG: result = this.doGenerate(t.as!SimpleType); break;
                case EType.ARRAY: result = this.doGenerate(t.as!ArrayType); break;
                case EType.FUNCTION_PTR: result = this.doGenerate(t.as!FunctionPtr); break;

                default: assert(false, "Handle type %s".format(t.etype));
            }
        }
        return ReturnType(true, result);
    }
private:
    APIEmitter base;

    string doGenerate(ArrayType at) {
        string s = base.gen(at.elementType());

        // Multidimensional arrays are reversed
        foreach_reverse(d; at.dimensionExprs()) {
            s ~= "[";
            auto num = d.as!Number;
            if(num && "-1" == num.stringValue) {
                // this is an empty dimension
            } else {
                s ~= base.gen(d);
            }
            s ~= "]";
        }

        if(at.varName) s ~= " %s".format(base.dname(at.varName));

        return s;
    }
    string doGenerate(FunctionPtr fp) {
        string cc;

        bool noCC = base.state == APIEmitter.State.GLOBALS;

        if(!noCC) {
            cc = "extern(C) ";
            if(fp.callingConvention == CallingConvention.STDCALL) {
                cc = "extern(Windows) ";
            }
        }

        auto paramString = fp.params.map!(it=>base.gen(it)).join(", ");
        auto returnTypeString = base.gen(fp.returnType);
        auto suffix = " nothrow";
        if(fp.varName && base.state != APIEmitter.State.ALIASES) {
            suffix ~= " %s".format(base.dname(fp.varName));
        }

        return "%s%s function(%s)%s".format(cc, returnTypeString, paramString, suffix);
    }
    string doGenerate(SimpleType st) {

        string p = "*".repeat(st.ptrDepth());
        string s = base.stringOf(st);

        if(st.etype == EType.CHAR) {
            if(st.modifiers.isUnsigned) {
                s = "ubyte";
            } else if(st.isPtr()) {
                s = "immutable(char)";
            }
        }

        return "%s%s".format(s, p);
    }
    string doGenerate(TypeRef tr) {
        if(tr.nodeRef) {
            return base.gen(tr.nodeRef);
        } else {
            string modifiers = ""; // tr.modifiers.isUnsigned ? "unsigned " : "";
            return "%s%s%s".format(modifiers, tr.name, "*".repeat(tr.ptrDepth()));
        }
    }
}

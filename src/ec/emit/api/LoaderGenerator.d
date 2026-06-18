module ec.emit.api.LoaderGenerator;

import core.sys.windows.windows;
import common : StringBuffer;

class AbsLoaderGenerator {
protected:
    string[] functionNames;
public:
    void setFunctionNames(string[] names...) {
        this.functionNames = names;
    }
    string doGenerate() {
        auto buf = new StringBuffer();
        emitProlog(buf);
        emitFunctions(buf, functionNames);
        emitEpilog(buf);
        return buf.toString();
    }
    abstract void emitProlog(StringBuffer buf);
    abstract void emitFunctions(StringBuffer buf, string[] functionNames);
    abstract void emitEpilog(StringBuffer buf);
}

//──────────────────────────────────────────────────────────────────────────────────────────────────

class DLLLoaderGenerator : AbsLoaderGenerator {
protected:
    string className;
    string libraryName;
    string debugLibraryName;
public:
    this(string className, string libraryName, string debugLibraryName) {
        this.className = className;
        this.libraryName = libraryName;
        this.debugLibraryName = debugLibraryName;
    }
    override void emitProlog(StringBuffer buf) {
        buf.add("// %s\n", className);
        buf.add("private struct _%s {\n", className);
        buf.add("\timport core.sys.windows.windows;\n");
        buf.add("\tHANDLE handle;\n");
        buf.add("\tbool load() {\n");

        if(debugLibraryName) {
            buf.add("\t\tdebug {\n");
            buf.add("\t\t\tthis.handle = LoadLibraryA(\"%s\");\n", debugLibraryName);
            buf.add("\t\t} else {\n");
            buf.add("\t\t\tthis.handle = LoadLibraryA(\"%s\");\n", libraryName);
            buf.add("\t\t}\n");
        } else {
            buf.add("\t\tthis.handle = LoadLibraryA(\"%s\");\n", libraryName);
        }

        buf.add("\t\tif(!handle) return false;\n");
        
        buf.add("\t\t\n");
    }
    override void emitFunctions(StringBuffer buf, string[] functionNames) {
        foreach(n; functionNames) {
            buf.add("\t\t*(cast(void**)&%s) = GetProcAddress(handle, \"%s\");", n,n);
            buf.add(" assert(%s);\n", n);
        }
    }
    override void emitEpilog(StringBuffer buf) {
        buf.add("\t\treturn true;\n");
        buf.add("\t}\n");
        buf.add("\tvoid unload() {\n");
        buf.add("\t\tif(handle) FreeLibrary(handle);\n");
        buf.add("\t}\n");
        buf.add("}\n");
        buf.add("__gshared _%s %s;\n", className, className);
        buf.add("// End of %s\n\n", className);
    }
}

module ec.misc.logging;

import ec.all;
import std.stdio : writeln, writefln;

enum Log {
    General,
    StmtParser,
    ExprParser,
    TypeParser,
    StmtGenerator,
    Preprocessor,
}
private static bool[Log] enabledLogs = [
    Log.General       : false,
    Log.StmtParser    : false,
    Log.ExprParser    : false,
    Log.TypeParser    : false,
    Log.StmtGenerator : false,
    Log.Preprocessor  : false
];

void log(A...)(Log src, string fmt, A args) {
    if(auto ptr = src in enabledLogs) {
        if(*ptr) log(format(fmt, args));
    } 
}

void logError(A...)(string fmt, A args) {
    string msg = format(fmt, args);
    writefln("[%s] %s", ansiWrap("ERROR", Ansi.RED), msg);
}

private:

void log(string msg) {
    writeln(msg);
}

void log(A...)(string fmt, A args) {
    log(format(fmt, args));
}

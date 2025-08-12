module ec.misc.logging;

import ec.all;

import std.stdio : writeln, writefln;

void log(string msg) {
    writeln(msg);
}

void log(A...)(string fmt, A args) {
    log(format(fmt, args));
}

void logError(A...)(string fmt, A args) {
    string msg = format(fmt, args);
    writefln("[%s] %s", ansiWrap("ERROR", Ansi.RED), msg);
}

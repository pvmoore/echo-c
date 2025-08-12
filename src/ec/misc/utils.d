module ec.misc.utils;

import ec.all;

bool isDigit(char c) {
    return c >= '0' && c <= '9';
}

string toCanonicalDirectory(string path) {
    import std.file;
    import std.path;
    import std.array : replace;

    if(path is null) return "./";

    string norm = buildNormalizedPath(path).replace('\\', '/');
    if(norm[$-1] != '/') norm ~= '/';
    return norm;
}

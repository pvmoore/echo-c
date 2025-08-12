module ec.parse.SyntaxError;

import ec.all;

void syntaxError(CFile cfile, Token t, string msg) {
    syntaxError(cfile.filename, t.line, t.column, msg);
}

void syntaxError(Tokens tokens, string msg) {
    syntaxError(tokens.cfile.filename, tokens.token().line, tokens.token().column, msg);
}

void syntaxError(string relativeFilename, int line, int column, string msg) {
    logError("Syntax error in %s at %s:%s: %s", relativeFilename, line, column, msg);
    throw new Exception(msg);
}

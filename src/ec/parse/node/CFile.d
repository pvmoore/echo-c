module ec.parse.node.CFile;

import ec.all;

final class CFile : Node {
public:
    Config config;
    string filename;
    Token[] tokens;
    Typedef[string] typedefs;

    this(Config config, string filename, Token[] tokens) {
        this.config = config;
        this.filename = filename;
        this.tokens = tokens;
    }

    /**
     * Optimisation to make it quicker to lookup typedefs.
     */
    void registerTypedef(Typedef td) {
        log("registering Typedef %s", td.name);
        typedefs[td.name] = td;
    }

    override string toString() {
        return "CFile(%s)".format(filename);
    }
}

module ec.EC;

import ec.all;

final class EC {
public:
    this(Config config) {
        this.config = config;
        this.config.check();

        log(Log.General, "EC created with config: %s", this.config.toString());
    }
    void addCFile(string filename) {

        if(cfiles.containsKey(filename)) {
            return;
        }

        string fullPath = config.sourceDirectory ~ filename;
        if(!exists(fullPath)) {
            throw new Exception("File does not exist: " ~ fullPath);
        }
        if(!isFile(fullPath)) {
            throw new Exception("Not a file: " ~ fullPath);
        }
        
        auto preprocessor = new Preprocessor(config);
        string ppOutput = preprocessor.process(filename);

        Lexer lexer = new Lexer(filename, ppOutput);
        Token[] tokens = lexer.tokenise();

        if(tokens.length < 100) {
            log(Log.General, tokens.toString());
        } else {
            log(Log.General, tokens[0..100].toString());
        }

        CFile cfile = new CFile(config, filename, tokens);
        cfiles[filename] = cfile;

        parseCFile(cfile);

        enum WRITE_AST = false;
        static if(WRITE_AST) {
            import std.file : write;
            string dumped = cfile.dumpToString();
            write(config.targetDirectory ~ filename ~ ".ast", dumped);
        }
    }
    /**
     * Resolve any ambiguous AST nodes.
     */
    void resolve() {
        log(Log.General, "Resolving");
        Node[] unresolved;
        void recurse(Node n) {
            if(!n.isResolved()) {
                unresolved ~= n;
            }
            foreach(ch; n.children) {
                recurse(ch);
            }
        }
        foreach(cfile; cfiles.values) {
            recurse(cfile);
        }
        if(unresolved.length > 0) {
            logError("Unresolved nodes found: %s", unresolved.length);
            foreach(i, u; unresolved) {
                log(Log.General, "[%s] - %s", i, u);

                todo("resolve this node");
            }
        }
    }
    void generate() {
        log(Log.General, "Generating to [%s]", config.targetDirectory);
        foreach(cfile; cfiles.values) {
            StmtGenerator gen = new StmtGenerator();
            gen.generate(cfile);
        }
    }
private:
    Config config;
    CFile[string] cfiles;
}

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

        enum WRITE_TOKENS = true;
        static if(WRITE_TOKENS) {
            import std.file : write;
            string t;
            foreach(token; tokens) {
                t ~= token.toString() ~ "\n";
            }
            write(config.targetDirectory ~ filename ~ ".tokens", t);
        }

        CFile cfile = new CFile(config, filename, tokens);
        cfiles[filename] = cfile;

        parseCFile(cfile);

        enum WRITE_AST = true;
        static if(WRITE_AST) {
            import std.file : write;
            string dumped = cfile.dumpToString();
            write(config.targetDirectory ~ filename ~ ".ast", dumped);
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

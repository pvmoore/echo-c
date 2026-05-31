module ec.preprocess.Preprocessor;

import ec.all;

final class Preprocessor {
public:
    enum {
        CL      = 1,
        CLANG   = 2,
        ALL     = CL | CLANG
    }
    enum processors = CL | 0;
    enum primary    = CL;

    shared static ulong totalTimeCl;
    shared static ulong totalTimeClang;

    this(Config conf) {
        this.config = conf;
    }
    string process(string filename) {
        string output;

        if(processors & CL) {
            string clOutput = processUsingMicrosoftCL(filename);
            if(!output) output = clOutput;
        }
        if(processors & CLANG) {
            string clangOutput = processUsingClang(filename);
            if(!output) output = clangOutput;
        }

        if(config.writePreprocessedFiles) {
            writeOutput(filename, "", output);
        }

        return output;
    }

    /**
     * Call Microsoft CL compiler to preprocess a file.
     */
    string processUsingMicrosoftCL(string filename) {
        StopWatch watch;
        watch.start();

        string srcFilename = config.sourceDirectory ~ filename;

        auto args = [
            "cl.exe",
            //"/P",
            "/E",
            "/std:c17",
            "/nologo",
            //"/Fi%s".format(outFilename),
            //"/I" ~ config.sourceDirectory,
        ];

        foreach(d; config.includeDirectories) {
            args ~= "/I" ~ d;
        }

        args ~= srcFilename;

        log(Log.Preprocessor,  "executing preprocessor on file %s: %s", filename, args.join(" "));

        import std.process : execute, Config;

        auto result = execute(
            args,
            null,   // env
            Config.suppressConsole
        );

        string output = result.output.strip();

        throwIf(result.status != 0, "Preprocessor failed %s", output);

        // Throw away the first line which contains the original filename for some reason
        auto eol = output.indexOf("\n");
        output = output[eol+1..$];

        // Remove empty lines
        output = output.splitLines()
            .filter!(line => line.strip().length > 0)
            .join("\n");

        if(config.writePreprocessedFiles) {
            writeOutput(filename, ".cl", output);
        }

        watch.stop();
        atomicOp!"+="(totalTimeCl, watch.peek().total!"nsecs");
        return output;
    }
    /**
     * Call Clang compiler to preprocess a file.
     */
    string processUsingClang(string filename) {
        StopWatch watch;
        watch.start();

        string srcFilename = config.sourceDirectory ~ filename;

        auto args = [
            "clang.exe",
            "-E",
            "-fuse-line-directives",    // add #line directives
            "-std=c17",
        ];

        foreach(d; config.includeDirectories) {
            args ~= "-I" ~ d;
        }

        args ~= srcFilename;

        log(Log.Preprocessor,  "executing preprocessor on file %s: %s", filename, args.join(" "));

        import std.process : execute, Config;

        auto result = execute(
            args,
            null,   // env
            Config.suppressConsole
        );

        string output = result.output.strip();

        throwIf(result.status != 0, "Preprocessor failed %s", output);

        // Remove these: 
        //   Empty lines
        //   #line 1 "<command line>"
        //   #line 1 "<built-in>"
        output = output.splitLines()
            .filter!((line) { 
                string l = line.strip();
                if(l.startsWith("#line")) {
                    if(l.contains("<command line>")) return false;
                    if(l.contains("<built-in>")) return false;
                }
                return l.length > 0; 
            })
            .join("\n");

        if(config.writePreprocessedFiles) {
            writeOutput(filename, ".clang", output);
        }

        watch.stop();
        atomicOp!"+="(totalTimeClang, watch.peek().total!"nsecs");
        return output;
    }
private:
    Config config;

    void writeOutput(string filename, string postfix, string output) {
        import std.file : write;

        string ppFilename = config.targetDirectory ~ filename.stripExtension() ~ postfix ~ ".i";
        write(ppFilename, output);
    }
}

module ec.preprocess.Preprocessor;

import ec.all;

final class Preprocessor {
public:
    shared static ulong totalTimeCl;
    shared static ulong totalTimeClang;

    this(Config conf) {
        this.config = conf;
    }
    string process(string filename) {
        bool useClang = false;

        string clangOutput = processUsingClang(filename, useClang);
        string clOutput    = processUsingMicrosoftCL(filename, !useClang);

        return useClang ? clangOutput : clOutput;
    }

    /**
     * Call Microsoft CL compiler to preprocess a file.
     */
    string processUsingMicrosoftCL(string filename, bool isPrimary) {
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
            import std.file : write;
            if(isPrimary) {
                string ppFilename = config.targetDirectory ~ filename.stripExtension() ~ ".i";
                write(ppFilename, output);
            }
            {
                string ppFilename = config.targetDirectory ~ filename.stripExtension() ~ ".cl.i";
                write(ppFilename, output);
            }
        }

        watch.stop();
        atomicOp!"+="(totalTimeCl, watch.peek().total!"nsecs");
        return output;
    }
    /**
     * Call Clang compiler to preprocess a file.
     */
    string processUsingClang(string filename, bool isPrimary) {
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
            import std.file : write;
            if(isPrimary) {
                string ppFilename = config.targetDirectory ~ filename.stripExtension() ~ ".i";
                write(ppFilename, output);
            }
            {
                string ppFilename = config.targetDirectory ~ filename.stripExtension() ~ ".clang.i";
                write(ppFilename, output);
            }
        }

        watch.stop();
        atomicOp!"+="(totalTimeClang, watch.peek().total!"nsecs");
        return output;
    }
private:
    Config config;
}

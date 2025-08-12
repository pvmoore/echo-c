module ec.preprocess.Preprocessor;

import ec.all;

final class Preprocessor {
public:
    this(Config conf) {
        this.config = conf;
    }
    string process(string filename) {
        return processUsingMicrosoftCL(filename);
    }

    /**
     * Call Microsoft CL compiler.
     */
    string processUsingMicrosoftCL(string filename) {

        string srcFilename = config.sourceDirectory ~ filename;

        auto args = [
            "cl.exe",
            //"/P",
            "/E",
            "/std:clatest",
            "/nologo",
            //"/Fi%s".format(outFilename),
            //"/I" ~ config.sourceDirectory,
        ];

        foreach(d; config.includeDirectories) {
            args ~= "/I" ~ d;
        }

        args ~= srcFilename;

        log("executing preprocessor on file %s: %s", filename, args.join(" "));

        import std.process : execute, Config;

        auto result = execute(
            args,
            null,   // env
            Config.suppressConsole
        );

        string output = result.output.strip();

        throwIf(result.status != 0, "Preprocessor failed %s", output);

        // Preprocess the preprocessed output to tidy it up a bit

        // (1) Throw away the first line which contains the original filename for some reason
        auto eol = output.indexOf("\n");
        output = output[eol+1..$];

        // (2) Remove blank lines
        output = output.splitLines()
            .filter!(line => line.strip().length > 0)
            .join("\n");

        if(config.writePreprocessedFiles) {
            import std.file : write;
            string ppFilename = config.targetDirectory ~ filename.stripExtension() ~ ".i";
            write(ppFilename, output);
        }

        return output;
    }
private:
    Config config;
}

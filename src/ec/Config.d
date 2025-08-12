module ec.Config;

import ec.all;

struct Config {
    string sourceDirectory;
    string targetDirectory;
    string[] includeDirectories;

    bool writePreprocessedFiles = true;

    void check() {
        this.sourceDirectory = toCanonicalDirectory(sourceDirectory);
        this.targetDirectory = toCanonicalDirectory(targetDirectory);
        this.includeDirectories = includeDirectories.map!toCanonicalDirectory().array();

        if(!sourceDirectory.exists()) {
            throw new Exception("Source directory does not exist: " ~ sourceDirectory);
        }
        if(!sourceDirectory.isDir()) {
            throw new Exception("Source directory is not a directory: " ~ sourceDirectory);
        }
        foreach(d; includeDirectories) {
            if(!d.exists()) {
                throw new Exception("Include directory does not exist: " ~ d);
            }
            if(!d.isDir()) {
                throw new Exception("Include directory is not a directory: " ~ d);
            }
        }
        if(!targetDirectory.exists()) {
            mkdirRecurse(targetDirectory);
        }
    }

    string toString() {
        string s = "{\n";
        s ~= format("  sourceDirectory .. %s,\n" ~ 
                    "  targetDirectory .. %s\n", 
            sourceDirectory, 
            targetDirectory);

        foreach(d; includeDirectories) {
            s ~= format("  includeDirectory .. %s\n", d);
        }

        return s ~ "}";
    }
}

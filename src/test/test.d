module test.test;

import std.stdio  : writefln, writeln;
import std.format : format;
import test.test_comparer;
import ec;

void main() {
    writeln("Hello World");

    enum ONLY_RUN_TEST_SUITE = false;

    static if(ONLY_RUN_TEST_SUITE) {
        runTests();
    } else {

        // Run the tests
        runTests();

        // .. followed by the big one

        EC ec = testMiniVrt();

        ec.resolve();
        ec.generate();
    }
}

EC testMiniVrt() {
    Config conf = {
        sourceDirectory: "C:/pvmoore/d/experimental/mini_vrt/c/src/",
        targetDirectory: ".target/mini_vrt/",
        includeDirectories: [
            "C:/work/VulkanSDK/1.4.321.1/Include",
            "C:/work/glfw-3.4.bin.WIN64/include"
        ]
    };
    
    
    EC ec = new EC(conf);

    ec.addCFile("main.c");

    return ec;
}

void runTests() {
    import std.file : dirEntries, SpanMode;
    import std.path : baseName, stripExtension;

    writefln("Running tests ...");

    enum SINGLE_TEST = "";// = "test2";
    static if(SINGLE_TEST != "") {
        runTest(SINGLE_TEST);
        return;
    }

    foreach(e; dirEntries("resources/test-data/", "*.c", SpanMode.shallow)) {
        string filename = e.name.baseName().stripExtension();
        runTest(filename);
    }
}

void runTest(string filename) {
    writefln("Running test %s.c ...", filename);
    Config conf = {
        sourceDirectory: "resources/test-data/",
        targetDirectory: ".target/test-data/",
        includeDirectories: []
    };

    EC ec = new EC(conf);

    ec.addCFile(filename ~ ".c");
    ec.resolve();
    ec.generate();

    string srcFilename    = ".target/test-data/%s.i".format(filename);
    string targetFilename = ".target/test-data/%s.c".format(filename);

    auto comparer = new TestComparer();

    writefln("Comparing %s -> %s", srcFilename, targetFilename);
    if(comparer.compare(srcFilename, targetFilename)) {
        writefln("  Passed: %s", filename);
    } else {
        writefln("  Failed: %s", filename);
        throw new Exception("Test failed");
    }
}

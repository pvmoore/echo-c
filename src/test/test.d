module test.test;

import std.stdio    : writefln, writeln;
import std.format   : format;
import std.file     : dirEntries, SpanMode, exists, timeLastModified;
import std.path     : baseName, stripExtension;

import test.test_comparer;
import ec;

enum ONLY_RUN_TEST_SUITE = false;
enum SINGLE_TEST         = "";// = "test2";

void main() {

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

    writefln("Running tests ...");

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

    string srcFilename       = "resources/test-data/%s.c".format(filename);
    string expectFile        = "resources/test-data/%s.expected.h".format(filename);
    string truthFilename     = ".target/test-data/%s.i".format(filename);
    string generatedFilename = ".target/test-data/%s.c".format(filename);

    auto comparer = new TestComparer();

    // Use expect file as src
    if(expectFile.exists()) {

        auto srcTime    = timeLastModified(srcFilename);
        auto expectTime = timeLastModified(expectFile);

        if(srcTime > expectTime) {
            throw new Exception("  Expect file may be stale: %s".format(expectFile));
        }

        truthFilename = expectFile;
    }

    writefln("Comparing %s -> %s", truthFilename, generatedFilename);
    if(comparer.compare(truthFilename, generatedFilename)) {
        writefln("  Passed: %s", filename);
    } else {
        writefln("  Failed: %s", filename);
        throw new Exception("Test failed");
    }
}

module test.test;

import std.stdio    : writefln, writeln;
import std.format   : format;
import std.file     : dirEntries, SpanMode, exists, timeLastModified;
import std.path     : baseName, stripExtension;

import test.test_comparer;
import ec;

enum RUN_TEST_SUITE  = true;
enum RUN_LARGE_TESTS = true;

enum SINGLE_TEST = "";// = "test2";

void main() {

    static if(RUN_TEST_SUITE) {
        runTestSuite();
    }
    static if(RUN_LARGE_TESTS) {
        testMiniVrt();
        testWindows();
    }

    import ec.preprocess.Preprocessor;
    writefln("Preprocessor timings:");
    writefln("  clang: %.2f s", Preprocessor.totalTimeClang / 1_000_000_000.0);
    writefln("  cl:    %.2f s", Preprocessor.totalTimeCl / 1_000_000_000.0);
}
 
private: 

void testMiniVrt() {
    writefln("Testing mini_vrt ...");

    Config conf = {
        sourceDirectory: "C:/pvmoore/d/experimental/mini_vrt/c/src/",
        targetDirectory: ".target/test-mini_vrt/",
        includeDirectories: [
            "C:/work/VulkanSDK/1.4.350.0/Include",
            "C:/work/glfw-3.4.bin.WIN64/include"
        ]
    };
    
    
    EC ec = new EC(conf);

    ec.addCFile("main.c");
    ec.resolve();
    ec.generate();
    writefln("  Done");
}
void testWindows() {
    writefln("Testing Windows ...");

    Config conf = {
        sourceDirectory: "resources/large-tests/",
        targetDirectory: ".target/test-windows/",
        includeDirectories: []
    };
    
    EC ec = new EC(conf);

    ec.addCFile("test_windows.c");
    ec.resolve();
    ec.generate();
    writefln("  Done");
}

void runTestSuite() {

    writefln("Running test suite ...");

    static if(SINGLE_TEST != "") {
        runTest(SINGLE_TEST);
        return;
    }

    foreach(e; dirEntries("resources/test-suite/", "*.c", SpanMode.shallow)) {
        string filename = e.name.baseName().stripExtension();
        runTest(filename);
    }
    writefln("Test suite \u001b[32mpassed\u001b[0m");
}

void runTest(string filename) {
    writefln("[Running test %s.c]", filename);
    Config conf = {
        sourceDirectory: "resources/test-suite/",
        targetDirectory: ".target/test-suite/",
        includeDirectories: []
    };

    EC ec = new EC(conf);

    ec.addCFile(filename ~ ".c");
    ec.resolve();
    ec.generate();

    string srcFilename       = "resources/test-suite/%s.c".format(filename);
    string expectFile        = "resources/test-suite/%s.expected.h".format(filename);
    string truthFilename     = ".target/test-suite/%s.i".format(filename);
    string generatedFilename = ".target/test-suite/%s.c".format(filename);

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

    writefln("  Comparing %s -> %s", truthFilename, generatedFilename);
    if(comparer.compare(truthFilename, generatedFilename)) {
        writefln("  Passed");
    } else {
        throw new Exception("Test failed: %s".format(filename));
    }
}

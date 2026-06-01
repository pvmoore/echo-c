module test.test;

import std.stdio    : writefln, writeln;
import std.format   : format;
import std.file     : dirEntries, SpanMode, exists, timeLastModified;
import std.path     : baseName, stripExtension;
import std.process  : environment;

import test.CompareStrict;
import test.CompareRelaxed;
import ec;

enum RUN_TEST_SUITE  = true;
enum RUN_LARGE_TESTS = true;

enum SINGLE_TEST = "";// = "test2";

void main() {

    static if(RUN_TEST_SUITE) {
        runTestSuite();
    }

    // These only assert that no errors occur
    static if(RUN_LARGE_TESTS) {
        // testMiniVrt();
        largeTest("windows");
        // largeTest("stdio");
        //largeTest("stdlib");
        //largeTest("vulkan", [environment.get("VULKAN_SDK") ~ "/Include"]);

        // testCimgui();
        // testVma();
        //testKtx();
    }

    import ec.preprocess.Preprocessor;
    writefln("Preprocessor timings:");
    writefln("  clang: %.2f s", Preprocessor.totalTimeClang / 1_000_000_000.0);
    writefln("  cl:    %.2f s", Preprocessor.totalTimeCl / 1_000_000_000.0);
}

//────────────────────────────────────────────────────────────────────────────────────────────────── 
private: 

void largeTest(string name, string[] includeDirectories...) {
    writefln("Testing %s ...", name);

    Config conf = {
        sourceDirectory: "resources/large-tests/",
        targetDirectory: ".target/test-%s/".format(name),
        includeDirectories: includeDirectories
    };

    writefln("  Including: %s", conf.includeDirectories);
    
    EC ec = new EC(conf);

    ec.addCFile("test_%s.c".format(name)); 
    ec.generate();

    // Compare the generated output to the preprocessed output
    string expectedFile = ".target/test-%s/test_%s.i".format(name, name);
    string generatedFile = ".target/test-%s/test_%s.c".format(name, name);
    writefln("  Comparing %s -> %s", expectedFile, generatedFile);
    new CompareRelaxed().compare(expectedFile, generatedFile);
    writefln("  Finished testing %s", name);
}

void testMiniVrt() {
    writefln("Testing mini_vrt ...");

    string vulkanInclude = environment.get("VULKAN_SDK") ~ "/Include";
    string glfwInclude   = "C:/work/glfw-3.4.bin.WIN64/include";

    writefln("  Vulkan include : %s", vulkanInclude);
    writefln("  GLFW include   : %s", glfwInclude);

    Config conf = {
        sourceDirectory: "C:/pvmoore/d/experimental/mini_vrt/c/src/",
        targetDirectory: ".target/test-mini_vrt/",
        includeDirectories: [
            vulkanInclude,
            glfwInclude
        ]
    };
    
    
    EC ec = new EC(conf);

    ec.addCFile("main.c");
    ec.generate();
    writefln("  Done");
}
void testCimgui() {
    writefln("Testing cimgui ...");

    Config conf = {
        sourceDirectory: "resources/large-tests/",
        targetDirectory: ".target/test-cimgui/",
        includeDirectories: [
            "c:/pvmoore/cpp/cimgui/"
            //"c:/pvmoore/cpp/cimgui/imgui/"
        ]
    };
    
    EC ec = new EC(conf);

    ec.addCFile("test_cimgui.c");
    ec.generate();
    writefln("  Done");
}
void testVma() {
    writefln("Testing vma ...");

    string vulkanInclude = environment.get("VULKAN_SDK") ~ "/Include";

    Config conf = {
        sourceDirectory: "resources/large-tests/",
        targetDirectory: ".target/test-vma/",
        includeDirectories: [
            vulkanInclude,
            vulkanInclude ~ "/vma/"
        ]
    };
    
    EC ec = new EC(conf);

    ec.addCFile("test_vma.c");
    ec.generate();
    writefln("  Done");
}
void testKtx() {
    writefln("Testing ktx ...");

    Config conf = {
        sourceDirectory: "resources/large-tests/",
        targetDirectory: ".target/test-ktx/",
        includeDirectories: [
            "C:/Temp/KTX-Software-5.0.0-rc1/lib/include/",
            "C:/Temp/KTX-Software-5.0.0-rc1/external/dfdutils/",
            environment.get("VULKAN_SDK") ~ "/Include"
        ]
    };
    
    EC ec = new EC(conf);

    ec.addCFile("test_ktx.c");
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
    ec.generate();

    string srcFilename       = "resources/test-suite/%s.c".format(filename);
    string expectFile        = "resources/test-suite/%s.expected.h".format(filename);
    string truthFilename     = ".target/test-suite/%s.i".format(filename);
    string generatedFilename = ".target/test-suite/%s.c".format(filename);

    auto comparer = new CompareStrict();

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

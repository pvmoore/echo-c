module test;

import std.stdio;

import ec;

void main() {
    writeln("Hello World");

    //EC ec = testMiniVrt();
    EC ec = testTest1();

    ec.resolve();
    ec.generate();
}

EC testTest1() {
    Config conf = {
        sourceDirectory: "resources/test-data/",
        targetDirectory: ".target/test-data/",
        includeDirectories: []
    };

    EC ec = new EC(conf);

    ec.addCFile("test1.c");

    return ec;
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

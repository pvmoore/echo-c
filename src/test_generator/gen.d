module test_generator.gen;

import test_generator.gen_cimgui;
import test_generator.gen_ktx;
import test_generator.gen_vma;
import test_generator.gen_vulkan;

void main() {
    generateVma();
    generateCimgui();
    generateKtx();
    generateVulkan();
}

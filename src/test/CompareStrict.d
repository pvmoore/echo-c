module test.CompareStrict;

import std.stdio     : writefln;
import std.file      : read;
import common.utils  : as;
import test.TestTokeniser;

final class CompareStrict {
    bool compare(string srcFile, string targetFile) {
        auto src = read(srcFile).as!string;
        auto target = read(targetFile).as!string;

        auto srcTokens = TestTokeniser.tokenise(src);
        auto targetTokens = TestTokeniser.tokenise(target);

        if(srcTokens.length != targetTokens.length) {
            writefln("Token count mismatch: %s != %s", srcTokens.length, targetTokens.length);
        }

        auto count = srcTokens.length < targetTokens.length ? srcTokens.length : targetTokens.length;
        foreach(i; 0..count) {

            string srcToken = srcTokens[i].text;
            string targetToken = targetTokens[i].text;

            bool equal = srcToken == targetToken;
            string estr = equal ? "==" : "!=";

            if(!equal) {
                writefln("[%s %s] %s %s %s", srcTokens[i].line, targetTokens[i].line, srcToken, estr, targetToken);
                return false;
            }
        }
        return true;
    }
}

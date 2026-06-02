module test.CompareRelaxed;

import std.stdio     : writefln;
import std.file      : read;
import std.format    : format;
import std.typecons  : Tuple, tuple;
import std.algorithm : all, any, map;
import std.range     : array, join;
import common.utils  : as;

import test.FuzzyMatch;
import test.TestTokeniser;

final class CompareRelaxed {
    TestTokeniser.Token[] expTokens;
    TestTokeniser.Token[] genTokens;
    int expPos;
    int genPos;

    string peekExpected(int offset, bool simplify = false) {
        if(expPos + offset >= expTokens.length) return "";
        string s = expTokens[expPos + offset].text;
        if(simplify) {
            if(s[0] == '\"') s = "<string>";
        }
        return s;
    }
    string peekGenerated(int offset, bool simplify = false) {
        if(genPos + offset >= genTokens.length) return "";
        string s = genTokens[genPos + offset].text;
        if(simplify) {
            if(s[0] == '\"') s = "<string>";
        }
        return s;
    }
    int peekExpectedLine(int offset = 0) {
        if(expPos + offset >= expTokens.length) return 0;
        return expTokens[expPos + offset].line;
    }
    int peekGeneratedLine(int offset = 0) {
        if(genPos + offset >= genTokens.length) return 0;
        return genTokens[genPos + offset].line;
    }
    bool expMatchesN(int offset, string[] t...) {
        foreach(i; 0..t.length) {
            string s = peekExpected(i.as!int + offset, true);
            if(s != t[i]) return false;
        }
        return true;
    }
    bool expMatches(string[] t...) {
        return expMatchesN(0, t);
    }
    bool genMatchesN(int offset, string[] t...) {
        foreach(i; 0..t.length) {
            string s = peekGenerated(i.as!int + offset, true);
            if(s != t[i]) return false;
        }
        return true;
    }
    bool genMatches(string[] t...) {
        return genMatchesN(0, t);
    }
    void skipToNextExpectedLine() {
        int line = expTokens[expPos].line;
        do{
            expPos++;
        }while(expPos < expTokens.length && expTokens[expPos].line == line);
    }

    bool compare(string expectedFile, string genFile) {
        string expected = read(expectedFile).as!string;
        string gen      = read(genFile).as!string;

        this.expTokens = TestTokeniser.tokenise(expected);
        this.genTokens = TestTokeniser.tokenise(gen);
        this.expPos = 0;
        this.genPos = 0;

        while(expPos < expTokens.length && genPos < genTokens.length) {

            // Skip backslash
            if(expMatches("\\")) {
                writefln("Skipping backslash @ exp.%s, gen.%s:", expTokens[expPos].line, genTokens[genPos].line);
                expPos++;
                continue;
            }
            // Skip #pragma once in the expected stream
            if(expMatches("#", "pragma", "once")) {
                writefln("Skipping #pragma once");
                skipToNextExpectedLine();
                continue;
            }
            // Skip #pragma region in the expected stream
            if(expMatches("#", "pragma", "region")) {
                writefln("Skipping #pragma region");
                skipToNextExpectedLine();
                continue;
            }
            // Skip #pragma endregion in the expected stream
            if(expMatches("#", "pragma", "endregion")) {
                writefln("Skipping #pragma endregion");
                skipToNextExpectedLine();
                continue;
            }
            // unsigned -> unsigned int match
            if(genMatches("unsigned", "int") && expMatches("unsigned") && 
                  expTokens[expPos+1].text != "int" && expTokens[expPos+1].text != "__int32") {
                writefln("Skipping unsigned -> unsigned int match @ exp.%s, gen.%s:", expTokens[expPos].line, genTokens[genPos].line);
                expPos++;
                genPos+=2;
                continue;
            }
            // Skip unnecessary semicolon
            if(expMatches(";") && !genMatches(";")) {
                writefln("Skipping unnecessary semicolon @ exp.%s, gen.%s:", expTokens[expPos].line, genTokens[genPos].line);
                expPos++;
                continue;
            }

            string expToken = peekExpected(0);
            string genToken = peekGenerated(0);

            // Look for an exact match
            bool exactEqual = expToken == genToken;
            
            if(!exactEqual) {
                // Enter fuzzy match mode

                bool fuzzyEqual = fuzzyCompare();
                if(fuzzyEqual) {
                    continue;
                }

                writefln("expected[%s '%s'] != generated[%s '%s']", expTokens[expPos].line, expToken, genTokens[genPos].line, genToken);
                return false;
            }

            expPos++;
            genPos++;
        }

        if(expPos < expTokens.length || genPos < genTokens.length) {
            writefln("Token length mismatch: %s != %s", expPos, genPos);
            return false;
        }

        return true;
    }    
private:
    bool fuzzyCompare() {

        auto m = FuzzyMatch.findFirstMatch(this);

        bool found() {
            writefln("    Allowed match @ line exp.%s, gen.%s:", expTokens[expPos].line, genTokens[genPos].line);
            writefln("     exp: %s", expTokens[expPos..expPos + m.expLength].map!(t=>t.text).join(" "));
            writefln("          %s", m.match.expValues);
            writefln("     gen: %s", genTokens[genPos..genPos + m.genLength].map!(t=>t.text).join(" "));
            writefln("          %s", m.match.genValues);
            expPos += m.expLength;
            genPos += m.genLength;
            return true;
        }

        if(m.found) {
            return found();
        } else {
            // Reverse up to 2 tokens to see if we can match
            foreach(offset; 0..2) {
                expPos--;
                genPos--;

                m = FuzzyMatch.findFirstMatch(this);
                if(m.found) {
                    return found();
                }
            }
        }        
        return false;
    }    
}

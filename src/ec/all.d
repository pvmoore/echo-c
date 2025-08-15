module ec.all;

public:

import std.format    : format;
import std.range     : array, join;
import std.algorithm : map, filter;
import std.file      : exists, isFile, isDir, mkdirRecurse;
import std.path      : baseName, stripExtension;
import std.string    : strip, indexOf, split, splitLines, toLower;
import std.array     : replace;
import std.typecons  : Tuple, tuple;

import ec;

import ec.gen.StmtGenerator;

import ec.lex.Token;
import ec.lex.Tokens;
import ec.lex.Lexer;

import ec.preprocess.Preprocessor;

import ec.misc.logging;
import ec.misc.utils;

import ec.parse.node.Node;
import ec.parse.node.CFile;

import ec.parse.expr.Addressof;
import ec.parse.expr.Call;
import ec.parse.expr.Cast;
import ec.parse.expr.Dot;
import ec.parse.expr.Expr;
import ec.parse.expr.Identifier;
import ec.parse.expr.Index;
import ec.parse.expr.Infix;
import ec.parse.expr.Initialiser;
import ec.parse.expr.Number;
import ec.parse.expr.Parens;
import ec.parse.expr.Prefix;
import ec.parse.expr.Postfix;
import ec.parse.expr.StringLiteral;
import ec.parse.expr.Ternary;
import ec.parse.expr.Valueof;

import ec.parse.stmt.Break;
import ec.parse.stmt.Continue;
import ec.parse.stmt.DoWhile;
import ec.parse.stmt.Enum;
import ec.parse.stmt.For;
import ec.parse.stmt.Function;
import ec.parse.stmt.If;
import ec.parse.stmt.Label;
import ec.parse.stmt.Pragma;
import ec.parse.stmt.Return;
import ec.parse.stmt.Scope;
import ec.parse.stmt.Stmt;
import ec.parse.stmt.Struct;
import ec.parse.stmt.Switch;
import ec.parse.stmt.Typedef;
import ec.parse.stmt.Union;
import ec.parse.stmt.Var;
import ec.parse.stmt.While;

import ec.parse.type.ArrayType;
import ec.parse.type.EType;
import ec.parse.type.FunctionPtr;
import ec.parse.type.SimpleType;
import ec.parse.type.Type;
import ec.parse.type.TypeRef;

import ec.parse.CallingConvention;
import ec.parse.ExprParser;
import ec.parse.Operator;
import ec.parse.PragmaParser;
import ec.parse.PtrFlags;
import ec.parse.StmtParser;
import ec.parse.StorageClass;
import ec.parse.SyntaxError;
import ec.parse.TypeModifiers;
import ec.parse.TypeParser;

import common.utils : isOneOf, as, isA, throwIf, todo, removeAt, indexOf, containsKey, repeat, className;
import common.io    : Ansi, ansiWrap;
import common       : StringBuffer;



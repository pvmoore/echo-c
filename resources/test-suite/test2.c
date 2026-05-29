

typedef __declspec(deprecated) __declspec(align(16)) struct A1 {
    int Low;
} A1;

typedef __declspec(deprecated) __declspec(align(16)) union {
    int Low;
} A2;

typedef __declspec(deprecated) __declspec(align(16)) enum {
    Low,
    High
} A3;

typedef __declspec(align(16)) int*const A;
typedef __declspec(align(16)) int B;

__declspec(align(16)) int a;
__declspec(align(16)) int b;
A c;
B d;

__declspec(align(16)) struct {
    int Low;
} c2;

__declspec(align(16)) struct {
    int Low;
} c3;

__declspec(align(16)) union {
    int Low;
} c4;

__declspec(align(16)) union {
    int Low;
} c5;

__declspec(align(16)) enum {
    Low,
    High
} c6;

__declspec(align(16)) enum {
    Low,
    High
} c7;

typedef __declspec(align(16)) __declspec(no_init_all) __pragma(warning(push)) __pragma(warning(disable:4845)) __pragma(warning(pop)) struct _CONTEXT {
    int P1Home;
} CONTEXT;


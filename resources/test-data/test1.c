
#include <stdbool.h>

// variable declarations and definitions
static void variables() {
    int a = 5;
    float b = 3.14;
    char c = 'A';
    long long d = 123456789012345;
    double e = 2.71828;
    bool f = true;
    short g = 10;
    unsigned int h = 20;
    long double i = 3.14159265358979323846;
    signed char j = -5;

    int k = { 0 };
    //int l = {};     // c23

    int arr0[2] = {1, 2};
    int arr1[11] = { 1, [2] = 5, 2, [4] = 6, 9 }; // {1, 0, 5, 2, 6, 9, 0, 0, 0, 0, 0 }

    char str[] = "Hello, World" "!!";

}

typedef struct Sun {
    int radius;
    float temperature;
    int a;
    int b;
    int c;
    bool isShining;
} Sun;

// struct initialisation
void structs() {
    Sun sun = { .radius = 695700, .temperature = 5778, 10, 20, .isShining = true };
    Sun* ptr = &sun;

    int a1 = sun.a;
    int a2 = ptr->a; // pointer access

}
void statements() {
    int h;
    for(int i = 0, j=0, *volatile const k = &h; i<10; i++, j--, ++h) {
        printf("Iteration %d\n", i);
    }
label1:
    while(h > 0) {
        printf("H is positive: %d\n", h);

        if(h == 10) continue;
        if(h == 11) break;
        --h;
    }
label2:
    int* ptr = &h;
    do{
        *ptr++;
    }while(true);

aswitch:
    switch(h) {
        case 1:
            printf("H is 1\n");
            break;
        case 2:
            printf("H is 2\n");
            break;
        default:
            printf("H is something else\n");
            break;
    }
}
void typedefs() {
    typedef struct _Mbstatet { 
        unsigned long _Wchar;
        unsigned short _Byte, _State;
    } _Mbstatet;

    _Mbstatet mbState;
}

void arrays() {
    int arr1[] = { 1, 2, 3 };
    int arr2[2][3] = { { 1, 2, 3 }, { 4, 5, 6 } };

    int a = arr1[0];
    int b = arr2[1][2];
}

int g1, g2, *g3;

typedef struct _Mbstatet {
    unsigned long _Wchar;
    unsigned short _Byte, _State;
} _Mbstatet2;

struct tm {
    int tm_sec;   
    int tm_min;   
    int tm_hour;  
    int tm_mday;  
    int tm_mon;   
    int tm_year;  
    int tm_wday;  
    int tm_yday;  
    int tm_isdst; 
};

typedef long long time_t;
typedef long long __time64_t;
typedef signed char INT8, *PINT8;

struct timespec {
    time_t tv_sec;  
    long   tv_nsec; 
};
struct _timespec64 {
    __time64_t tv_sec;
    long       tv_nsec;
};

int __cdecl _timespec64_get(struct _timespec64* _Ts, int _Base);

static __inline int __cdecl timespec_get(struct timespec* const _Ts, const int _Base) {
    return _timespec64_get((struct _timespec64*)_Ts, _Base);
}

struct { // sizeof(flags) = 4
    unsigned int flag1 : 1;
    unsigned int flag2 : 1;
    unsigned int flag3 : 1;
    unsigned int flag4 : 2;
    unsigned int flag5 : 4;
} flags;

struct SS;

enum AA { A, B = 1, C };
enum BB;

union CC;

union DD {
    int a;
    float b;
};

typedef struct _PROCESSOR_NUMBER {
    int a;
    int b;
    int c;
} PROCESSOR_NUMBER, *PPROCESSOR_NUMBER;

PPROCESSOR_NUMBER pnum;

// typedef of a function ptr
typedef void*(*const foobar)(int);

// typedef of a function declaration
typedef void* const __cdecl barbaz(int);

// function declaration used as a type
typedef barbaz *PEXCEPTION_ROUTINE;

typedef int (__cdecl* _CoreCrtSecureSearchSortCompareFunction)(void*, const void*, const void*);
void* __cdecl bsearch_s(const void* _Key,
                        const void* _Base,
                        long long   _NumOfElements,
                        long long   _SizeOfElements,
                        _CoreCrtSecureSearchSortCompareFunction _CompareFunction,
                        void*       _Context);

typedef void* (__stdcall *PFN_vkAllocationFunction)(void* pUserData);
typedef struct VkAllocationCallbacks {
    void*                    pUserData;
    PFN_vkAllocationFunction pfnAllocation;
} VkAllocationCallbacks;

VkAllocationCallbacks allocCallbacks, *allocCallbacksPtr;


typedef unsigned long long LARGE_INTEGER;
typedef long long LONG, *LONG_PTR;

typedef char __C_ASSERT__[
    (((LONG)(LONG_PTR)
    &(((struct { char x; LARGE_INTEGER test; }*)0)->test)) == 8) ? 1 : -1
    ];

typedef int array10[10];
array10 arr1;

int main() {
    variables();
    structs();
    statements();
    arrays();
    
    return 0;
}

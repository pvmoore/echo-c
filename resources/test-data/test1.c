
#include <stdbool.h>

// variable declarations and definitions
void variables() {
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

int main() {
    variables();
    structs();
    statements();
    
    return 0;
}

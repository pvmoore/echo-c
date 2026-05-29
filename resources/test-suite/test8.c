
// Comma operator tests

int foo() {

    // These commas are not comma operators
    int a=1, b=2, c=3;              

    // comma operator i = b
    int i = (a, b);  

    // a += 2
    // i2 = a + b (a is now 3, i2 = 5)
    int i2 = (a += 2, a + b);

    // a = 5
    // i = 7
    i = a += 2, a + b;

    { 
        int i = a, b, c; 
    }

    // These commas are not comma operators
    int arr1[11] = { 1, [2] = 5, 2, [4] = 6, 9 }; 

    struct AA {
        int a;
        int b;
        int c;
    };

    struct AA info = {
        .a = 1,
        .b = 0
            | 1
            | 2
            ,
        .c = 0
    };

    // returns 7
    return i, 7;
}

typedef enum VkExternalMemoryFeatureFlagBits {
    // These commas are not comma operators
    A = 0x00000001,
    B = 0x00000002 | 1,
} VkExternalMemoryFeatureFlagBits;

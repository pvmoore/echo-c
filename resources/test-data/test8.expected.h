
int foo() {
    int a=1, b=2, c=3;              
    int i = (a, b);  
    int i2 = (a += 2, a + b);
    i = a += 2, a + b;

    { 
        int i = a, b, c; 
    }

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

    return i, 7;
}
typedef enum VkExternalMemoryFeatureFlagBits {
    A = 0x00000001,
    B = 0x00000002 | 1
} VkExternalMemoryFeatureFlagBits;


void foo() {
    int x;
    int i;
    int len;
    int *p1;
    int *p2;
    
    for (; i < len; i += 1) {
        x |= p1[i] ^ p2[i];
    }
}

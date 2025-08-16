 
typedef long HRESULT;

__forceinline  HRESULT HRESULT_FROM_WIN32(unsigned long x) { 
    return (HRESULT)(x) <= 0 ? (HRESULT)(x) : (HRESULT) (((x) & 0x0000FFFF) | (7 << 16) | 0x80000000);
}

__forceinline HRESULT HRESULT_FROM_SETUPAPI(unsigned long x) { 
    return (((x) & (0x20000000|0xC0000000)) == (0x20000000|0xC0000000))
        ? ((HRESULT) (((x) & 0x0000FFFF) | (15 << 16) | 0x80000000))   
        : HRESULT_FROM_WIN32(x);}

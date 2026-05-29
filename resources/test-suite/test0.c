
typedef void* ENCLAVE_TARGET_FUNCTION(void*);
typedef ENCLAVE_TARGET_FUNCTION (*PENCLAVE_TARGET_FUNCTION);
typedef PENCLAVE_TARGET_FUNCTION LPENCLAVE_TARGET_FUNCTION;

int* (((*foo)))(void);          
int *(* (*(*foo2))(void) );     
int (* ((*foo3[2]))(void) );     

int baz[3]; 

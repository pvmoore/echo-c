
typedef unsigned int uint32_t;
static int VK_SUCCESS = 0;

struct VkVersion {
    uint32_t major;
    uint32_t minor;
    uint32_t patch;
};

int getVkVersion() {
	uint32_t apiVersion = 0;

    do{ 
        if(1) { 
            (void)( (!!(0)) || (1, 0) ); 
        } 
    }while(0);

    uint32_t major = ((uint32_t)(apiVersion) >> 22U) ;
    uint32_t minor = (((uint32_t)(apiVersion) >> 12U) & 0x3FFU) ;
    uint32_t patch = ((uint32_t)(apiVersion) & 0xFFFU) ;
	return 1;
}

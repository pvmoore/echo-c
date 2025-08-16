
typedef unsigned long long VkDeviceAddress;

typedef union VkDeviceOrHostAddressKHR {
    VkDeviceAddress    deviceAddress;
    void*              hostAddress;
} VkDeviceOrHostAddressKHR;

typedef struct {
    void* handle;
} Buffer;

typedef struct {
    int sType;
    void* pNext;
    int mode;
    void* src;
    VkDeviceOrHostAddressKHR dst;
} VkCopyAccelerationStructureToMemoryInfoKHR;

VkDeviceAddress getBufferDeviceAddress(void* handle) {
    return 0;
}

void foo() {
    void* handle;

    Buffer buffer;

    VkCopyAccelerationStructureToMemoryInfoKHR copyToMemory = {
        .sType = 1,
        .mode = 2,
        .src = handle,
        .dst.deviceAddress = getBufferDeviceAddress(buffer.handle)
    };
}

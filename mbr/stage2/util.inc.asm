%ifndef UTIL_ASM_INC
%define UTIL_ASM_INC

%ifndef UTIL_ASM_INC_NO_EXTERN
extern memcmp ; int memcmp(void *buf1, void *buf2, uint32_t len)
extern memcpy ; int memcpy(void *dst, void *src, uint32_t len)
extern memset ; int memset(void *dst, int byte, uint32_t len)

extern check_cpuid ; int check_cpuid()
extern get_cpu_features ; uint64_t get_cpu_features(void)
%endif

%endif

#include <nozzle/nozzle_c.h>
#include <string.h>

#ifdef _WIN32
#define PROBE_EXPORT __declspec(dllexport)
#else
#define PROBE_EXPORT __attribute__((visibility("default")))
#endif

PROBE_EXPORT uint64_t nozzle_test_connected_info_size(void) {
    return (uint64_t)sizeof(NozzleConnectedSenderInfo);
}

PROBE_EXPORT uint64_t nozzle_test_modifier_offset(void) {
    return (uint64_t)offsetof(NozzleConnectedSenderInfo, native_format_modifier);
}

// Header-layout fixture only: no core linkage, receiver, or GPU operation.
PROBE_EXPORT void nozzle_test_fill_connected_info(void *storage, uint64_t modifier) {
    NozzleConnectedSenderInfo *info = (NozzleConnectedSenderInfo *)storage;
    memset(info, 0, sizeof(*info));
    info->native_format_kind = NOZZLE_NATIVE_KIND_DXGI_FORMAT;
    info->native_format_value = UINT32_C(0x10203040);
    info->native_format_modifier = modifier;
}

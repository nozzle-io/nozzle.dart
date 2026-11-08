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

#define SNAPSHOT_SIZE(prefix, type) \
    PROBE_EXPORT uint64_t nozzle_test_##prefix##_size(void) { return sizeof(type); }
#define SNAPSHOT_FIELD(prefix, type, field) \
    PROBE_EXPORT uint64_t nozzle_test_##prefix##_##field##_offset(void) { \
        return offsetof(type, field); \
    } \
    PROBE_EXPORT uint64_t nozzle_test_##prefix##_##field##_size(void) { \
        return sizeof(((type *)0)->field); \
    }
#define SNAPSHOT_IDENTITY(prefix, type) \
    SNAPSHOT_SIZE(prefix, type) \
    SNAPSHOT_FIELD(prefix, type, name) \
    SNAPSHOT_FIELD(prefix, type, application_name) \
    SNAPSHOT_FIELD(prefix, type, id) \
    SNAPSHOT_FIELD(prefix, type, backend)

SNAPSHOT_IDENTITY(sender_snapshot, NozzleSenderInfoSnapshot)
SNAPSHOT_IDENTITY(connected_snapshot, NozzleConnectedSenderSnapshot)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, connected)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, width)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, height)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, format)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, semantic_format)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, estimated_fps)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, frame_counter)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, last_update_time_ns)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, native_format_kind)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, native_format_value)
SNAPSHOT_FIELD(connected_snapshot, NozzleConnectedSenderSnapshot, native_format_modifier)

#undef SNAPSHOT_IDENTITY
#undef SNAPSHOT_FIELD
#undef SNAPSHOT_SIZE

// Synthetic metadata, not values observed from a real sender or GPU frame.
#define FILL_IDENTITY(info) \
    memcpy((info)->name, "camera-\xe6\x97\xa5\xe6\x9c\xac\xf0\x9f\x9a\x80", \
           sizeof("camera-\xe6\x97\xa5\xe6\x9c\xac\xf0\x9f\x9a\x80")); \
    memcpy((info)->application_name, "fixture-\xf0\x9f\x9a\x80", sizeof("fixture-\xf0\x9f\x9a\x80")); \
    memcpy((info)->id, "01234567-89ab-cdef-0123-456789abcdef", sizeof("01234567-89ab-cdef-0123-456789abcdef")); \
    (info)->backend = NOZZLE_BACKEND_METAL

PROBE_EXPORT void nozzle_test_fill_sender_snapshot(void *storage) {
    NozzleSenderInfoSnapshot *info = (NozzleSenderInfoSnapshot *)storage;
    memset(info, 0, sizeof(*info));
    FILL_IDENTITY(info);
}

PROBE_EXPORT void nozzle_test_fill_connected_snapshot(void *storage) {
    NozzleConnectedSenderSnapshot *info = (NozzleConnectedSenderSnapshot *)storage;
    memset(info, 0, sizeof(*info));
    FILL_IDENTITY(info);
    info->connected = 7;
    info->width = 65;
    info->height = 3;
    info->format = NOZZLE_FORMAT_BGRA8_UNORM;
    info->semantic_format = NOZZLE_FORMAT_RGB16_FLOAT;
    info->estimated_fps = 59.9375;
    info->frame_counter = UINT64_C(0x123456789ab);
    info->last_update_time_ns = UINT64_C(0x23456789abc);
    info->native_format_kind = NOZZLE_NATIVE_KIND_MTL_PIXEL_FORMAT;
    info->native_format_value = UINT32_C(0x10203040);
    info->native_format_modifier = UINT64_C(0x3456789abcd);
}

#undef FILL_IDENTITY

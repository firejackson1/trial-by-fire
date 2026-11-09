// SPDX-License-Identifier: Apache-2.0
#pragma once
#include <string>

namespace trona::network {
inline constexpr char kNetworkBackendProperty[] = "ro.trona.network_backend";
inline constexpr char kVendorDeviceProperty[] = "ro.product.vendor.device";
inline constexpr char kLegacyNativeReadyProperty[] = "sys.trona.netd_ready";
inline constexpr char kLegacyNativeGenerationProperty[] = "sys.trona.netd_generation";
// Version prefix only; a valid ready value also contains the init-owned generation.
inline constexpr char kLegacyNativeReadyToken[] = "trona-qtaguid-v1";
enum class RequestedNetworkBackend { Modern, TronaLegacy };

// Narrow read boundary: zero succeeds, nonzero errors; never publishes properties.
struct PropertyReader {
    int (*read)(const char* name, std::string* value, void* context) noexcept;
    void* context;
};

// Captures requested mode/identity once. A request is not backend readiness.
// Reader/context must outlive the snapshot; readiness is checked freshly.
class NativeNetworkProfileSnapshot final {
public:
    explicit NativeNetworkProfileSnapshot(PropertyReader reader) noexcept;
    // On error the output is untouched. Null output returns EINVAL.
    int getRequestedBackend(RequestedNetworkBackend* output) const noexcept;
    // Capture once before real daemon initialization; this never publishes readiness.
    int captureLegacyNativeReadyToken(std::string* output) const noexcept;
    // Fresh trusted generation/readiness/generation reads; not an independent core probe.
    // Modern returns EOPNOTSUPP. No PID/debug-property liveness inference is made.
    int requireLegacyNativeReady() const noexcept;
private:
    struct Selection { int error; RequestedNetworkBackend backend; };
    static Selection capture(PropertyReader reader) noexcept;
    const PropertyReader reader_;
    const Selection selection_;
};

// Read-only singleton per linked image. Independently linked users consume the
// same immutable RO selector/vendor identity; no mutable policy owner lives here.
// Freeze records errors without aborting, allowing clatd integrity checks first.
void FreezeNativeNetworkProfile() noexcept;
int GetRequestedNetworkBackend(RequestedNetworkBackend* output) noexcept;
int CaptureLegacyNativeReadyToken(std::string* output) noexcept;
int RequireLegacyNativeReady() noexcept;
}  // namespace trona::network

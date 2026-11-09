// SPDX-License-Identifier: Apache-2.0
#include <trona/NativeNetworkProfile.h>
#include <android-base/properties.h>
#include <cerrno>
#include <charconv>
#include <cstdint>

namespace trona::network {
namespace {
int readStatus(int status) noexcept { return status > 0 ? -EIO : status; }
bool validGeneration(const std::string& value) noexcept {
    if (value.empty() || value[0] < '1' || value[0] > '9') return false;
    uint64_t parsed;
    const auto result = std::from_chars(value.data(), value.data() + value.size(), parsed);
    return result.ec == std::errc{} && result.ptr == value.data() + value.size();
}
int readProperty(const char* name, std::string* value, void*) noexcept {
    // libbase returns the fallback for absent/unreadable properties. Missing
    // selector means modern; missing readiness never means ready. Property read
    // permissions and the future ready publisher remain integration obligations.
    *value = android::base::GetProperty(name, "");
    return 0;
}
const NativeNetworkProfileSnapshot& processProfile() noexcept {
    static const NativeNetworkProfileSnapshot profile({readProperty, nullptr});
    return profile;
}
}  // namespace

NativeNetworkProfileSnapshot::Selection NativeNetworkProfileSnapshot::capture(
        PropertyReader reader) noexcept {
    using Backend = RequestedNetworkBackend;
    if (!reader.read) return {-EINVAL, Backend::Modern};
    std::string requested;
    int error = readStatus(reader.read(kNetworkBackendProperty, &requested, reader.context));
    if (error) return {error, Backend::Modern};
    if (requested.empty() || requested == "modern") return {0, Backend::Modern};
    if (requested != "legacy") return {-EINVAL, Backend::Modern};
    std::string device;
    error = readStatus(reader.read(kVendorDeviceProperty, &device, reader.context));
    if (error) return {error, Backend::Modern};
    if (device != "trona") return {-ENODEV, Backend::Modern};
    return {0, Backend::TronaLegacy};
}
NativeNetworkProfileSnapshot::NativeNetworkProfileSnapshot(PropertyReader reader) noexcept
    : reader_(reader), selection_(capture(reader)) {}

int NativeNetworkProfileSnapshot::getRequestedBackend(RequestedNetworkBackend* output) const noexcept {
    if (!output) return -EINVAL;
    if (selection_.error) return selection_.error;
    *output = selection_.backend;
    return 0;
}
int NativeNetworkProfileSnapshot::captureLegacyNativeReadyToken(std::string* output) const noexcept {
    if (!output) return -EINVAL;
    if (selection_.error) return selection_.error;
    if (selection_.backend != RequestedNetworkBackend::TronaLegacy) return -EOPNOTSUPP;
    std::string generation;
    const int error = readStatus(reader_.read(kLegacyNativeGenerationProperty, &generation, reader_.context));
    if (error) return error;
    if (generation.empty() || generation == "0") return -EAGAIN;
    if (!validGeneration(generation)) return -EPROTO;
    *output = std::string(kLegacyNativeReadyToken) + ":" + generation;
    return 0;
}
int NativeNetworkProfileSnapshot::requireLegacyNativeReady() const noexcept {
    std::string expected;
    int error = captureLegacyNativeReadyToken(&expected);
    if (error) return error;
    std::string token;
    error = readStatus(reader_.read(kLegacyNativeReadyProperty, &token, reader_.context));
    if (error) return error;
    if (token.empty() || token == "0") return -EAGAIN;
    const std::string prefix = std::string(kLegacyNativeReadyToken) + ":";
    if (token.compare(0, prefix.size(), prefix) != 0 ||
        !validGeneration(token.substr(prefix.size()))) return -EPROTO;
    if (token != expected) return -EAGAIN;
    std::string current;
    error = captureLegacyNativeReadyToken(&current);
    if (error) return error;
    return current == expected ? 0 : -EAGAIN;
}
void FreezeNativeNetworkProfile() noexcept { (void)processProfile(); }
int GetRequestedNetworkBackend(RequestedNetworkBackend* output) noexcept {
    return processProfile().getRequestedBackend(output);
}
int CaptureLegacyNativeReadyToken(std::string* output) noexcept {
    return processProfile().captureLegacyNativeReadyToken(output);
}
int RequireLegacyNativeReady() noexcept { return processProfile().requireLegacyNativeReady(); }
}  // namespace trona::network

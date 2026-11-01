import Foundation

var count = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
    count += 1
}
var instance = ProviderInstance(id: "synthetic-account", label: "Fixture", providerType: .openAI,
                                credentialType: .oauth, createdAt: Date(timeIntervalSince1970: 0))
check(instance.effectiveCodexClientVersion == "0.159.0", "old/default config inherits bundled version")
let oldData = try JSONEncoder().encode(instance)
check(!String(decoding: oldData, as: UTF8.self).contains("codexClientVersionOverride"), "nil adds no JSON churn")
let oldRestored = try JSONDecoder().decode(ProviderInstance.self, from: oldData)
check(oldRestored.codexClientVersionOverride == nil, "old JSON loads")
for good in ["0.159.0", "0.200.1", "1.0.0-beta.1", "1.0.0+build.2"] {
    check(ProviderInstance.normalizedCodexClientVersion(good) == good, "accept \(good)")
}
check(ProviderInstance.normalizedCodexClientVersion(" 0.200.0 \n") == "0.200.0", "trim boundaries")
for bad in ["", "0.159", "latest", "1.2.3\r\nX-Test: invalid", "1.2.3&x=1", "1.2.3/evil", "１.２.３", "1.2.3-beta..1", String(repeating: "1", count: 65) + ".2.3"] {
    check(ProviderInstance.normalizedCodexClientVersion(bad) == nil, "reject unsafe or malformed version")
}
instance.codexClientVersionOverride = "0.200.0"
check(instance.effectiveCodexClientVersion == "0.200.0", "override used")
let restored = try JSONDecoder().decode(ProviderInstance.self, from: JSONEncoder().encode(instance))
check(restored == instance, "backup JSON round-trip")
let prior = #"{"futureSetting":{"keep":true}}"#
let extras = instance.codexVersionExtras(merging: prior)!
check(ProviderInstance.codexVersionFromExtras(extras) == "0.200.0", "SQLite envelope round-trip")
let fields = try JSONSerialization.jsonObject(with: Data(extras.utf8)) as! [String: Any]
check((fields["futureSetting"] as? [String: Bool])?["keep"] == true, "preserve unknown synced fields")
check(instance.codexVersionExtras(merging: extras) == extras, "unchanged row is byte stable")
instance.codexClientVersionOverride = nil
let reset = instance.codexVersionExtras(merging: extras)!
check(ProviderInstance.codexVersionFromExtras(reset) == nil, "reset removes only version")
check(reset.contains("futureSetting"), "reset preserves other extras")
check(instance.effectiveCodexClientVersion == "0.159.0", "reset restores default")
instance.codexClientVersionOverride = "bad\nheader"
check(instance.effectiveCodexClientVersion == "0.159.0", "malformed imported value falls back safely")
let apiKey = ProviderInstance(label: "API fixture", providerType: .openAI, credentialType: .apiKey,
                              codexClientVersionOverride: "0.200.0")
check(!apiKey.supportsCodexClientVersion, "API key has no Codex setting")
check(apiKey.effectiveCodexClientVersion == "0.159.0", "API key cannot acquire Codex override")
let other = ProviderInstance(label: "Other fixture", providerType: .anthropic, credentialType: .oauth,
                             codexClientVersionOverride: "0.200.0")
check(!other.supportsCodexClientVersion, "other OAuth unaffected")
var malformed = String(decoding: oldData, as: UTF8.self)
malformed.removeLast()
malformed += ",\"codexClientVersionOverride\":123}"
let decoded = try JSONDecoder().decode(ProviderInstance.self, from: Data(malformed.utf8))
check(decoded.codexClientVersionOverride == nil, "wrong-type optional field does not discard the provider")
print("PASS: \(count) runtime Codex configuration checks (shipping ProviderInstance.swift)")

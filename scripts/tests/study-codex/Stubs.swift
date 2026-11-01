import Foundation

// Isolate ProviderInstance's unrelated credential / channel dependencies.
// No Keychain, network, filesystem, application singleton or real user data.
enum ProviderType: String, Codable {
    case openAI, openAIResponses, anthropic, gemini, antigravity, openRouter, xAI, kimiCode, githubCopilot, unsupported
    static func decoded(_ value: String) -> Self { Self(rawValue: value) ?? .unsupported }
}
enum ProviderCredential: String, Codable { case oauth, apiKey }
enum OpenAIProvider { static let codexClientVersion = "0.159.0" }
enum OpenCodeChannel { static func looksLikeOpenCodeBaseURL(_ url: String?) -> Bool { false } }
struct ClaudeTokenStorage {}
struct GeminiTokenStorage {}
struct CodexTokenStorage {}
struct XAITokenStorage {}
struct KimiTokenStorage {}
struct CopilotTokenStorage { var githubToken = "" }
enum ProviderKeychainHelper {
    static func loadAPIKey(instanceId: String, caller: String) -> String? { nil }
    static func loadOAuthString(instanceId: String, account: String, caller: String) -> String? { nil }
    static func oauthNeedsReauth(instanceId: String) -> Bool { false }
    static func loadOAuthToken<T>(instanceId: String, as type: T.Type, caller: String) -> T? { nil }
}

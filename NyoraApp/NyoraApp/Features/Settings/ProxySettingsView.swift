import SwiftUI

/// SCREEN 4b — Proxy. Mirrors pref_proxy.xml.
struct ProxySettingsView: View {
    @AppStorage("proxy_type_2") private var type: ProxyTypeOption = .direct
    @AppStorage("proxy_address") private var address = ""
    @AppStorage("proxy_port") private var port = ""
    @AppStorage("proxy_login") private var login = ""
    @AppStorage("proxy_password") private var password = ""
    @State private var testResult: String?
    @State private var testing = false

    private var enabled: Bool { type != .direct }

    var body: some View {
        List {
            Section { SettingsHeader("Proxy", systemImage: "network") }

            Section {
                SingleSelectRow(title: "Type", selection: $type)
            }

            Section {
                TextEditRow(title: "Address", placeholder: "proxy.example.com", keyboard: .URL, text: $address)
                TextEditRow(title: "Port", placeholder: "8080", keyboard: .numberPad, text: $port)
            }
            .disabled(!enabled)

            Section("Authorization (optional)") {
                TextEditRow(title: "Username", text: $login)
                TextEditRow(title: "Password", secure: true, text: $password)
            }
            .disabled(!enabled)

            Section {
                ActionRow(title: testing ? "Testing…" : "Test connection",
                          systemImage: "checkmark.shield",
                          summary: testResult) {
                    runTest()
                }
                .disabled(testing)
            } footer: {
                // NOTE: The NyoraEngine WebClient builds its own URLSession and does not
                // currently read these proxy values, so applying the proxy app-wide requires
                // WebClient to consult ProxyConfiguration.currentDictionary() when it creates
                // its URLSessionConfiguration. These values are persisted to UserDefaults for
                // that integration; the test above validates them live through the proxy.
                Text("Settings are stored on this device.")
            }
            .disabled(!enabled)
        }
        .navigationTitle("Proxy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runTest() {
        guard enabled else { testResult = "Proxy disabled"; return }
        let host = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else { testResult = "Enter a proxy address"; return }
        guard let portNum = Int(port.trimmingCharacters(in: .whitespaces)), (1...65535).contains(portNum) else {
            testResult = "Port must be 1–65535"; return
        }

        testing = true
        testResult = nil
        let dict = ProxyConfiguration.connectionProxyDictionary(
            type: type, host: host, port: portNum, login: login, password: password)

        Task {
            let start = Date()
            do {
                let config = URLSessionConfiguration.ephemeral
                config.connectionProxyDictionary = dict
                config.timeoutIntervalForRequest = 12
                config.requestCachePolicy = .reloadIgnoringLocalCacheData
                let session = URLSession(configuration: config)
                // Reach a tiny endpoint through the proxy to confirm tunneling works.
                var req = URLRequest(url: URL(string: "https://www.google.com/generate_204")!)
                req.timeoutInterval = 12
                let (_, response) = try await session.data(for: req)
                session.invalidateAndCancel()
                let ms = Int(Date().timeIntervalSince(start) * 1000)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                await MainActor.run {
                    testResult = "Connected via \(type.label) in \(ms) ms (HTTP \(code))"
                    testing = false
                }
            } catch {
                await MainActor.run {
                    testResult = "Failed: \((error as NSError).localizedDescription)"
                    testing = false
                }
            }
        }
    }
}

/// Builds a CFNetwork `connectionProxyDictionary` for a URLSessionConfiguration.
/// Shared so WebClient/ImageLoader can apply the same proxy when wired up.
enum ProxyConfiguration {
    static func connectionProxyDictionary(type: ProxyTypeOption, host: String, port: Int,
                                          login: String, password: String) -> [AnyHashable: Any] {
        var dict: [AnyHashable: Any] = [:]
        switch type {
        case .direct:
            break
        case .http:
            dict[kCFNetworkProxiesHTTPEnable as String] = 1
            dict[kCFNetworkProxiesHTTPProxy as String] = host
            dict[kCFNetworkProxiesHTTPPort as String] = port
            // HTTPS leg of the same proxy (keys are macOS-named but honored on iOS).
            dict["HTTPSEnable"] = 1
            dict["HTTPSProxy"] = host
            dict["HTTPSPort"] = port
        case .socks:
            // The kCFNetworkProxiesSOCKS* constants are macOS-only; the underlying string
            // keys are honored by URLSessionConfiguration.connectionProxyDictionary on iOS.
            dict["SOCKSEnable"] = 1
            dict["SOCKSProxy"] = host
            dict["SOCKSPort"] = port
        }
        if !login.isEmpty {
            dict[kCFProxyUsernameKey as String] = login
            dict[kCFProxyPasswordKey as String] = password
        }
        return dict
    }

    /// Convenience reader for other components to apply the persisted proxy.
    /// Cheap change-detector so ImageLoader can rebuild its session only when proxy settings change.
    static func fingerprint(defaults: UserDefaults = .standard) -> String {
        ["proxy_type_2", "proxy_address", "proxy_port", "proxy_login", "proxy_password"]
            .map { defaults.string(forKey: $0) ?? "" }
            .joined(separator: "\u{1}")
    }

    static func currentDictionary(defaults: UserDefaults = .standard) -> [AnyHashable: Any]? {
        guard let raw = defaults.string(forKey: "proxy_type_2"),
              let type = ProxyTypeOption(rawValue: raw), type != .direct else { return nil }
        let host = (defaults.string(forKey: "proxy_address") ?? "").trimmingCharacters(in: .whitespaces)
        guard !host.isEmpty, let port = Int(defaults.string(forKey: "proxy_port") ?? "") else { return nil }
        return connectionProxyDictionary(type: type, host: host, port: port,
                                         login: defaults.string(forKey: "proxy_login") ?? "",
                                         password: defaults.string(forKey: "proxy_password") ?? "")
    }
}

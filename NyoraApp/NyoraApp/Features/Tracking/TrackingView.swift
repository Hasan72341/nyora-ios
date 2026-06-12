import SwiftUI
import NyoraEngine

/// Tracking hub listing all four services and the linked manga. Each service row navigates
/// to a `TrackerServiceView` that handles its specific sign-in flow.
struct TrackingView: View {
    @StateObject private var tracking = TrackingService.shared

    var body: some View {
        List {
            Section("Services") {
                ForEach(TrackerService.allCases) { service in
                    NavigationLink {
                        TrackerServiceView(service: service)
                    } label: {
                        HStack {
                            Label(service.displayName, systemImage: "antenna.radiowaves.left.and.right")
                            Spacer()
                            if let name = tracking.userName(service) {
                                Text(name).font(.caption).foregroundStyle(.secondary)
                            } else {
                                Text("Tap to log in").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            linkedSection
        }
        .navigationTitle("Tracking")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var linkedSection: some View {
        Section("Linked manga") {
            if tracking.trackedList.isEmpty {
                Text("No manga linked yet. Use the Track button on a manga’s detail page.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tracking.trackedList) { tracked in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tracked.manga.title).font(.subheadline)
                        Text("\(tracked.service.displayName): \(tracked.remoteTitle)  ·  ch \(tracked.lastSyncedProgress)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { idx in
                    let items = tracking.trackedList
                    idx.forEach { tracking.unlink(items[$0].service, items[$0].manga.id) }
                }
            }
        }
    }
}

/// Sign-in / sign-out and per-service status for one tracker.
struct TrackerServiceView: View {
    let service: TrackerService

    @StateObject private var tracking = TrackingService.shared
    @State private var working = false
    @State private var error: String?

    // Kitsu password-grant fields.
    @State private var kitsuUser = ""
    @State private var kitsuPassword = ""
    // AniList legacy token-paste fallback.
    @State private var tokenField = ""

    var body: some View {
        List {
            if tracking.isSignedIn(service) {
                accountSection
            } else {
                signInSection
            }
            if let error {
                Section { Text(error).font(.footnote).foregroundStyle(.red) }
            }
        }
        .navigationTitle(service.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var accountSection: some View {
        Section("Account") {
            LabeledContent("Logged in as", value: tracking.userName(service) ?? service.displayName)
            Button("Sign out", role: .destructive) {
                tracking.signOut(service)
                error = nil
            }
        }
    }

    @ViewBuilder private var signInSection: some View {
        switch service {
        case .kitsu:
            kitsuSignIn
        default:
            oauthSignIn
        }
    }

    private var oauthSignIn: some View {
        Section {
            Button {
                Task { await oauth() }
            } label: {
                HStack {
                    Text("Sign in with \(service.displayName)")
                    if working { Spacer(); ProgressView().controlSize(.small) }
                }
            }
            .disabled(working)
            if service == .aniList {
                // Legacy token-paste fallback (still supported).
                SecureField("…or paste an access token", text: $tokenField)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Use pasted token") {
                    Task { await pasteToken() }
                }
                .disabled(tokenField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || working)
            }
        } footer: {
            Text(footer)
        }
    }

    private var kitsuSignIn: some View {
        Section {
            TextField("Kitsu email", text: $kitsuUser)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
            SecureField("Password", text: $kitsuPassword)
            Button {
                Task { await kitsuLogin() }
            } label: {
                HStack {
                    Text("Sign in")
                    if working { Spacer(); ProgressView().controlSize(.small) }
                }
            }
            .disabled(kitsuUser.isEmpty || kitsuPassword.isEmpty || working)
        } footer: {
            Text("Kitsu signs in with your account email and password (OAuth2 password grant).")
        }
    }

    private var footer: String {
        switch service {
        case .aniList: return "Opens AniList to authorize Nyora (implicit grant). Tokens are stored on-device."
        case .myAnimeList: return "Opens MyAnimeList to authorize Nyora (OAuth2 with PKCE)."
        case .shikimori: return "Opens Shikimori to authorize Nyora (OAuth2). Requires a client secret configured in TrackerProtocol.swift."
        case .kitsu: return ""
        }
    }

    private func oauth() async {
        working = true; error = nil
        do { try await tracking.signInViaOAuth(service) }
        catch let TrackerOAuthError.cancelled { /* user backed out */ }
        catch { self.error = (error as? TrackerOAuthError)?.errorDescription ?? error.localizedDescription }
        working = false
    }

    private func kitsuLogin() async {
        working = true; error = nil
        do { try await tracking.signInKitsu(username: kitsuUser, password: kitsuPassword); kitsuPassword = "" }
        catch { self.error = (error as? TrackerOAuthError)?.errorDescription ?? error.localizedDescription }
        working = false
    }

    private func pasteToken() async {
        working = true; error = nil
        do { try await tracking.signIn(token: tokenField); tokenField = "" }
        catch { self.error = (error as? TrackerOAuthError)?.errorDescription ?? error.localizedDescription }
        working = false
    }
}

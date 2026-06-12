import SwiftUI

struct SupabaseSyncSettingsView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("sb_access_token") private var accessToken = ""
    @AppStorage("sb_user_id") private var userId = ""
    @AppStorage("sb_last_sync_timestamp") private var lastSyncTimestamp = "1970-01-01T00:00:00Z"
    
    @State private var syncing = false
    @State private var restoring = false
    @State private var signingIn = false
    @State private var error: String?
    
    var body: some View {
        List {
            Section {
                if !userId.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(SupabaseConfig.parseEmail(fromJwt: accessToken))
                            .font(.headline)
                        Text(userId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Guest")
                            .font(.headline)
                        Text("Sign in to sync your data across devices")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if userId.isEmpty {
                Section {
                    Button {
                        signIn()
                    } label: {
                        if signingIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Label("Sign in with Google", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                    .disabled(signingIn)
                }
            } else {
                Section {
                    Button {
                        sync()
                    } label: {
                        if syncing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Label("Sync now", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(syncing || restoring)

                    Button {
                        restore()
                    } label: {
                        if restoring {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Label("Restore from Cloud", systemImage: "icloud.and.arrow.down")
                        }
                    }
                    .disabled(syncing || restoring)

                    LabeledContent("Last synced", value: lastSyncTimestamp == "1970-01-01T00:00:00Z" ? "Never" : lastSyncTimestamp)
                }

                Section {
                    Button(role: .destructive) {
                        model.signOutSupabase()
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            
            if let error = error {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Account & Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func signIn() {
        signingIn = true
        error = nil
        Task {
            if let idToken = await SupabaseGoogleAuthHelper.signIn() {
                let ok = await SupabaseSync.shared.signInWithGoogle(idToken: idToken)
                if ok {
                    await model.syncWithSupabase()
                } else {
                    error = "Sign-in failed. Please try again."
                }
            } else {
                error = "Could not obtain Google ID token."
            }
            signingIn = false
        }
    }

    private func sync() {
        syncing = true
        error = nil
        Task {
            await model.syncWithSupabase()
            syncing = false
        }
    }

    private func restore() {
        restoring = true
        error = nil
        Task {
            await model.restoreFromCloud()
            restoring = false
        }
    }
}

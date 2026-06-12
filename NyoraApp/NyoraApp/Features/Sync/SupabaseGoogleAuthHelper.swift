import Foundation
import GoogleSignIn
import SwiftUI

enum SupabaseGoogleAuthHelper {
    
    enum SignInResult {
        case success(String)
        case failure(String)
    }
    
    @MainActor
    static func signInVerbose() async -> SignInResult {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController else {
            return .failure("Critical: Could not find a valid window to show sign-in.")
        }
        
        let clientID = "181067068545-9jkcbv6cb552jvmn6o3rdk87m2195g7n.apps.googleusercontent.com"
        let serverClientID = "181067068545-4jkfesn716ucqbuhcbtvdtlqfg3ar38u.apps.googleusercontent.com"
        let config = GIDConfiguration(clientID: clientID, serverClientID: serverClientID)
        
        return await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.configuration = config
            
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                if let error = error {
                    let nsError = error as NSError
                    if nsError.code == -5 {
                        continuation.resume(returning: .failure("Sign-in canceled"))
                    } else {
                        let msg = "\(error.localizedDescription) (Code: \(nsError.code))"
                        continuation.resume(returning: .failure(msg))
                    }
                    return
                }
                
                guard let result = result, let idToken = result.user.idToken?.tokenString else {
                    continuation.resume(returning: .failure("No ID Token returned"))
                    return
                }
                
                continuation.resume(returning: .success(idToken))
            }
        }
    }

    @MainActor
    static func signIn() async -> String? {
        let result = await signInVerbose()
        switch result {
        case .success(let token): return token
        case .failure: return nil
        }
    }
}

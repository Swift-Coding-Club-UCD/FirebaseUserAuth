//
//  AuthenticationManager.swift
//  FirebaseUserAuth
//
//  Adapted from UserAuthentication by David Estrella.
//  Modified to use Firebase Authentication.
//

import Foundation
import Observation
import AuthenticationServices
import CryptoKit
import FirebaseAuth

@Observable
@MainActor
class AuthenticationManager {
    var currentUser: AppUser?
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    // For Apple Sign In
    private var currentNonce: String?

    // Firebase auth state listener handle (nonisolated so deinit can access it)
    nonisolated(unsafe) private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenToAuthState()
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Firebase Auth State Listener

    /// Listens for Firebase auth state changes and updates the published properties.
    private func listenToAuthState() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            if let firebaseUser {
                self.currentUser = self.mapFirebaseUser(firebaseUser)
                self.isAuthenticated = true
            } else {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }

    /// Maps a Firebase `User` to the app's `AppUser` model.
    private func mapFirebaseUser(_ firebaseUser: FirebaseAuth.User) -> AppUser {
        let provider: AuthProvider
        // Determine auth provider from the first provider data entry
        if let providerID = firebaseUser.providerData.first?.providerID {
            switch providerID {
            case "apple.com":
                provider = .apple
            case "google.com":
                provider = .google
            default:
                provider = .email
            }
        } else {
            provider = .email
        }

        return AppUser(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            authProvider: provider
        )
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }

    // MARK: - Apple Sign In

    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    errorMessage = "Invalid state: missing nonce."
                    isLoading = false
                    return
                }
                guard let appleIDToken = appleIDCredential.identityToken,
                      let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    errorMessage = "Unable to fetch identity token."
                    isLoading = false
                    return
                }

                // Build Firebase credential from Apple token
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )

                Task {
                    do {
                        try await Auth.auth().signIn(with: credential)
                        // Auth state listener will update currentUser
                    } catch {
                        errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                    }
                    isLoading = false
                }
            }
        case .failure(let error):
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                // User canceled
            } else {
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        errorMessage = nil

        do {
            // Get credential first — the Google SDK presents its own UI,
            // so we must not show the loading overlay yet.
            let credential = try await GoogleSignInHelper.shared.signIn()

            // Now that the Google sheet has dismissed, show the loading indicator
            // while we complete the Firebase sign-in.
            isLoading = true
            try await Auth.auth().signIn(with: credential)
            // Auth state listener will update currentUser
        } catch {
            errorMessage = "Google Sign In failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Email/Password Sign Up (Firebase)

    func signUpWithEmail(email: String, password: String, displayName: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return false
        }

        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your name"
            isLoading = false
            return false
        }

        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)

            // Update the user's display name in Firebase
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            // Reload the user so the auth state listener picks up the display name
            try await authResult.user.reload()

            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Email/Password Sign In (Firebase)

    func signInWithEmail(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            isLoading = false
            return false
        }

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            // Auth state listener will update currentUser
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Helpers

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

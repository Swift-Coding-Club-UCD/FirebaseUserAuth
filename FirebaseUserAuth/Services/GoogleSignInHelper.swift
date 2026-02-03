//
//  GoogleSignInHelper.swift
//  FirebaseUserAuth
//
//  Adapted from UserAuthentication by David Estrella.
//
//  NOTE: This file contains the integration pattern for Google Sign-In with Firebase.
//  To enable Google Sign-In, you need to:
//  1. Add the GoogleSignIn package to your project
//  2. Configure your Google Cloud Console project
//

import Foundation
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth
import FirebaseCore

// MARK: - Google Sign-In + Firebase Integration Guide
/*
 To integrate Google Sign-In with Firebase Authentication:

 1. Add GoogleSignIn-iOS package:
    - In Xcode: File -> Add Package Dependencies
    - URL: https://github.com/google/GoogleSignIn-iOS
    - Add GoogleSignIn and GoogleSignInSwift products

 2. Firebase Console Setup:
    - Go to Firebase Console -> Authentication -> Sign-in method
    - Enable the Google provider
    - Copy the Web client ID from the provider config

 3. Configure Google Cloud Console:
    - The Firebase project auto-creates a Google Cloud project
    - Ensure your iOS bundle ID is registered

 4. Add URL Scheme:
    - Open your project's Info.plist
    - Add URL Types with your reversed client ID from GoogleService-Info.plist
*/

// MARK: - Google Sign-In Helper Implementation

@MainActor
class GoogleSignInHelper {
    static let shared = GoogleSignInHelper()

    func signIn() async throws -> AuthCredential {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw GoogleSignInError.noClientID
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw GoogleSignInError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleSignInError.noIDToken
        }

        // Create a Firebase credential from the Google ID token
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        return credential
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}

enum GoogleSignInError: LocalizedError {
    case noClientID
    case noRootViewController
    case noIDToken

    var errorDescription: String? {
        switch self {
        case .noClientID:
            return "Unable to find Firebase client ID"
        case .noRootViewController:
            return "Unable to find root view controller"
        case .noIDToken:
            return "Unable to get ID token from Google"
        }
    }
}

// MARK: - SwiftUI Google Sign-In Button (Placeholder)

/// A placeholder Google Sign-In button for demonstration purposes.
/// Replace with GoogleSignInButton from GoogleSignInSwift after adding the package.
struct GoogleSignInButtonView: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)

                Text("Sign in with Google")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.systemBackground))
            .foregroundStyle(.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }
}

#Preview {
    GoogleSignInButtonView(action: {
        print("Google Sign In tapped")
    })
    .padding()
}

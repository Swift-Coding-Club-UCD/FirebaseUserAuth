//
//  AuthenticationView.swift
//  FirebaseUserAuth
//
//  Adapted from UserAuthentication by David Estrella.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @Environment(AuthenticationManager.self) var authManager
    @State private var showEmailSignIn = false
    @State private var showEmailSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // App Logo/Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.blue)

                    Text("Welcome")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Sign-in Options
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton(
                        onRequest: { request in
                            authManager.handleAppleSignInRequest(request)
                        },
                        onCompletion: { result in
                            Task { @MainActor in
                                authManager.handleAppleSignInCompletion(result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)

                    // Google Sign In
                    Button {
                        Task {
                            await authManager.signInWithGoogle()
                        }
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

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)

                        Text("or")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)

                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)

                    // Email Sign In
                    Button {
                        showEmailSignIn = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)

                            Text("Sign in with Email")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }

                    // Sign Up Link
                    Button {
                        showEmailSignUp = true
                    } label: {
                        Text("Don't have an account? ")
                            .foregroundStyle(.secondary)
                        +
                        Text("Sign Up")
                            .foregroundStyle(.blue)
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .padding(.top, 8)
                }

                // Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationDestination(isPresented: $showEmailSignIn) {
                EmailSignInView()
            }
            .navigationDestination(isPresented: $showEmailSignUp) {
                EmailSignUpView()
            }
            .overlay {
                if authManager.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environment(AuthenticationManager())
}

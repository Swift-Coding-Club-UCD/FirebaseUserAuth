//
//  EmailSignInView.swift
//  FirebaseUserAuth
//
//  Adapted from UserAuthentication by David Estrella.
//

import SwiftUI

struct EmailSignInView: View {
    @Environment(AuthenticationManager.self) var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.blue)

                Text("Sign In")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Enter your email and password")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)

            Spacer()

            // Form Fields
            VStack(spacing: 16) {
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Enter your email", text: $email)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                }

                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit {
                            signIn()
                        }
                }
            }

            // Error Message
            if let errorMessage = authManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Sign In Button
            Button {
                signIn()
            } label: {
                Text("Sign In")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .disabled(!isFormValid || authManager.isLoading)

            Spacer()
        }
        .padding(.horizontal, 24)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
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
        .onAppear {
            authManager.errorMessage = nil
        }
    }

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    private func signIn() {
        focusedField = nil
        Task {
            let success = await authManager.signInWithEmail(email: email, password: password)
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        EmailSignInView()
            .environment(AuthenticationManager())
    }
}

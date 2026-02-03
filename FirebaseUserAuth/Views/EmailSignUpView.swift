//
//  EmailSignUpView.swift
//  FirebaseUserAuth
//
//  Adapted from UserAuthentication by David Estrella.
//

import SwiftUI

struct EmailSignUpView: View {
    @Environment(AuthenticationManager.self) var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case name, email, password, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.blue)

                    Text("Create Account")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Sign up to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Form Fields
                VStack(spacing: 16) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Enter your name", text: $displayName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .textContentType(.name)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .email
                            }
                    }

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
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .confirmPassword
                            }

                        if !password.isEmpty && password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        SecureField("Confirm your password", text: $confirmPassword)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.go)
                            .onSubmit {
                                signUp()
                            }

                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundStyle(.red)
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

                // Sign Up Button
                Button {
                    signUp()
                } label: {
                    Text("Create Account")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
                .disabled(!isFormValid || authManager.isLoading)
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
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
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }

    private func signUp() {
        focusedField = nil
        Task {
            let success = await authManager.signUpWithEmail(
                email: email,
                password: password,
                displayName: displayName
            )
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        EmailSignUpView()
            .environment(AuthenticationManager())
    }
}

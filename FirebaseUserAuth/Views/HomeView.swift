//
//  HomeView.swift
//  FirebaseUserAuth
//
//  Adapted from UserAuthentication by David Estrella.
//

import SwiftUI

struct HomeView: View {
    @Environment(AuthenticationManager.self) var authManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // User Profile Section
                VStack(spacing: 16) {
                    // Profile Image
                    if let photoURL = authManager.currentUser?.photoURL {
                        AsyncImage(url: photoURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            case .failure:
                                defaultProfileImage
                            @unknown default:
                                defaultProfileImage
                            }
                        }
                    } else {
                        defaultProfileImage
                    }

                    // User Info
                    VStack(spacing: 8) {
                        if let displayName = authManager.currentUser?.displayName {
                            Text(displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        if let email = authManager.currentUser?.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Auth Provider Badge
                        if let provider = authManager.currentUser?.authProvider {
                            HStack(spacing: 6) {
                                providerIcon(for: provider)
                                    .font(.caption)
                                Text("Signed in with \(providerName(for: provider))")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.top, 4)
                        }
                    }
                }

                Spacer()

                // User Details Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Details")
                        .font(.headline)

                    VStack(spacing: 12) {
                        DetailRow(
                            icon: "person.fill",
                            title: "User ID",
                            value: authManager.currentUser?.id ?? "N/A"
                        )

                        Divider()

                        DetailRow(
                            icon: "envelope.fill",
                            title: "Email",
                            value: authManager.currentUser?.email ?? "Not provided"
                        )

                        Divider()

                        DetailRow(
                            icon: "shield.fill",
                            title: "Auth Provider",
                            value: providerName(for: authManager.currentUser?.authProvider ?? .email)
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()

                // Sign Out Button
                Button(role: .destructive) {
                    authManager.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .foregroundStyle(.red)
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundStyle(.blue)
    }

    @ViewBuilder
    private func providerIcon(for provider: AuthProvider) -> some View {
        switch provider {
        case .apple:
            Image(systemName: "apple.logo")
        case .google:
            Image(systemName: "g.circle.fill")
        case .email:
            Image(systemName: "envelope.fill")
        }
    }

    private func providerName(for provider: AuthProvider) -> String {
        switch provider {
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        case .email:
            return "Email"
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.subheadline)
    }
}

#Preview {
    HomeView()
        .environment(AuthenticationManager())
}

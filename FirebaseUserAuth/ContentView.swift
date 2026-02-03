//
//  ContentView.swift
//  FirebaseUserAuth
//
//  Created by David Estrella on 2/2/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthenticationManager.self) var authManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                HomeView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environment(AuthenticationManager())
}

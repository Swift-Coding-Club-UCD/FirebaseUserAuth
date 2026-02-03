//
//  FirebaseUserAuthApp.swift
//  FirebaseUserAuth
//
//  Created by David Estrella on 2/2/26.
//

import SwiftUI
import FirebaseCore

@main
struct FirebaseUserAuthApp: App {
    @State private var authManager: AuthenticationManager

    init() {
        FirebaseApp.configure()
        _authManager = State(initialValue: AuthenticationManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
    }
}

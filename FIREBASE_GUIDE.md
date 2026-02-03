# Firebase Authentication Guide - FirebaseUserAuth

## What is Firebase Authentication?

Firebase Authentication is a backend service provided by Google that handles user identity. Instead of building your own server to store emails, passwords, and sessions, Firebase manages all of that for you. Your app communicates directly with Firebase's servers through the SDK, and Firebase returns secure tokens that represent the signed-in user.

The original `UserAuthentication` project stored user credentials locally in `UserDefaults` with manual SHA256 hashing. This Firebase version replaces all of that with Firebase Auth, which means:

- Passwords are never stored on-device or hashed by your code
- User accounts persist across devices (not just the local app)
- Firebase handles password security, rate limiting, and account recovery
- You get a centralized dashboard to manage users

## How Firebase Fits Into This Project

### Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                   SwiftUI App                    │
│                                                  │
│  ┌─────────────┐    ┌────────────────────────┐  │
│  │ ContentView  │───▶│  AuthenticationManager  │  │
│  └─────────────┘    └───────────┬────────────┘  │
│                                 │                │
│  ┌──────────────────┐          │                │
│  │ AuthenticationView│──────────┤                │
│  │ EmailSignInView   │          │                │
│  │ EmailSignUpView   │          │                │
│  │ HomeView          │          │                │
│  └──────────────────┘          │                │
└─────────────────────────────────┼────────────────┘
                                  │ Firebase SDK
                                  ▼
                    ┌─────────────────────────┐
                    │   Firebase Auth Service   │
                    │   (Google's servers)      │
                    │                           │
                    │  • Stores user accounts   │
                    │  • Hashes passwords       │
                    │  • Issues ID tokens       │
                    │  • Manages sessions       │
                    └─────────────────────────┘
```

### What Changed From the Original

| Component | Original (UserAuthentication) | Firebase Version |
|-----------|-------------------------------|------------------|
| **Sign Up** | `UserDefaults` + manual SHA256 hash | `Auth.auth().createUser(withEmail:password:)` |
| **Sign In** | Compare hashed password from `UserDefaults` | `Auth.auth().signIn(withEmail:password:)` |
| **Sign Out** | Remove key from `UserDefaults` | `Auth.auth().signOut()` |
| **Session** | Manually saved/loaded from `UserDefaults` | Firebase auth state listener fires automatically |
| **Apple Sign-In** | Stored credential locally | Apple token passed to Firebase as `OAuthProvider.appleCredential()` |
| **User Model** | Custom `User` stored locally | `FirebaseAuth.User` mapped to `AppUser` |
| **Password Storage** | SHA256 hash in `UserDefaults` | Handled entirely by Firebase (never touches your code) |

### Key Firebase Concepts

**`FirebaseApp.configure()`** - Called once at app launch in `FirebaseUserAuthApp.swift`. This reads `GoogleService-Info.plist` and initializes the Firebase SDK.

**`Auth.auth()`** - The singleton entry point for all authentication operations. Every sign-in, sign-up, and sign-out call goes through this object.

**Auth State Listener** - Instead of manually tracking login state, Firebase provides a listener that fires whenever the user signs in or out:

```swift
Auth.auth().addStateDidChangeListener { auth, user in
    if let user {
        // User is signed in
    } else {
        // User is signed out
    }
}
```

This is what `AuthenticationManager` uses to keep `isAuthenticated` and `currentUser` in sync.

**`Auth.auth().createUser(withEmail:password:)`** - Creates a new account on Firebase's servers. Firebase stores the password securely (bcrypt-hashed on their end). If the email is already taken, it returns an error.

**`Auth.auth().signIn(withEmail:password:)`** - Validates credentials against Firebase's servers. On success, the auth state listener fires and the user object becomes available.

**`OAuthProvider.appleCredential()`** - Converts an Apple Sign-In token into a Firebase credential, letting Firebase link the Apple identity to a Firebase user account.

## Setup Instructions

### Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Name your project (e.g., "FirebaseUserAuth")
4. Optionally enable Google Analytics
5. Click "Create project"

### Step 2: Register Your iOS App

1. In the Firebase Console, click the iOS+ icon to add an iOS app
2. Enter your bundle identifier: open `FirebaseUserAuth.xcodeproj` and find the bundle ID in the target's General tab
3. Download the `GoogleService-Info.plist` file
4. Drag `GoogleService-Info.plist` into your Xcode project root (make sure "Copy items if needed" is checked and it's added to the FirebaseUserAuth target)

### Step 3: Add the Firebase SDK via Swift Package Manager

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter the URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version **11.0.0** or later
4. Add these products to your target:
   - `FirebaseAuth`
   - `FirebaseCore`

### Step 4: Enable Authentication Methods in Firebase Console

1. In the Firebase Console, go to **Authentication > Sign-in method**
2. Enable **Email/Password**
3. Enable **Apple** (requires Apple Developer Program membership)
4. Optionally enable **Google** (requires additional setup — see below)

### Step 5: Add New Source Files to the Xcode Target

The new files (`Models/User.swift`, `Services/AuthenticationManager.swift`, `Services/GoogleSignInHelper.swift`, and all files in `Views/`) must be added to the Xcode project's build target:

1. In Xcode, right-click the `FirebaseUserAuth` group in the navigator
2. Select **Add Files to "FirebaseUserAuth"**
3. Navigate to and select the `Models`, `Services`, and `Views` folders
4. Make sure "Create groups" is selected and the `FirebaseUserAuth` target is checked
5. Click "Add"

### Step 6 (Optional): Google Sign-In Setup

1. Add the GoogleSignIn-iOS package: `https://github.com/google/GoogleSignIn-iOS`
2. In the Firebase Console under Authentication > Sign-in method > Google, enable it and note the Web client ID
3. Add a URL scheme to your Info.plist using the reversed client ID from `GoogleService-Info.plist`. The `REVERSED_CLIENT_ID` key in that plist will look something like:
   ```
   com.googleusercontent.apps.392870087646-abcdef1234567890abcdef1234567890
   ```
   Copy that full value and add it as a new URL scheme under **URL Types** in your Info.plist.
4. Uncomment the implementation in `GoogleSignInHelper.swift`
5. Update `AuthenticationManager.signInWithGoogle()` to use the helper

### Step 7 (Optional): Apple Sign-In Setup

1. In your Apple Developer account, enable "Sign in with Apple" for your App ID
2. In Xcode, go to **Signing & Capabilities > + Capability > Sign in with Apple**
3. The code in `AuthenticationManager` already handles creating the Firebase credential from the Apple token

## File Structure

```
FirebaseUserAuth/
├── FirebaseUserAuthApp.swift          # App entry — calls FirebaseApp.configure()
├── ContentView.swift                  # Routes to auth or home based on login state
├── Models/
│   └── User.swift                     # AppUser model + AuthProvider enum
├── Services/
│   ├── AuthenticationManager.swift    # All Firebase Auth logic lives here
│   └── GoogleSignInHelper.swift       # Google Sign-In integration guide + placeholder button
├── Views/
│   ├── AuthenticationView.swift       # Main sign-in screen (Apple, Google, Email buttons)
│   ├── EmailSignInView.swift          # Email + password sign-in form
│   ├── EmailSignUpView.swift          # Email registration form
│   └── HomeView.swift                 # Signed-in profile screen with sign-out
└── GoogleService-Info.plist           # (You add this from Firebase Console)
```

## How the Auth Flow Works at Runtime

1. App launches → `FirebaseApp.configure()` initializes the SDK
2. `AuthenticationManager.init()` registers an auth state listener
3. If Firebase has a cached session, the listener fires with the existing user → app shows `HomeView`
4. If no session exists, `isAuthenticated` stays `false` → app shows `AuthenticationView`
5. User taps a sign-in method:
   - **Email**: calls `Auth.auth().signIn(withEmail:password:)` or `Auth.auth().createUser(withEmail:password:)`
   - **Apple**: system sheet appears, token is passed to `Auth.auth().signIn(with: appleCredential)`
   - **Google**: (after SDK setup) Google sheet appears, token is passed to `Auth.auth().signIn(with: googleCredential)`
6. On success, the auth state listener fires → `currentUser` and `isAuthenticated` update → SwiftUI re-renders to show `HomeView`
7. User taps "Sign Out" → `Auth.auth().signOut()` → listener fires with `nil` → back to `AuthenticationView`

## Firebase Console: Managing Users

After users sign up, you can see and manage them in the Firebase Console under **Authentication > Users**. From there you can:

- View all registered users
- Disable or delete accounts
- Reset passwords
- See which provider each user signed in with
- View the unique UID Firebase assigned to each user

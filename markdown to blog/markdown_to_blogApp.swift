//
//  markdown_to_blogApp.swift
//  markdown to blog
//
//  Created by Prachi Heda on 3/22/25.
//

import SwiftUI
struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("New Post", systemImage: "plus")
                }
            
            PostListView()
                .tabItem {
                    Label("Edit Posts", systemImage: "pencil")
                }
        }
//        .onAppear {
//            saveGitHubToken("some token")
//            // Once it's stored, you can remove this line from your code.
//        }
        
    }
}

@main
struct markdown_to_blogApp: App {
    var body: some Scene {
            WindowGroup {
                MainView()
            }
        }
}

#Preview {
    MainView()
}

func saveGitHubToken(_ token: String) {
    guard let tokenData = token.data(using: .utf8) else { return }
    
    // 1. Define a search query to see if the item already exists
    let searchQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "GitHubToken",
        kSecAttrAccount as String: "prachiheda",
        kSecAttrSynchronizable as String: kCFBooleanTrue!,
        kSecUseDataProtectionKeychain as String: true // ✅ iOS 10+ Data Protection
    ]
    
    // 2. Check if an item already exists in the Keychain
    let status = SecItemCopyMatching(searchQuery as CFDictionary, nil)
    
    // 3. If the item already exists, update it; otherwise, add it as a new entry
    if status == errSecSuccess {
        // Update the existing Keychain item
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: tokenData
        ]
        
        let updateStatus = SecItemUpdate(searchQuery as CFDictionary, attributesToUpdate as CFDictionary)
        if updateStatus != errSecSuccess {
            print("Failed to update token in Keychain: \(updateStatus)")
        }
    } else if status == errSecItemNotFound {
        // Add a new Keychain item
        var newItem = searchQuery
        newItem[kSecValueData as String] = tokenData
        
        let addStatus = SecItemAdd(newItem as CFDictionary, nil)
        if addStatus != errSecSuccess {
            print("Failed to add token to Keychain: \(addStatus)")
        }
    } else {
        // Some other error occurred
        print("Failed to search for Keychain item: \(status)")
    }
}

import SwiftUI
import WebKit

struct EditPostView: View {
    let fileName: String
    @State private var content = ""
    @State private var sha = ""
    @State private var statusMessage = ""
    
    // Show/hide alert before updating
    @State private var showingConfirmationAlert = false
    // Toggle between raw editing and preview
    @State private var showingPreview = false

    var body: some View {
        NavigationView {
            Group {
                if !showingPreview {
                    // RAW MARKDOWN EDITOR
                    TextEditor(text: $content)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // MARKDOWN PREVIEW (via WebView + Showdown)
                    MarkdownWebView(markdownText: content)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(fileName)
            // .navigationBarTitleDisplayMode(.inline) // If you want a smaller title
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Toggle Preview
                    Button {
                        showingPreview.toggle()
                    } label: {
                        Image(systemName: showingPreview ? "eye.slash" : "eye")
                    }
                    
                    // Update Post
                    Button("Update Post") {
                        showingConfirmationAlert = true
                    }
                }
            }
            .alert("Are you sure you want to update this post?",
                   isPresented: $showingConfirmationAlert
            ) {
                Button("Yes") {
                    Task {
                        await updatePost()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will update \(fileName) on GitHub.")
            }
            .onAppear {
                Task {
                    await loadPost()
                }
            }
        }
    }
    
    // MARK: - Keychain Token Retrieval
    func getGitHubToken() -> String? {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "GitHubToken",
            kSecAttrAccount as String: "prachiheda",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,
            kSecUseDataProtectionKeychain as String: true
        ]
        
        var dataTypeRef: AnyObject? = nil
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let tokenString = String(data: data, encoding: .utf8) {
            return tokenString
        } else {
            print("Failed to retrieve token from Keychain: \(status)")
            return nil
        }
    }
    
    // MARK: - Load Post from GitHub
    func loadPost() async {
        guard let token = getGitHubToken() else {
            statusMessage = "❌ No token found in Keychain."
            return
        }
        
        let repo = "prachiheda/prachiblogs"
        let path = "content/posts/\(fileName)"
        
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)") else {
            statusMessage = "❌ Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(GitHubFileContent.self, from: data)
            
            // Clean up the Base64 string before decoding
            let cleanedBase64 = decoded.content
                .replacingOccurrences(of: "\n", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let decodedData = Data(base64Encoded: cleanedBase64),
               let decodedString = String(data: decodedData, encoding: .utf8) {
                content = decodedString
                sha = decoded.sha
            } else {
                statusMessage = "❌ Failed to decode file content."
            }
        } catch {
            statusMessage = "❌ Failed to load content: \(error.localizedDescription)"
        }
    }

    // MARK: - Update Post on GitHub
    func updatePost() async {
        guard let token = getGitHubToken() else {
            statusMessage = "❌ No token found in Keychain."
            return
        }
        
        let repo = "prachiheda/prachiblogs"
        let path = "content/posts/\(fileName)"
        
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)") else {
            statusMessage = "❌ Invalid URL"
            return
        }
        
        // Convert edited text to Base64
        let contentBase64 = content.data(using: .utf8)!.base64EncodedString()
        let payload: [String: Any] = [
            "message": "Updated post from iOS app",
            "content": contentBase64,
            "sha": sha
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                statusMessage = "✅ \(fileName) updated!"
            } else {
                statusMessage = "❌ Failed to update post."
            }
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Model for Decoding GitHub File Content
struct GitHubFileContent: Codable {
    let content: String
    let sha: String
}

import SwiftUI

struct ContentView: View {
    @State private var markdownText = ""
    @State private var fileName = "new-post"
    @State private var statusMessage = ""
    
    @State private var showingConfirmationAlert = false
    @State private var showingPreview = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filename field
                TextField("File Name (without .md)", text: $fileName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Toggle between a raw TextEditor and WebView-based Markdown preview
                if !showingPreview {
                    TextEditor(text: $markdownText)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Our new WebView with Showdown
                    MarkdownWebView(markdownText: markdownText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Toggle preview mode
                    Button {
                        showingPreview.toggle()
                    } label: {
                        Image(systemName: showingPreview ? "eye.slash" : "eye")
                    }

                    // Push to GitHub
                    Button("Push to GitHub") {
                        showingConfirmationAlert = true
                    }
                }
            }
            .alert("Are you sure you want to push to GitHub?",
                   isPresented: $showingConfirmationAlert
            ) {
                Button("Yes") {
                    Task {
                        await pushToGitHub(content: markdownText, fileName: fileName)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will publish \(fileName).md to the main branch.")
            }
            .onAppear {
                markdownText = generateMarkdownTemplate()
            }
        }
    }
    
    // Provide a default markdown template
    func generateMarkdownTemplate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        return """
        ---
        author: [Prachi Heda]
        date: \(today)
        draft: false
        title: YOUR TITLE HERE
        description: YOUR DESCRIPTION HERE
        summary: YOUR SUMMARY HERE
        ---

        # Heading Example

        Some **bold** text, some *italic* text.
        - List item 1
        - List item 2
        """
    }

    // Keychain retrieval
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
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            print("Failed to retrieve token from Keychain: \(status)")
            return nil
        }
    }
    
    // GitHub push (unchanged)
    func pushToGitHub(content: String, fileName: String) async {
        guard let token = getGitHubToken() else {
            statusMessage = "❌ No token found in Keychain."
            return
        }
        
        let repo = "prachiheda/prachiblogs"
        let path = "content/posts/\(fileName).md"
        
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)?branch=main") else {
            statusMessage = "❌ Invalid URL"
            return
        }
        
        let contentBase64 = content.data(using: .utf8)!.base64EncodedString()
        let payload: [String: Any] = [
            "message": "New post from iOS app",
            "content": contentBase64
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                statusMessage = "✅ \(fileName).md published!"
            } else {
                statusMessage = "❌ Failed to publish"
            }
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}

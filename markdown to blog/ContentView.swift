import SwiftUI

struct ContentView: View {
    @State private var markdownText = ""
    @State private var fileName = "new-post"
    @State private var statusMessage = ""

    var body: some View {
        VStack {
            // File Name Input
            TextField("File Name (without .md)", text: $fileName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Markdown Input
            TextEditor(text: $markdownText)
                .border(Color.gray, width: 1)
                .frame(height: 300)
                .padding()

            // Push Button
            Button("Push to GitHub") {
                Task {
                    await pushToGitHub(content: markdownText, fileName: fileName)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            // Status Message
            Text(statusMessage)
                .foregroundColor(.gray)
                .padding()
        }
        .padding()
        .onAppear {
            markdownText = generateMarkdownTemplate()
        }
    }

    // Generate markdown template with today's date
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
        """
    }
    
    func getGitHubToken() -> String? {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "GitHubToken",
            kSecAttrAccount as String: "prachiheda",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject? = nil
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        } else {
            print("Failed to retrieve token from Keychain: \(status)")
        }
        
        return nil
    }

    func pushToGitHub(content: String, fileName: String) async {
        guard let token = getGitHubToken() else {
                statusMessage = "❌ No token found in Keychain."
                return
            }
        let repo = "prachiheda/prachiblogs"
        let path = "content/posts/\(fileName).md"
        
        let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)?branch=main")!
        
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

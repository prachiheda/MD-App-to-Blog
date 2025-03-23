import SwiftUI

struct EditPostView: View {
    let fileName: String
    @State private var content = ""
    @State private var sha = ""
    @State private var statusMessage = ""

    var body: some View {
        VStack {
            TextEditor(text: $content)
                .border(Color.gray, width: 1)
                .frame(height: 300)
                .padding()
            
            Button("Update Post") {
                Task {
                    await updatePost()
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Text(statusMessage)
                .foregroundColor(.gray)
                .padding()
        }
        .padding()
        .navigationTitle(fileName)
        .onAppear {
            Task {
                await loadPost()
            }
        }
    }

    func loadPost() async {
        let token = "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"
        let repo = "prachiheda/prachiblogs"
        let path = "content/posts/\(fileName)"
        
        let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(GitHubFileContent.self, from: data)
            
            // ✅ Remove newlines and padding before decoding
            let cleanedBase64 = decoded.content
                .replacingOccurrences(of: "\n", with: "") // Remove newlines
                .trimmingCharacters(in: .whitespacesAndNewlines) // Trim padding characters

            if let decodedData = Data(base64Encoded: cleanedBase64) {
                content = String(data: decodedData, encoding: .utf8) ?? ""
                sha = decoded.sha // Save the SHA to update later
            } else {
                statusMessage = "❌ Failed to decode file content."
            }
        } catch {
            statusMessage = "❌ Failed to load content: \(error.localizedDescription)"
        }
    }

    func updatePost() async {
        let token = "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"
        let repo = "prachiheda/prachiblogs"
        let path = "content/posts/\(fileName)"
        
        let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!
        
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
                statusMessage = "❌ Failed to update post"
            }
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }
    }
}

struct GitHubFileContent: Codable {
    let content: String
    let sha: String
}

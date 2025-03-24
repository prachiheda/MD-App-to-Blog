import SwiftUI

struct PostListView: View {
    @State private var files: [String] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            List(files, id: \.self) { file in
                NavigationLink(destination: EditPostView(fileName: file)) {
                    Text(file)
                }
            }
            .navigationTitle("Blog Posts")
            .onAppear {
                Task {
                    await fetchPosts()
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }

    func fetchPosts() async {
        guard let token = getGitHubToken() else {
            return
        }
        let repo = "prachiheda/prachiblogs"
        let path = "content/posts"
        
        let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode([GitHubFile].self, from: data)
            files = decoded.map { $0.name }
            isLoading = false
        } catch {
            errorMessage = "Failed to load posts: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
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
}

struct GitHubFile: Codable {
    let name: String
}

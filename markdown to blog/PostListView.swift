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
        let token = "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"
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
}

struct GitHubFile: Codable {
    let name: String
}

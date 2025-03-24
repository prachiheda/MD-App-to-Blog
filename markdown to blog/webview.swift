import SwiftUI
import WebKit

struct MarkdownWebView: UIViewRepresentable {
    let markdownText: String
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 1) Clean the Markdown of front matter (for preview)
        let previewMarkdown = removeFrontMatter(from: markdownText)
        
        // 2) Load Showdown-based HTML
        let html = """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
            <script src="https://cdn.jsdelivr.net/npm/showdown/dist/showdown.min.js"></script>
            <style>
              body {
                font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, Arial, sans-serif;
                margin: 0;
                padding: 16px;
              }
              pre, code {
                background-color: #f4f4f4;
                padding: 2px 4px;
              }
            </style>
          </head>
          <body>
            <div id="content"></div>
            <script>
              var text      = \(jsonEscape(previewMarkdown));
              var converter = new showdown.Converter();
              var html      = converter.makeHtml(text);
              document.getElementById("content").innerHTML = html;
            </script>
          </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    // MARK: - Remove front matter from the top of the Markdown text
    private func removeFrontMatter(from markdown: String) -> String {
        // Split into lines
        var lines = markdown.components(separatedBy: .newlines)
        
        // If the first line is "---", find the next "---"
        if lines.first?.trimmingCharacters(in: .whitespaces) == "---" {
            // Drop the first line, and find where the next "---" appears
            // Note: dropFirst() returns a subsequence, so we need an index search
            if let secondFenceIndex = lines.dropFirst().firstIndex(where: {
                $0.trimmingCharacters(in: .whitespaces) == "---"
            }) {
                // Remove all lines up to and including that second "---"
                lines.removeSubrange(...secondFenceIndex)
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// Safely escape your Markdown so it can be injected into JavaScript
    private func jsonEscape(_ string: String) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: [string]),
           let jsonArrayString = String(data: data, encoding: .utf8),
           jsonArrayString.count >= 2 {
            // Original result looks like: ["some text\n..."]
            // We drop leading '[' and trailing ']'
            return String(jsonArrayString.dropFirst().dropLast())
        }
        return "\"\""
    }
}

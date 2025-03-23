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


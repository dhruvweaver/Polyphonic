//
//  MainView.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/10/22.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            BasicView()
                .tabItem {
                    Label("Basic Sharing", systemImage: "music.note")
                }
            PlaylistView()
                .tabItem {
                    Label("Playlist Sharing", systemImage: "music.note.list")
                }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

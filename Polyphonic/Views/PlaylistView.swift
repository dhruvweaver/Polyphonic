//
//  PlaylistView.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/10/22.
//

import SwiftUI

struct PlaylistView: View {
    @State private var linkStr: String = ""
    @State private var isProcessing: Bool = false
    @State private var playlist: Playlist = Playlist(title: "nil", songs: [], creator: "nil")
    @State private var done: Bool = false
    @State private var songify: Song = Song(title: "Title and Registration", ISRC: "123", artists: ["Death Cab for Cutie"], album: "Transatlanticism", albumID: "123", explicit: false, trackNum: 3)
    
    var body: some View {
        NavigationView {
            VStack (alignment: .center) {
                HStack(alignment: .center) {
                    TextField("Press the paste button", text: $linkStr)
                        .textFieldStyle(.roundedBorder)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                        .padding([.leading, .top])
                    
                    Button(action: {
                        linkStr = ""
                    }) {
                        Image(systemName: "xmark")
                            .padding(.leading, 10)
                            .padding([.trailing, .top, .bottom])
                    }
                    .disabled(linkStr == "")
                    .padding(.top, 16)
                    .help("Clear")
                    
                    Button(action: {
                        if let pasteStr = UIPasteboard.general.string {
                            linkStr = pasteStr
                            hideKeyboard()
                        }
                    }) {
                        Image(systemName: "doc.on.clipboard")
                            .padding([.trailing, .top, .bottom])
                    }
                    .padding(.top, 16)
                    .help("Paste link from clipboard")
                }
                
                if (!isProcessing) {
                    Button("Process") {
                        Task {
                            hideKeyboard()
                            isProcessing = true
                            
                            let playlistData = PlaylistData()
                            playlist = await playlistData.processPlaylistItems(playlistLink: linkStr)
                            debugPrint(playlist.getImageURL())
                            
                            songify = Song(title: playlist.getTitle(), ISRC: "", artists: [playlist.getCreator()], album: "", albumID: "", explicit: true, trackNum: playlist.getSongs().count)
                            songify.setTranslatedImgURL(link: playlist.getImageURL().absoluteString)
                            
                            isProcessing = false
                            done = true
                        }
                    }
                    .disabled(linkStr == "")
                    .padding(6)
                    .cornerRadius(8)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.vertical, 6)
                }
                
                Text("Output Preview")
                    .font(.title2)
                    .fontWeight(.heavy)
                
                if (done) {
                    OutputPreviewView(song: songify, type: .playlist, url: "", forEditing: false)
                } else {
                    OutputPreviewView(song: songify, type: .playlist, url: "", forEditing: false)
                        .redacted(reason: .placeholder)
                }
            }
            .navigationTitle("Polyphonic")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
    }
}

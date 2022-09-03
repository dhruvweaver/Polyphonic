//
//  PlaylistImportView.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 8/18/22.
//

import SwiftUI

struct PlaylistImportView: View {
    var playlistForImport: Playlist!
    // TODO: remove these variables. Not needed anymore with new data var
    @State private var translatedSongs: [Song] = []
    @State private var translatedSongURLs: [String] = []
    @State private var translatedAltSongs: [[Song]] = []
    @State private var translatedAltURLs: [[String]] = []
    
    @State private var data: [(Song, String, [Song], [String])] = []
    @State private var editViews: [EditResultsView] = []
    @State private var editIndex: Int = 0
    
    @State private var hasTranslatedSongs: Bool = false
    @State private var isLoading: Bool = false
    @State private var currentIndex = 0.0
    @State private var showingEditSheet = false
    @State private var platform: Platform = .unknown
    
    var body: some View {
        if (hasTranslatedSongs) {
            ScrollView {
                VStack(alignment: .center) {
                    Text("\(playlistForImport.getTitle())")
                        .font(.title)
                    Text("\(data.count) songs")
                        .font(.subheadline)
                    
                    if (data.count != playlistForImport.getSongs().count) {
                        Button("\(playlistForImport.getSongs().count - data.count) songs not found") {
                            
                        }
                    }
                    
                    Button("Import") {
                        let playlistData = PlaylistData()
                        Task {
                            await playlistData.importPlaylist(playlistPlatform: platform, playlistSongs: translatedSongs, title: playlistForImport.getTitle())
                        }
                    }
                    
                    if (playlistForImport.getSongs().count >= 1) {
                        let songs = translatedSongs
                        ForEach(0..<songs.count, id: \.self) { index in
                            HStack(alignment: .center) {
                                // TODO: send alt songs to output preview and edit from there
                                OutputPreviewView(song: data[index].0, type: .song, url: data[index].1, forEditing: false, forPlaylist: true, altSongs: data[index].2, altURLs: data[index].3)
                                
                                Button("Edit") {
                                    editIndex = index
                                    showingEditSheet.toggle()
                                    
                                    debugPrint(index)
                                }
                //                .disabled(isLoading)
                                .sheet(isPresented: $showingEditSheet) {
                                    editViews[editIndex]
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Import Playlist")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            VStack(alignment: .center) {
                Menu {
                    Button {
                        platform = .spotify
                    } label: {
                        Text("Spotify (not available yet)")
                        //                                Image(systemName: "arrow.up.circle")
                    }
                    Button {
                        platform = .appleMusic
                    } label: {
                        Text("Apple Music")
                    }
                } label: {
                    Text(platform == .unknown ? "Choose your platform" : (platform == .spotify ? "Spotify" : "Apple Music"))
                    Image(systemName: "chevron.down")
                }
                .padding(.bottom, 60.0)
                
                if (!isLoading) {
                    Button("Translate songs from \"\(playlistForImport.getTitle())\"\nto \(platform == .spotify ? "Spotify" : (platform == .appleMusic ? "Apple Music" : ""))") {
                        
                        Task {
                            // get/check permission to access streaming service
                            // TODO: add Spotify import
                            await getAppleMusicPermission()
                            
                            let songs: [Song] = playlistForImport.getSongs()
                            
                            isLoading = true
                            let musicData = MusicData()
                            
                            for i in songs {
                                let results = await musicData.translateDataBySongObj(songObj: i, targetPlatform: platform)
                                if let song = results.1 {
                                    translatedSongs.append(song)
                                    translatedSongURLs.append(song.getTranslatedURLasString())
                                    translatedAltSongs.append(results.3)
                                    translatedAltURLs.append(results.2)
                                    
                                    let tempData = (song, song.getTranslatedURLasString(), results.3, results.2)
                                    
                                    data.append(tempData)
                                }
                                
                                currentIndex += 1.0
                            }
                            
                            debugPrint(data.count)
                            for i in 0..<data.count {
                                debugPrint(i)
                                editViews.append(EditResultsView(song: $data[i].0, alts: data[i].2, altURLs: data[i].3, type: .song, linkOut: $data[i].1))
                                currentIndex += 1.0
                            }
                            
                            isLoading = false
                            hasTranslatedSongs = true
                        }
                    }
                    .disabled(platform == .unknown)
                } else {
                    ProgressView("Translating (\(Int(currentIndex))/\(playlistForImport.getSongs().count))...", value: currentIndex, total: Double(playlistForImport.getSongs().count))
                }
            }
            .navigationTitle("Import Playlist")
        }
        
        //            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlaylistImportView_Previews: PreviewProvider {
    static var previews: some View {
        let playlist: Playlist = Playlist(title: "Test", songs: [], creator: "10")
        PlaylistImportView(playlistForImport: playlist)
    }
}

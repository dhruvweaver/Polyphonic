//
//  ContentView.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/11/22.
//

import SwiftUI

struct BasicView: View {
    @State private var linkStr: String = ""
    @State private var linkOut: String = ""
    @State private var isLoading: Bool = false
    
    @State private var keySong: Song = Song(title: "Title and Registration", ISRC: "123", artists: ["Death Cab for Cutie"], album: "Transatlanticism", albumID: "123", explicit: false, trackNum: 3)
    @State private var type: MusicType = .song
    @State private var alts: [Song] = []
    @State private var altURLs: [String] = []
    
    @State private var showingEditSheet: Bool = false
    
    var body: some View {
        let musicData = MusicData()
        NavigationView {
            VStack(alignment: .center) {
                Text("Share songs and albums between Apple Music and Spotify")
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(width: 300.0)
                    .padding(.top, 40)
                
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
                
                if (!isLoading) {
                    Button("Translate") {
                        Task {
                            hideKeyboard()
                            isLoading = true
                            let results = await musicData.translateData(link: linkStr)
                            linkOut = results.0
                            if let song = results.1 {
                                keySong = song
                                type = results.2
                                alts = results.4
                                altURLs = results.3
                            }
                            isLoading = false
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
                
                HStack(alignment: .center) {
                    TextField("No output yet...", text: $linkOut)
                        .textFieldStyle(.roundedBorder)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                        .padding([.leading, .bottom])
                    
                    Button(action: {
                        UIPasteboard.general.string = linkOut
                    }) {
                        Image(systemName: "doc.on.doc")
                            .padding(.leading, 10)
                            .padding([.trailing, .top, .bottom])
                    }
                    .disabled(isLoading || !validURL())
                    .padding(.bottom, 16)
                    .help("Copy link to clipboard")
                    
                    Button(action: {
                        if let urlShare = URL(string: linkOut) {
                            let shareActivity = UIActivityViewController(activityItems: [urlShare], applicationActivities: nil)
                            
                            let scenes = UIApplication.shared.connectedScenes
                            let windowScene = scenes.first as? UIWindowScene
                            
                            windowScene?.keyWindow?.rootViewController?.present(shareActivity, animated: true, completion: nil)
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .padding([.trailing, .top, .bottom])
                    }
                    .disabled(isLoading || !validURL())
                    .padding(.bottom, 16)
                    .help("Share link")
                }
                
                Text("Output Preview")
                    .font(.title2)
                    .fontWeight(.heavy)
                
                if (validURL()) {
                    OutputPreviewView(song: keySong, type: type, url: linkOut, forEditing: false, forPlaylist: false, altSongs: alts, altURLs: altURLs)
                } else {
                    OutputPreviewView(song: Song(title: "abcdefghijklmnopqr", ISRC: "nil", artists: ["abcdefghijklmno"], album: "abcdefghij", albumID: "nil", explicit: false, trackNum: 0), type: .song, url: linkOut, forEditing: false, forPlaylist: false, altSongs: alts, altURLs: altURLs)
                        .redacted(reason: .placeholder)
                }
                
                Button("Edit") {
                    showingEditSheet.toggle()
                }
                .disabled(isLoading || !validURL())
                .sheet(isPresented: $showingEditSheet) {
                    EditResultsView(song: $keySong, alts: alts, altURLs: altURLs, type: type, linkOut: $linkOut)
                }
            }
            .navigationTitle("Polyphonic")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .gesture(DragGesture().onChanged{_ in UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)})
    }
    
    private func validURL() -> Bool {
        if let _ = URL(string: linkOut) {
            return true
        } else {
            return false
        }
    }
}

extension View {
    /**
     Simple function to hide the keyboard.
     */
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BasicView()
    }
}

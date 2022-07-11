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
    @State private var keySong: Song? = nil
    @State private var type: MusicType = .song
    //    @State private var musicData = MusicData()
    
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
//                        hideKeyboard()
                        Task {
                            isLoading = true
                            let results = await musicData.translateData(link: linkStr)
                            linkOut = results.0
                            if let song = results.1 {
                                keySong = song
                                type = results.2
                                debugPrint(type)
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
                    OutputPreviewView(song: keySong!, type: type)
                } else {
                    OutputPreviewView(song: Song(title: "abcdefghijklmnopqr", ISRC: "nil", artists: ["abcdefghijklmno"], album: "abcdefghij", albumID: "nil", explicit: false, trackNum: 0), type: .song)
                        .redacted(reason: .placeholder)
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
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BasicView()
    }
}

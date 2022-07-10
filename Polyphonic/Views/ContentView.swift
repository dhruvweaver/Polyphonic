//
//  ContentView.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/11/22.
//

import SwiftUI

struct ContentView: View {
    @State private var linkStr: String = ""
    @State private var linkOut: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        let songData = MusicData()
        NavigationView {
            VStack(alignment: .center) {
                Text("Paste a link from Apple Music or Spotify to get started")
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                HStack(alignment: .center) {
                    TextField("Input Link", text: $linkStr)
                        .textFieldStyle(.roundedBorder)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                        .padding([.leading, .top])
                    
                    Button(action: {
                        linkStr = ""
                    }) {
                        Image(systemName: "clear")
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
                            isLoading = true
                            linkOut = await songData.translateData(link: linkStr)
                            isLoading = false
                            hideKeyboard()
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
                    TextField("Translated Link", text: $linkOut)
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
            }
            .navigationTitle("Polyphonic")
        }
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
        ContentView()
    }
}

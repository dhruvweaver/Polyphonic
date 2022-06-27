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
        VStack(alignment: .center) {
            Text("Translate links between Apple Music and Spotify")
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            HStack(alignment: .center, spacing: 25.0) {
                Button("Paste Link") {
                    if let pasteStr = UIPasteboard.general.string {
                        linkStr = pasteStr
                        hideKeyboard()
                    }
                }
                Button("Clear Link") {
                    linkStr = ""
                }
            }
            
            HStack(alignment: .center) {
                TextField("Input Link", text: $linkStr)
                    .textFieldStyle(.roundedBorder)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                    .padding(.horizontal)
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
                .padding(.vertical, 2.0)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.vertical, 2.0)
            }
            
            HStack(alignment: .center) {
                TextField("Translated Link", text: $linkOut)
                    .textFieldStyle(.roundedBorder)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                    .padding(.horizontal)
            }
            
            Button("Copy Translated Link") {
                UIPasteboard.general.string = linkOut
            }
            .disabled(isLoading || !validURL())
            Button("Share Link") {
                if let urlShare = URL(string: linkOut) {
                    let shareActivity = UIActivityViewController(activityItems: [urlShare], applicationActivities: nil)
                    
                    let scenes = UIApplication.shared.connectedScenes
                    let windowScene = scenes.first as? UIWindowScene
                    
                    windowScene?.keyWindow?.rootViewController?.present(shareActivity, animated: true, completion: nil)
                }
            }
            .disabled(isLoading || !validURL())
            .padding(.top)
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

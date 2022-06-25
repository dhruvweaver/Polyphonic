//
//  ContentView.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/11/22.
//

import SwiftUI

struct ContentView: View {
    @Binding private var linkStr: String
    @State private var linkOut: String = ""
    @State private var isLoading: Bool = false
    
    init(shareLink: Binding<String>) {
        self._linkStr = shareLink
    }
    
    var body: some View {
        let songData = SongData()
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
            // will later hold text field
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
            Button("Share Link") {
                if let urlShare = URL(string: linkOut) {
                    
                    let AV = UIActivityViewController(activityItems: [urlShare], applicationActivities: nil)
                    
                    let scenes = UIApplication.shared.connectedScenes
                    let windowScene = scenes.first as? UIWindowScene
                    
                    windowScene?.keyWindow?.rootViewController?.present(AV, animated: true, completion: nil)
                }
            }
            .padding(.top)
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    @State static var blank = ""
    static var previews: some View {
        ContentView(shareLink: $blank)
    }
}

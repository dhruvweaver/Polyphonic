//
//  ContentView.swift
//  MusicLinkApp
//
//  Created by Dhruv Weaver on 6/11/22.
//

import SwiftUI

struct ContentView: View {
    @State private var linkStr: String = ""
    @State private var linkOut: String = ""
    @State private var isLoading: Bool = false
    var body: some View {
        let songData = SongData()
        VStack(alignment: .center) {
            Text("Translate links between Apple Music and Spotify")
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            Button("Clear Input Link") {
                linkStr = ""
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

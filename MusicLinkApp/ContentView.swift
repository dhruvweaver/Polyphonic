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
    var body: some View {
        let songData = SongData()
        VStack(alignment: .center) {
            Text("Translate links between Apple Music and Spotify")
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            Button("Clear") {
                linkStr = ""
                linkOut = ""
            }
            HStack(alignment: .center) {
                TextField("Input Link", text: $linkStr)
                    .textFieldStyle(.roundedBorder)
                    .border(Color.gray)
                    .padding(.horizontal)
            }
            Button("Translate") {
                Task {
                    linkOut = await songData.translateData(link: linkStr)
                }
            }
            // will later hold text field
            HStack(alignment: .center) {
                TextField("Translated Link", text: $linkOut)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .border(Color.gray)
                    .padding(.horizontal)
            }
            Button("Copy") {
                UIPasteboard.general.string = linkOut
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

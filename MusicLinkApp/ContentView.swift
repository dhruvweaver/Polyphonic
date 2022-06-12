//
//  ContentView.swift
//  MusicLinkApp
//
//  Created by Dhruv Weaver on 6/11/22.
//

import SwiftUI

struct ContentView: View {
    @State var linkStr: String = ""
    @State var linkOut: String = ""
    var body: some View {
        let songData = SongData()
        VStack(alignment: .center) {
            Button("Clear") {
                linkStr = ""
                linkOut = ""
            }
            HStack(alignment: .center) {
                TextField("Spotify Link", text: $linkStr)
                    .frame(width: 350)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .border(Color.gray)
                    .fixedSize(horizontal: true, vertical: false)
            }
            Button("Translate") {
                Task {
                    linkOut = await songData.translateData(link: linkStr)
                }
            }
            // will later hold text field
            HStack(alignment: .center) {
                TextField("Song Name", text: $linkOut)
                    .frame(width: 350)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .border(Color.gray)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  EditResultsView.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/11/22.
//

import SwiftUI

struct EditResultsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var song: Song
    let alts: [Song]
    let altURLs: [String]
    let type: MusicType
    var onDismiss: ((_ model: String, Song) -> Void)?
    @Binding var linkOut: String
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                if (alts.count > 1) {
                    ForEach(0..<alts.count, id: \.self) { index in
                        let currentAlt = alts[index]
                        if (type == .album && (cleanSpotifyText(title: currentAlt.getAlbum(), forSearching: false) == cleanSpotifyText(title: song.getAlbum(), forSearching: false)) && song.getTranslatedURLasString() != currentAlt.getTranslatedURLasString()) {
                            OutputPreviewView(song: currentAlt, type: type, url: altURLs[index])
                                .onTapGesture {
                                    linkOut = altURLs[index]
                                    song = currentAlt
                                    onDismiss?(linkOut, song)
                                    presentationMode.wrappedValue.dismiss()
                                }
                        } else if (type == .song && song.getTranslatedURLasString() != currentAlt.getTranslatedURLasString()) {
                            OutputPreviewView(song: currentAlt, type: type, url: altURLs[index])
                                .onTapGesture {
                                    linkOut = altURLs[index]
                                    song = currentAlt
                                    onDismiss?(linkOut, song)
                                    presentationMode.wrappedValue.dismiss()
                                }
                        }
                    
                    }
                } else {
                    Text("No alternatives to pick from")
                }
            }
        }
    }
}

struct EditResultsView_Previews: PreviewProvider {
    @State static var str = "test"
    @State static var alts: [Song] = [Song(title: "Title and Registration", ISRC: "123", artists: ["Death Cab for Cutie"], album: "Transatlanticism", albumID: "123", explicit: false, trackNum: 3), Song(title: "Roman Candles", ISRC: "123", artists: ["Death Cab for Cutie"], album: "Asphalt Meadows", albumID: "123", explicit: false, trackNum: 3)]
    static var previews: some View {
        EditResultsView(song: $alts[0], alts: alts, altURLs: ["one", "two"], type: .song, linkOut: $str)
    }
}

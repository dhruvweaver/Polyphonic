//
//  OutputPreviewView.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/10/22.
//

import SwiftUI

struct OutputPreviewView: View {
    var song: Song
    var type: MusicType
    var body: some View {
        let url = song.getTranslatedImgURL()
        let songTitle: String = song.getTitle()
        let albumTitle: String = song.getAlbum()
        let artistName: String = song.getArtists()[0]
        
        HStack(alignment: .center) {
            AsyncImage(
                url: url,
                content: { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(5)
                        .frame(maxWidth: 140, maxHeight: 140)
                        .padding(.leading, 20)
                        .padding(.trailing, 10)
                        .padding(.vertical, 10)
                        .shadow(radius: 4)
                }
                ,
                placeholder: {
                    ProgressView()
                        .padding(.leading, 80)
                        .padding(.trailing, 70)
//                        .padding(.vertical, 70)
                        .frame (minHeight: 65, maxHeight: 160)
                }
            )
            
            VStack(alignment: .leading) {
                if (type == .song) {
                    Text(songTitle)
                        .fontWeight(.bold)
                        .lineLimit(1)
                } else if (type == .album) {
                    Text("Album:")
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
                Text(albumTitle)
                    .lineLimit(1)
                Text(artistName)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(width: 180, alignment: .leading)
            .padding(.trailing, 30)
        }
    }
}

struct OutputPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = Song(title: "Title and Registration", ISRC: "123", artists: ["Death Cab for Cutie"], album: "Transatlanticism", albumID: "123", explicit: false, trackNum: 3)
        OutputPreviewView(song: sample, type: .song)
    }
}

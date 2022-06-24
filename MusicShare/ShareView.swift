//
//  File.swift
//  LinkShare
//
//  Created by Dhruv Weaver on 6/22/22.
//

import SwiftUI

struct ShareView: View {
    @State private var linkStr: String = "No link"
    @State private var linkOut: String = ""
    @State private var isLoading: Bool = false
    var body: some View {
        let songData = SongData()
        VStack(alignment: .center) {
            Text("Translate links between Apple Music and Spotify")
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            HStack(alignment: .center) {
                Text(linkStr)
            }
            if (!isLoading) {
                Button("Translate") {
                    Task {
                        isLoading = true
                        linkOut = await songData.translateData(link: linkStr)
                        isLoading = false
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

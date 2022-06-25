//
//  File.swift
//  LinkShare
//
//  Created by Dhruv Weaver on 6/22/22.
//

import SwiftUI

struct ShareView: View {
    @State var linkStr: String = ""
    @State private var linkOut: String = ""
    @State private var isLoading: Bool = false
    @State private var songData = SongData()
    var body: some View {
        VStack(alignment: .center) {
            if (isLoading) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.vertical, 2.0)
            }
            HStack(alignment: .center) {
                TextField("Input Link", text: $linkStr)
                    .textFieldStyle(.roundedBorder)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                    .padding(.horizontal)
            }.onAppear(perform: translate)
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
            if (isLoading) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.vertical, 2.0)
            } else {
//                Button("Share Link") {
//                    let urlShare = linkOut
//                    
//                    let AV = UIActivityViewController(activityItems: [urlShare], applicationActivities: nil)
//                    
//                    let scenes = UIApplication.shared.connectedScenes
//                    let windowScene = scenes.first as? UIWindowScene
//                    
//                    windowScene?.keyWindow?.rootViewController?.present(AV, animated: true, completion: nil)
//                }
//                .padding(.top)
            }
        }
    }
    
    private func translate() {
        Task {
            isLoading = true
            linkOut = await songData.translateData(link: linkStr)
            isLoading = false
        }
    }
}

struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        ShareView()
    }
}

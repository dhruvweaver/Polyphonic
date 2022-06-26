//
//  ShareLinkView.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/26/22.
//

import SwiftUI

struct ShareLinkView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding private var linkStr: String
    @State private var linkOut: String = ""
    @State private var isLoading: Bool = true
    private var songData = SongData()
    
    init(shareLink: Binding<String>) {
        self._linkStr = shareLink
    }
    
    private func translate() {
        Task {
            linkOut = await songData.translateData(link: linkStr)
            isLoading = false
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Translate links between Apple Music and Spotify")
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            
            HStack(alignment: .center) {
                TextField("Input Link", text: $linkStr)
                    .textFieldStyle(.roundedBorder)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                    .padding(.horizontal)
            }
            .onAppear(perform: translate)
            
            if (!isLoading) {
                HStack(alignment: .center) {
                    TextField("Translated Link", text: $linkOut)
                        .textFieldStyle(.roundedBorder)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                        .padding(.horizontal)
                }
//                .padding(.vertical, 10.0)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.vertical, 10.0)
            }
            
            Button("Share Link") {
                if let urlShare = URL(string: linkOut) {
                    let shareActivity = UIActivityViewController(activityItems: [urlShare], applicationActivities: nil)
                    
                    let scenes = UIApplication.shared.connectedScenes
                    let windowScene = scenes.first as? UIWindowScene
                    
                    windowScene?.keyWindow?.rootViewController?.present(shareActivity, animated: true, completion: nil)
                }
            }
            .padding()
            
            Button("Done") {
                dismiss()
            }
        }
    }
}

struct ShareLinkView_Previews: PreviewProvider {
    @State static var blank = ""
    static var previews: some View {
        ShareLinkView(shareLink: $blank)
    }
}

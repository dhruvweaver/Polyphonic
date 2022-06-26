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
    @State private var isLoading: Bool = true
    @State private var songData = SongData()
    @State private var isShare = false
    
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
            
            VStack(alignment: .center) {
                if (!isLoading) {
                    HStack(alignment: .center) {
                        TextField("Translated Link", text: $linkOut)
                            .textFieldStyle(.roundedBorder)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                            .padding(.horizontal)
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .frame(height: 40)
            .padding(.top, 10.0)
            
            Button("Share Link") {
                isShare = true
            }
            .padding()
            .background(SharingViewController2(isPresenting: $isShare) {
                let urlShare = URL(string: linkOut)
                let av = UIActivityViewController(activityItems: [urlShare!], applicationActivities: nil)
                
                av.completionWithItemsHandler = { _, _, _, _ in
                    isShare = false // required for re-open !!!
                }
                return av
            })
        }
    }
}

struct SharingViewController2: UIViewControllerRepresentable {
    @Binding var isPresenting: Bool
    var content: () -> UIViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresenting {
            uiViewController.present(content(), animated: true, completion: nil)
        }
    }
}

struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        ShareView()
    }
}

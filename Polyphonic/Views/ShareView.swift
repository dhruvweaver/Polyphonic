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
    @State private var isValid: Bool = false
    
    @State private var songData = MusicData()
    @State private var keySong: Song = Song(title: "Title and Registration", ISRC: "123", artists: ["Death Cab for Cutie"], album: "Transatlanticism", albumID: "123", explicit: false, trackNum: 3)
    @State private var isShare = false
    @State private var type: MusicType = .song
    @State private var alts: [Song] = []
    @State private var altURLs: [String] = []
    
    @State private var showingEditSheet: Bool = false
    
    private func translate() {
        Task {
            let results = await songData.translateData(link: linkStr)
            linkOut = results.0
            if let song = results.1 {
                keySong = song
                type = results.2
                alts = results.4
                altURLs = results.3
            }
            validURL()
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
                    .disabled(true)
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
                            .disabled(true)
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .frame(height: 40)
            .padding(.top, 10.0)
            
            Text("Output Preview")
                .font(.title2)
                .fontWeight(.heavy)
            
            if (isValid) {
                OutputPreviewView(song: keySong, type: type, url: linkOut)
            } else {
                OutputPreviewView(song: Song(title: "abcdefghijklmnopqr", ISRC: "nil", artists: ["abcdefghijklmno"], album: "abcdefghij", albumID: "nil", explicit: false, trackNum: 0), type: .song, url: linkOut)
                    .redacted(reason: .placeholder)
            }
            
            Button("Edit") {
                showingEditSheet.toggle()
            }
            .disabled(isLoading || !isValid)
            .sheet(isPresented: $showingEditSheet) {
                EditResultsView(song: $keySong, alts: alts, altURLs: altURLs, type: type, linkOut: $linkOut)
            }
            
            Button("Share Link") {
                isShare = true
            }
            .disabled(isLoading || !isValid)
            .padding()
            .background(SharingViewController(isPresenting: $isShare) {
                let urlShare = URL(string: linkOut)
                let av = UIActivityViewController(activityItems: [urlShare!], applicationActivities: nil)
                
                av.completionWithItemsHandler = { _, _, _, _ in
                    isShare = false // required for re-open !!!
                }
                return av
            })
        }
    }
    
    private func validURL() {
        if let _ = URL(string: linkOut) {
            isValid = true
        } else {
            isValid = false
        }
    }
}

struct SharingViewController: UIViewControllerRepresentable {
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

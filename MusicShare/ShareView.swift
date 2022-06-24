//
//  File.swift
//  LinkShare
//
//  Created by Dhruv Weaver on 6/22/22.
//

import SwiftUI

struct ShareView: View {
    var item: NSExtensionItem!
    @State private var linkStr: String = "No link yet"
    @State private var linkOut: String = ""
    @State private var isLoading: Bool = false
    var body: some View {
        let songData = SongData()
        VStack(alignment: .center) {
            Button("Get Input Link") {
                getURL()
            }
            HStack(alignment: .center) {
                TextField("", text: $linkStr)
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
    
    init(item: NSExtensionItem) {
        self.item = item
        getURL()
    }
    
    func getURL() {
        if let itemProvider = item.attachments?.first {
            if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
                itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (url, error) -> Void in
                    if let error = error {
                        print("error :-", error)
                    }
                    if (url as? NSURL) != nil {
                        // send url to server to share the link
                        do {
                            if let url = url as? URL{
                                print(url.absoluteString)
                                linkStr = url.absoluteString
                            }
                        }
                    }
                })
            }
        }
    }
}

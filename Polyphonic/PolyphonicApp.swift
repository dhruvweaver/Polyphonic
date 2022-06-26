//
//  PolyphonicApp.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/11/22.
//

import SwiftUI

@main
struct PolyphonicApp: App {
    @State private var shareLink: String = ""
    @State private var fromShare: Bool = false
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    var query = (url.query)!

                    if let indEquals = query.firstIndex(of: "=") {
                        query = String(query[query.index(indEquals, offsetBy: +1)..<query.endIndex])
                    }
                    shareLink = query
                    fromShare = true
                    print(query)
                }
                .sheet(isPresented: $fromShare) {
                    ShareLinkView(shareLink: $shareLink)
                }
        }
    }
}

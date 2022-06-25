//
//  PolyphonicApp.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/11/22.
//

import SwiftUI

@main
struct PolyphonicApp: App {
    @State var shareLink: String = ""
    var body: some Scene {
        WindowGroup {
            // TODO: if a valid link is sent, show a different screen
            ContentView(shareLink: $shareLink)
                .onOpenURL { url in
                    var query = (url.query)!

                    if let indEquals = query.firstIndex(of: "=") {
                        query = String(query[query.index(indEquals, offsetBy: +1)..<query.endIndex])
                    }
                    shareLink = query
                    print(query)
                }
        }
    }
}

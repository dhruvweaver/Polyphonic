//
//  PlaylistView.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/10/22.
//

import SwiftUI

struct PlaylistView: View {
    var body: some View {
        NavigationView {
            VStack (alignment: .center) {
                Text("Coming soon...")
                    .fontWeight(.bold)
            }
            .navigationTitle("Polyphonic")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
    }
}

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
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
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

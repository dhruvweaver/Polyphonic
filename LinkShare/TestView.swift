//
//  TestView.swift
//  LinkShare
//
//  Created by Dhruv Weaver on 6/24/22.
//

import SwiftUI

struct TestView : View {
    @State public var incoming_text: String
    
    var body: some View {
        Text(incoming_text)
    }
}

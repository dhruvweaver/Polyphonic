//
//  Album.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/27/22.
//

import Foundation

class Album {
    private let title: String!
    private let UPC: String!
    private let artists: [String]!
    private let songCount: Int!
    private let label: String!
    private var keySongID: String?
    private var translatedURL: URL?
    
    init(title: String, UPC: String, artists: [String], songCount: Int, label: String) {
        self.title = title
        self.UPC = UPC
        self.artists = artists
        self.songCount = songCount
        self.label = label
    }
    
    func getTitle() -> String {
        return title
    }
    
    func getUPC() -> String {
        return UPC
    }
    
    func getArtists() -> [String] {
        return artists
    }
    
    func getSongCount() -> Int {
        return songCount
    }
    
    func getLabel() -> String {
        return label
    }
    
    func setKeySongID(id: String) {
        keySongID = id
    }
    
    func getKeySongID() -> String {
        if let link = keySongID {
            return link
        } else {
            return ""
        }
    }
    
    func setTranslatedURL(link: String) {
        translatedURL = URL(string: link)
    }
    
    func getTranslatedURLasString() -> String {
        if let translatedURL = translatedURL {
            return translatedURL.absoluteString
        } else {
            return "There was no translation available"
        }
    }
}

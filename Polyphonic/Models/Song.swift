//
//  Song.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/11/22.
//

import Foundation

class Song {
    private let title: String!
    private let ISRC: String!
    private let artists: [String]!
    private let album: String!
    private let albumID: String!
    private let explicit: Bool!
    private var translatedURL: URL?
    
    init(title: String, ISRC: String, artists: [String], album: String, albumID: String, explicit: Bool) {
        self.title = title
        self.ISRC = ISRC
        self.artists = artists
        self.album = album
        self.albumID = albumID
        self.explicit = explicit
    }
    
    func getTitle() -> String {
        return title
    }
    
    func getISRC() -> String {
        return ISRC
    }
    
    func getArtists() -> [String] {
        return artists
    }
    
    func getAlbum() -> String {
        return album
    }
    
    func getAlbumID() -> String {
        return albumID
    }
    
    func getExplicit() -> Bool {
        return explicit
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

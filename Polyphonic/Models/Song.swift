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
    private let trackNum: Int!
    private var translatedImgURL: URL?
    
    init(title: String, ISRC: String, artists: [String], album: String, albumID: String, explicit: Bool, trackNum: Int) {
        self.title = title
        self.ISRC = ISRC
        self.artists = artists
        self.album = album
        self.albumID = albumID
        self.explicit = explicit
        self.trackNum = trackNum
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
    
    func getTrackNum() -> Int {
        return trackNum
    }
    
    func getTranslatedURLasString() -> String {
        if let translatedURL = translatedURL {
            return translatedURL.absoluteString
        } else {
            return "There was no translation available"
        }
    }
    
    func setTranslatedImgURL(link: String) {
        translatedImgURL = URL(string: link)
    }
    
    func getTranslatedImgURL() -> URL {
        if let translatedImgURL = translatedImgURL {
            return translatedImgURL
        }
        return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Question_mark_%28black%29.svg/800px-Question_mark_%28black%29.svg.png")!
    }
}

//
//  Song.swift
//  MusicLinkApp
//
//  Created by Dhruv Weaver on 6/11/22.
//

import Foundation

class Song {
    private let title: String!
    private let ISRC: String!
    private let artists: [String]!
    private let album: String!
    private var spotifyURL: URL?
    private var appleMusicURL: URL?
    
    init(title: String, ISRC: String, artists: [String], album: String) {
        self.title = title
        self.ISRC = ISRC
        self.artists = artists
        self.album = album
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
    
    func setSpotifyURL(link: URL) {
        spotifyURL = link
    }
    
    func setAppleMusicURL(link: URL) {
        appleMusicURL = link
    }
}

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
    private let artist: String!
    private let album: String!
    private var spotifyURL: URL?
    private var appleMusicURL: URL?
    
    init(title: String, ISRC: String, artist: String, album: String) {
        self.title = title
        self.ISRC = ISRC
        self.artist = artist
        self.album = album
    }
    
    func getTitle() -> String {
        return title
    }
    
    func getISRC() -> String {
        return ISRC
    }
    
    func getArtist() -> String {
        return artist
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

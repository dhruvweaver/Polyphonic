//
//  Album.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/27/22.
//

import Foundation

/**
 Class containing important details and parameters for identifying songs.
 */
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
    
    /**
     - Returns: Album's title.
     */
    func getTitle() -> String {
        return title
    }
    
    /**
     - Returns: Album's UPC.
     */
    func getUPC() -> String {
        return UPC
    }
    
    /**
     - Returns: Album's artists.
     */
    func getArtists() -> [String] {
        return artists
    }
    
    /**
     - Returns: Album's song count.
     */
    func getSongCount() -> Int {
        return songCount
    }
    
    /**
     - Returns: Album's label.
     */
    func getLabel() -> String {
        return label
    }
    
    /**
     - Parameter id: ID for the album's key song (a song that can identify the content rating of the album).
     */
    func setKeySongID(id: String) {
        keySongID = id
    }
    
    /**
     - Returns: Album's title.
     */
    func getKeySongID() -> String {
        if let link = keySongID {
            return link
        } else {
            return ""
        }
    }
    
    /**
     - Parameter link: Link to the album on the output platform.
     */
    func setTranslatedURL(link: String) {
        translatedURL = URL(string: link)
    }
    
    /**
     - Returns: Translated URL as a `String` if it is valid, otherwise returns a message reflecting an error.
     */
    func getTranslatedURLasString() -> String {
        if let translatedURL = translatedURL {
            return translatedURL.absoluteString
        } else {
            return "There was no translation available"
        }
    }
}

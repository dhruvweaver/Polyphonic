//
//  Song.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/11/22.
//

import Foundation
import UIKit

/**
 Class containing important details and parameters for identifying songs.
 */
class Song {
    private let title: String!
    private let ISRC: String!
    private let artists: [String]!
    private let album: String!
    private let albumID: String!
    private let explicit: Bool!
    private var originalURL: URL?
    private var translatedURL: URL?
    private var translationConfidence: Int = 0
    private let trackNum: Int!
    private var translatedImgURL: URL?
    private var translatedImgData: Data?
    
    var alts: [Song] = []
    
    init(title: String, ISRC: String, artists: [String], album: String, albumID: String, explicit: Bool, trackNum: Int) {
        self.title = title
        self.ISRC = ISRC
        self.artists = artists
        self.album = album
        self.albumID = albumID
        self.explicit = explicit
        self.trackNum = trackNum
    }
    
    /**
     - Returns: Song's title.
     */
    func getTitle() -> String {
        return title
    }
    
    /**
     - Returns: Song's ISRC.
     */
    func getISRC() -> String {
        return ISRC
    }
    
    /**
     - Returns: Song's artists.
     */
    func getArtists() -> [String] {
        return artists
    }
    
    /**
     - Returns: Song's album.
     */
    func getAlbum() -> String {
        return album
    }
    
    /**
     - Returns: Song's related album ID.
     */
    func getAlbumID() -> String {
        return albumID
    }
    
    /**
     - Returns: Song's content rating; true if explicit.
     */
    func getExplicit() -> Bool {
        return explicit
    }
    
    /**
     - Returns: Song's track number in the album.
     */
    func getTrackNum() -> Int {
        return trackNum
    }
    
    func setOriginalURL(link: String) {
        originalURL = URL(string: link)
    }
    
    func getOriginalURL() -> URL? {
        return originalURL
    }
    
    /**
     - Parameter link: Link to the song on the output platform.
     */
    func setTranslatedURL(link: String) {
        translatedURL = URL(string: link)
    }
    
    func getTranslatedURL() -> URL? {
        return translatedURL
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
    
    func setConfidence(level: Int) {
        translationConfidence = level
    }
    
    func getConfidence() -> Int {
        return translationConfidence
    }
    /**
     - Parameter link: Link to the album art on the output platform.
     */
    func setTranslatedImgURL(link: String) {
        translatedImgURL = URL(string: link)
    }
    
    /**
     - Returns: Translated song's album art URL as a `String` if it is valid, otherwise returns a link to an image of a question mark.
     */
    func getTranslatedImgURL() -> URL? {
        if let translatedImgURL = translatedImgURL {
            return translatedImgURL
        }
        return nil
    }
    
    /**
     Asyncronously gets image data from the `translatedImgURL` and saves it to `translatedImgData` in the `Song` object.
     */
    func setTranslatedImgData() async {
        if let url = self.getTranslatedImgURL() {
            translatedImgData = await getImageData(imageURL: url)
        } else {
            let image = UIImage(named: "NoMusic")
            translatedImgData = image?.pngData()
        }
    }
    
    /**
     - Returns: Image data previously gathered from the internet. `nil` if there is none.
     */
    func getTranslatedImgData() -> Data? {
        return translatedImgData
    }
}

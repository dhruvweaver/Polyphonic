//
//  SongData.swift
//  MusicLinkApp
//
//  Created by Dhruv Weaver on 6/11/22.
//

import Foundation

class SongData {
    private let starterLink: URL!
    
    init(starterLink: URL) {
        self.starterLink = starterLink
    }
    
    let spotifyAuthKey = (spotifyClientID + ":" + spotifyClientSecret).toBase64()
    
    enum Platform {
        case unknown, spotify, appleMusic
    }
    private var starterSource: Platform = Platform.unknown
    
    struct RelatedData {
        private let title: String!
        private let ISRC: String!
        private let artist: String!
        private let album: String!
        // could later hold an array of links to different platforms. Or a dictionary to quickly find the desired one
        private let link: URL!
    }
    
    func findPlatform() {
        let linkString = starterLink.absoluteString
        if (linkString.contains("apple")) {
            starterSource = Platform.appleMusic
        } else if (linkString.contains("spotify")) {
            starterSource = Platform.spotify
        }
    }
    
    func getSpotifyAuthKey() async {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        let urlSession = URLSession.shared
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(spotifyAuthKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "grant_type": "client_credentials"
        ]
        
        
    }
    
    func findTranslatedLink() {
        // first identify which platform the link starts with
        findPlatform()
        
        if (starterSource == Platform.spotify) {
            // Spotify API call can be made with the Spotify ID. This is located at the end of a Spotify link
            let spotifyID = starterLink.lastPathComponent
            
        }
    }
}

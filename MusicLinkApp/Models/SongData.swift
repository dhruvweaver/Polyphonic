//
//  SongData.swift
//  MusicLinkApp
//
//  Created by Dhruv Weaver on 6/11/22.
//

import Foundation

class SongData {
    private var starterLink: URL? = nil
    
    init() {
        
    }
    
    enum Platform {
        case unknown, spotify, appleMusic
    }
    private var starterSource: Platform = Platform.unknown
    
    struct CommonSongData {
        private let title: String
        private let ISRC: String
        private let artist: String
        private let album: String
        // could later hold an array of links to different platforms. Or a dictionary to quickly find the desired one
        private let link: URL
    }
    
    private var spotifyAccessJSON: SpotifyAccessData? = nil
    struct SpotifyAccessData: Decodable {
        let access_token: String
    }
    
    private func findPlatform() {
        let linkString = starterLink!.absoluteString
        if (linkString.contains("apple")) {
            starterSource = Platform.appleMusic
        } else if (linkString.contains("spotify")) {
            starterSource = Platform.spotify
        }
    }
    
    private func getSpotifyAuthKey() async -> String? {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        let urlSession = URLSession.shared
        let spotifyClientString = (spotifyClientID + ":" + spotifyClientSecret).toBase64()
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(spotifyClientString)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let postString = "grant_type=client_credentials"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        do {
            let (data, _) = try await urlSession.data(for: request)
            spotifyAccessJSON = try JSONDecoder().decode(SpotifyAccessData.self, from: data)
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
        
        var accessKey: String? = nil
        
        if let processed = spotifyAccessJSON {
            accessKey = processed.access_token
            print("Auth: \(accessKey)")
        }
        
        return accessKey
    }
    
    // currently only outputs song name
    private func findTranslatedLink() async -> String? {
        var output: String? = nil
        // first identify which platform the link starts with
        findPlatform()
        
        if (starterSource == Platform.spotify) {
            print("Link is from Spotify")
            // Spotify API call can be made with the Spotify ID. This is located at the end of a Spotify link
            let spotifyID = starterLink!.lastPathComponent
            // get authorization key from Spotify
            if let authKey = await getSpotifyAuthKey() {
                let Spotify = SpotifySongData(songID: spotifyID, authKey: authKey)
                await Spotify.getSpotifySongData()
                Spotify.parseToObject()
                
                print(Spotify.song?.getTitle())
                if let songName = Spotify.song?.getTitle() {
                    output = songName
                }
            }
        }
        
        return output
    }
    
    func translateData(link: String) async -> String {
        starterLink = URL(string: link)!
        
        var link: String?
        link = await findTranslatedLink()
        
        if link != nil {
            return link!
        } else {
            return "Output Failed"
        }
    }
}


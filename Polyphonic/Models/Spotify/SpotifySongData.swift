//
//  SpotifySongData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/12/22.
//

import Foundation

class SpotifySongData {
    private let songID: String?
    var song: Song? = nil
    
    init(songID: String?) {
        self.songID = songID
    }
    
    private var spotifySongJSON: SpotifySongDataRoot? = nil
    private var spotifySearchJSON: SpotifySongSearchRoot? = nil
    
    struct SpotifySongDataRoot: Decodable {
        let album: Album
        let artists: [Artist]
        let explicit: Bool
        let external_ids: ExternalIDs
        let name: String
        let uri: String
    }
    
    struct Album: Decodable {
        let id: String
        let name: String
    }
    
    struct Artist: Decodable {
        let name: String
    }
    
    struct ExternalIDs: Decodable {
        let isrc: String
    }
    
    struct SpotifySongSearchRoot: Decodable {
        let tracks: Tracks
    }
    
    struct Tracks: Decodable {
        let items: [SpotifySongDataRoot]
    }
    
    private var spotifyAccessJSON: SpotifyAccessData? = nil
    struct SpotifyAccessData: Decodable {
        let access_token: String
    }
    
    func getSpotifyAuthKey() async -> String? {
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
        }
        
        return accessKey
    }
    
    func getSpotifySongDataByID() async {
        let url = URL(string: "https://api.spotify.com/v1/tracks/\(songID!)")!
        let sessionConfig = URLSessionConfiguration.default
        // get authorization key from Spotify
        if let authKey = await getSpotifyAuthKey() {
            let authValue: String = "Bearer \(authKey)"
            sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
            let urlSession = URLSession(configuration: sessionConfig)
            do {
                let (data, response) = try await urlSession.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse.statusCode)
                }
                self.spotifySongJSON = try JSONDecoder().decode(SpotifySongDataRoot.self, from: data)
            } catch {
                debugPrint("Error loading \(url): \(String(describing: error))")
            }
        }
    }
    
    func getSpotifySongDataBySearch(songRef: Song, narrowSearch: Bool) async {
        var songStr = songRef.getTitle()
        songStr = cleanSpotifyText(title: songStr, forSearching: true)
        let artistStr = songRef.getArtists()[0]
        
        var searchParams: String
        if (narrowSearch) {
            searchParams = "track:\(songStr) artist:\(artistStr)&type=track"
        } else {
            searchParams = "track:\(songStr)&type=track"
        }
        
        let url = URL(string: "https://api.spotify.com/v1/search?q=\(searchParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
        debugPrint("Querying: \(url.absoluteString)")
        let sessionConfig = URLSessionConfiguration.default
        // get authorization key from Spotify
        if let authKey = await getSpotifyAuthKey() {
            let authValue: String = "Bearer \(authKey)"
            sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
            let urlSession = URLSession(configuration: sessionConfig)
            do {
                let (data, response) = try await urlSession.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse.statusCode)
                }
                self.spotifySearchJSON = try JSONDecoder().decode(SpotifySongSearchRoot.self, from: data)
            } catch {
                debugPrint("Error loading \(url): \(String(describing: error))")
            }
        }
    }
    
    func parseToObject(songRef: Song?) -> Bool {
        if let processed = spotifySongJSON {
            var artists: [String] = []
            for i in processed.artists {
                artists.append(i.name)
            }
            song = Song(title: processed.name, ISRC: processed.external_ids.isrc, artists: artists, album: processed.album.name, albumID: processed.album.id, explicit: processed.explicit)
        } else if let processed = spotifySearchJSON {
            let resultsCount = processed.tracks.items.count
            debugPrint("Number of results: \(resultsCount)")
            // handle case where search is too narrow
            if (resultsCount == 0) {
                debugPrint("Spotify search too narrow")
                // broaden search, remove artist parameter
                return false
            }
            
            var i = 0
            var matchFound: Bool! = false
            var closeMatch: Int? = nil
            var lookForCloseMatch: Bool = true
            while (resultsCount > i && !matchFound) {
                let attributes = processed.tracks.items[i]
                var artists: [String] = []
                for j in attributes.artists {
                    artists.append(j.name)
                }
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit)
                debugPrint(song!.getISRC())
                debugPrint(songRef!.getISRC())
                debugPrint(song!.getArtists()[0])
                debugPrint(songRef!.getArtists()[0])
                debugPrint("Spotify Album: \(song!.getAlbum())")
                debugPrint("Input   Album: \(songRef!.getAlbum())")
                
                // if there is an exact match with the ISRC, then the search can stop
                if (song?.getISRC() == songRef!.getISRC() && song?.getExplicit() == songRef?.getExplicit()) {
                    matchFound = true
                } else if (lookForCloseMatch && song?.getExplicit() == songRef?.getExplicit() && !(song?.getISRC() == songRef!.getISRC()) && (((song?.getAlbum() == songRef!.getAlbum() || cleanSpotifyText(title: (song?.getAlbum())!, forSearching: false) == cleanSpotifyText(title: songRef!.getAlbum(), forSearching: false)) && cleanSpotifyText(title: (song?.getTitle())!, forSearching: false) == cleanSpotifyText(title: songRef!.getTitle(), forSearching: false) && cleanArtistName(name: song!.getArtists()[0], forSearching: false) == cleanArtistName(name: songRef!.getArtists()[0], forSearching: false)))) {
                    debugPrint("Found close match")
                    // bookmark and come back to this one if nothing else matches
                    closeMatch = i
                    lookForCloseMatch = false
                }
                
                i += 1
                debugPrint(i)
            }
            
            if matchFound {
                let attributes = processed.tracks.items[i - 1]
                var artists: [String] = []
                for i in attributes.artists {
                    artists.append(i.name)
                }
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit)
                debugPrint("Found an exact match")
                song?.setTranslatedURL(link: generateLink(uri: attributes.uri))
            } else if (closeMatch != nil) {
                let attributes = processed.tracks.items[closeMatch!]
                var artists: [String] = []
                for i in attributes.artists {
                    artists.append(i.name)
                }
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit)
                debugPrint("Found a close match")
                song?.setTranslatedURL(link: generateLink(uri: attributes.uri))
            }
        }
        
        return true
    }
}

private func generateLink(uri: String) -> String {
    return "https://open.spotify.com/track/\(uri.suffix(from: uri.index(after: uri.lastIndex(of: ":")!)))"
}

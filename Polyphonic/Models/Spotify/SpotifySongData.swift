//
//  SpotifySongData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/12/22.
//

import Foundation
/**
 Class containing functions and structures critical to communicating with Spotify's music database, and for identifying a matching song.
 - Note: `parseToObject()` function only parses objects once decoded JSON data has been assigned within the class. Call either of the `getSpotifySongData` methods to do so.
 ~~~
 // initialize object
 let spotifyData = SpotifySongData("0123456789")
 
 // initialize decoded JSON data within SpotifySongData object
 spotifyData.getSpotifySongDataByID()
 
 // parse data into something usable,
 // will store usable `Song` object in public variable
 let accurate = spotifyData.parseToObject()
 // handle whether search results were accurate enough, if applicable
 let song = spotifyData.song
 
 // do something with the song
 ~~~
 */
class SpotifySongData {
    private let songID: String?
    var song: Song? = nil
    
    init(songID: String?) {
        self.songID = songID
    }
    
    private var spotifySongJSON: SpotifySongDataRoot? = nil
    private var spotifySearchJSON: SpotifySongSearchRoot? = nil
    
    /* Start of JSON decoding structs */
    private struct SpotifySongDataRoot: Decodable {
        let album: Album
        let artists: [Artist]
        let explicit: Bool
        let external_ids: ExternalIDs
        let name: String
        let track_number: Int
        let uri: String
    }
    
    private struct Album: Decodable {
        let id: String
        let name: String
        let images: [ArtImage]
    }
    
    private struct ArtImage: Decodable {
        let url: String
    }
    
    private struct Artist: Decodable {
        let name: String
    }
    
    private struct ExternalIDs: Decodable {
        let isrc: String
    }
    
    private struct SpotifySongSearchRoot: Decodable {
        let tracks: Tracks
    }
    
    private struct Tracks: Decodable {
        let items: [SpotifySongDataRoot]
    }
    
    private var spotifyAccessJSON: SpotifyAccessData? = nil
    struct SpotifyAccessData: Decodable {
        let access_token: String
    }
    /* End of JSON decoding structs */
    
    /**
     Gets an authorization key from Spotify's API.
     - Returns: Authorization key.
     */
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
    
    /**
     Assings local variable `spotifySongJSON` to decoded JSON after querying API for song data using a song ID.
     */
    func getSpotifySongDataByID() async {
        let url = URL(string: "https://api.spotify.com/v1/tracks/\(songID!)")!
        let sessionConfig = URLSessionConfiguration.default
        // get authorization key from Spotify
        if let authKey = await getSpotifyAuthKey() {
            let authValue: String = "Bearer \(authKey)"
            sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
            debugPrint("Querying: \(url.absoluteString)")
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
    
    /**
     Assings local variable `spotifySearchJSON` to decoded JSON after querying API for song data using relevant search parameters.
     - Parameter songRef: Song object containing song data from the original source.
     - Parameter narrowSearch: Whether or not to use broad search terms or to be more specific.
     */
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
    
    /**
     Parses data from decoded JSON to a song object. If the data came from search results more processing is required, and the original `Song` object is compared with the search results to find the best match.
     The function will then return a `Bool` indicating whether or not a broader search is needed.
     - Parameter songRef: Reference `Song` object for checking against search results. Not needed if processing results from an ID search.
     - Returns: `Bool` indicating whether or not a broader search is needed. `True` means results were acceptable.
     - Note: `parseToObject()` function only parses objects once decoded JSON data has been assigned within the class. Call either of the `getSpotifySongData` methods to do so.
     */
    func parseToObject(songRef: Song?) -> Bool {
        if let processed = spotifySongJSON {
            var artists: [String] = []
            for i in processed.artists {
                artists.append(i.name)
            }
            song = Song(title: processed.name, ISRC: processed.external_ids.isrc, artists: artists, album: processed.album.name, albumID: processed.album.id, explicit: processed.explicit, trackNum: processed.track_number)
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
            var veryCloseMatchFound: Bool = true
            while (resultsCount > i && !matchFound) {
                let attributes = processed.tracks.items[i]
                var artists: [String] = []
                for j in attributes.artists {
                    artists.append(j.name)
                }
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit, trackNum: attributes.track_number)
                debugPrint(song!.getISRC())
                debugPrint(songRef!.getISRC())
                debugPrint(song!.getArtists()[0])
                debugPrint(songRef!.getArtists()[0])
                debugPrint("Spotify Album: \((song?.getAlbum())!)")
                debugPrint("Input   Album: \(songRef!.getAlbum())")
                
                // if there is an exact match with the ISRC, then refine parameters until a match is identified
                if (song?.getISRC() == songRef!.getISRC()) {
                    if (cleanText(text: song!.getAlbum()) == cleanText(text: songRef!.getAlbum())) {
                        matchFound = true
                        lookForCloseMatch = false
                        debugPrint("Marked as exact match")
                    } else if (lookForCloseMatch) {
                        closeMatch = i
                        debugPrint("Marked as close match")
                        if (song?.getTrackNum() == songRef!.getTrackNum() && song?.getExplicit() == songRef?.getExplicit()) {
                            lookForCloseMatch = false
                            debugPrint("Marked as very close match")
                        }
                    }
                    // sometimes an exact match doesn't exist due to ISRC discrepancies, these must be resolved with a "close match"
                } else if (lookForCloseMatch) {
                    if (cleanText(text: song!.getAlbum()) == cleanText(text: songRef!.getAlbum())) {
                        closeMatch = i
                        debugPrint("Marked as close match")
                        if (song?.getTrackNum() == songRef!.getTrackNum() && song?.getExplicit() == songRef?.getExplicit()) {
                            lookForCloseMatch = false
                            veryCloseMatchFound = true
                            debugPrint("Marked as very close match")
                        }
                    } else if (cleanSpotifyText(title: (song?.getAlbum())!, forSearching: true) == cleanSpotifyText(title: songRef!.getAlbum(), forSearching: true)) {
                        closeMatch = i
                        debugPrint("Marked as close match")
                        if (song?.getTrackNum() == songRef!.getTrackNum() && song?.getExplicit() == songRef?.getExplicit()) {
                            debugPrint("Marked as very close match")
                        }
                    }
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
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit, trackNum: attributes.track_number)
                debugPrint("Found an exact match")
                song?.setTranslatedURL(link: generateLink(uri: attributes.uri))
                song?.setTranslatedImgURL(link: attributes.album.images[1].url)
            } else if (closeMatch != nil) {
                let attributes = processed.tracks.items[closeMatch!]
                var artists: [String] = []
                for i in attributes.artists {
                    artists.append(i.name)
                }
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit, trackNum: attributes.track_number)
                debugPrint("Found a close match")
                song?.setTranslatedURL(link: generateLink(uri: attributes.uri))
                song?.setTranslatedImgURL(link: attributes.album.images[1].url)
                
                // broaden search?
                return veryCloseMatchFound
            } else {
                debugPrint("No matches")
            }
        }
        
        return true
    }
    
    /**
     Generates link to a song given its Spotify URI.
     - Parameter uri: URI as provided by Spotify.
     - Returns: URL in `String` form.
     */
    private func generateLink(uri: String) -> String {
        return "https://open.spotify.com/track/\(uri.suffix(from: uri.index(after: uri.lastIndex(of: ":")!)))"
    }
    
    // parsed list of songs for user to override results with alternate results
    /**
     Gets and returns the full list of `Song` objects from decoded JSON data returned by API search.
     - Returns: `List` of `Song` objects
     */
    func getAllSongs() -> [Song] {
        var songs: [Song] = []
        if let processed = spotifySearchJSON {
            for i in processed.tracks.items{
                let attributes = i
                var artists: [String] = []
                for j in attributes.artists {
                    artists.append(j.name)
                }
                let songItem = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit, trackNum: attributes.track_number)
                songItem.setTranslatedURL(link: generateLink(uri: attributes.uri))
                songItem.setTranslatedImgURL(link: attributes.album.images[1].url)
                songs.append(songItem)
            }
        }
        
        // if array returned is empty, then the UI should reflect that
        return songs
    }
}

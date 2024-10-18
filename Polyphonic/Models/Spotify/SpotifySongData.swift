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
    
    /**
     Assings local variable `spotifySongJSON` to decoded JSON after querying API for song data using a song ID.
     */
    func getSpotifySongDataByID() async {let url = URL(string: "\(serverAddress)/spotify/song/id/\(songID!)")!
        let urlSession = URLSession(configuration: sessionConfig) // optional so memory can be cleared
//        sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
        debugPrint("Querying: \(url.absoluteString)")
        do {
            let (data, response) = try await urlSession.data(from: url)
            urlSession.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            self.spotifySongJSON = try JSONDecoder().decode(SpotifySongDataRoot.self, from: data)
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    /**
     Assings local variable `spotifySearchJSON` to decoded JSON after querying API for song data using relevant search parameters.
     - Parameter songRef: Song object containing song data from the original source.
     - Parameter narrowSearch: Whether or not to use broad search terms or to be more specific.
     */
    func getSpotifySongDataBySearch(songRef: Song, narrowSearch: Bool) async {
        var songStr = songRef.getTitle()
        var artistStr = songRef.getArtists()[0]
        
        songStr = simplifyMusicText(title: songStr, broadSearch: false)
        artistStr = normalizeString(str: artistStr)
        
        debugPrint("Song: \(songStr)")
        debugPrint("Artist: \(artistStr)")
        
        var searchParams: String
        if (narrowSearch) {
//            searchParams = "track:\(songStr) artist:\(artistStr)&type=track"
            searchParams = "track:\(songStr) artist:\(artistStr)"
        } else {
            debugPrint("Performing broader search")
            songStr = simplifyMusicText(title: songRef.getTitle(), broadSearch: true)
            artistStr  = simplifyMusicText(title: songRef.getArtists()[0], broadSearch: true)
            
//            searchParams = "track:\(songStr) artist:\(artistStr)&type=track"
            searchParams = "track:\(songStr) artist:\(artistStr)"
        }
        
        let url = URL(string: "\(serverAddress)/spotify/song/search/\(searchParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
        debugPrint("Querying: \(url.absoluteString)")
        let urlSession = URLSession(configuration: sessionConfig)
        do {
            let (data, response) = try await urlSession.data(from: url)
            urlSession.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            self.spotifySearchJSON = try JSONDecoder().decode(SpotifySongSearchRoot.self, from: data)
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    /**
     Parses data from decoded JSON to a song object. If the data came from search results more processing is required, and the original `Song` object is compared with the search results to find the best match.
     The function will then return a `Bool` indicating whether or not a broader search is needed.
     - Parameter songRef: Reference `Song` object for checking against search results. Not needed if processing results from an ID search.
     - Parameter vagueMatching: Whether or not to use vague matching techniques. Useful if no exact results have been found.
     - Returns: `TranslationMatchLevel` indicating how close the match was and whether or not a broader search is needed. See documentation for `TranslationMatchLevel` for more.
     - Note: `parseToObject()` function only parses objects once decoded JSON data has been assigned within the class. Call either of the `getSpotifySongData` methods to do so.
     */
    func parseToObject(songRef: Song?, vagueMatching: Bool) -> TranslationMatchLevel {
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
                return .none
            }
            
            var i = 0
            var matchFound: Bool! = false
            var closeMatch: Int? = nil
            var veryCloseMatch: Int? = nil
            var bestLevNumTitle = 1000
            var bestLevNumAlbum = 5
            var lookForCloseMatch: Bool = true
            var veryCloseMatchFound: Bool = false
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
                debugPrint("Spotify Album: \(simplifyMusicText(title: (song?.getAlbum())!, broadSearch: false))  - track: \(song!.getTrackNum())")
                debugPrint("Input Album: \(simplifyMusicText(title: (songRef?.getAlbum())!, broadSearch: false))  - track: \(songRef!.getTrackNum())")
                
                if (song?.getISRC() == songRef!.getISRC()) { // if ISRC matches no further effort required
                    if (normalizeString(str: song!.getAlbum()) == normalizeString(str: songRef!.getAlbum())) {
                        matchFound = true
                        lookForCloseMatch = false
                        debugPrint("Marked as exact match (e1)")
                    } else if (lookForCloseMatch) {
                        closeMatch = i
                        debugPrint("Marked as close match (c1)")
                        // album titles might be slightly different, but if two similar song names also have the same track number and explicit status, they're probably the same
                        if (song?.getTrackNum() == songRef!.getTrackNum() && song?.getExplicit() == songRef?.getExplicit()) {
                            veryCloseMatch = i
                            veryCloseMatchFound = true
                            lookForCloseMatch = false
                            
                            debugPrint("Marked as very close match (v1)")
                        } else {
                            debugPrint("Good ISRC. Levenshtein distance for song comparison")
                            
                            var normTitle1: String
                            var normTitle2: String
                            
                            if (!vagueMatching) {
                                normTitle1 = normalizeString(str: song!.getTitle())
                                normTitle2 = normalizeString(str: songRef!.getTitle())
                            } else { // use vague comparison methods
                                normTitle1 = simplifyMusicText(title: song!.getTitle(), broadSearch: true)
                                normTitle2 = simplifyMusicText(title: songRef!.getTitle(), broadSearch: true)
                            }
                            
                            // get Levenshtein distance between song titles
                            let levNum = levDis(normTitle1, normTitle2)
                            if (levNum < bestLevNumTitle) {
                                debugPrint("Best Lev distance: \(levNum)")
                                bestLevNumTitle = levNum
                                
                                veryCloseMatch = i
                                
                                veryCloseMatchFound = true
                                lookForCloseMatch = false
                                debugPrint("Marked as very close match (v2)")
                            }
                        }
                    }
                    // sometimes an exact match doesn't exist due to ISRC discrepancies, these must be resolved with a "close match"
                } else if (lookForCloseMatch) {
                    var normTitle1: String
                    var normTitle2: String
                    
                    if (!vagueMatching) {
                        normTitle1 = normalizeString(str: song!.getTitle())
                        normTitle2 = normalizeString(str: songRef!.getTitle())
                    } else { // use vague comparison methods
                        normTitle1 = simplifyMusicText(title: song!.getTitle(), broadSearch: true)
                        normTitle2 = simplifyMusicText(title: songRef!.getTitle(), broadSearch: true)
                    }
                    
                    let levNum = levDis(normTitle1, normTitle2)
                    if (levNum == 0) {
                        bestLevNumTitle = levNum
                        closeMatch = i
                        
                        let normAlbum1 = simplifyMusicText(title: song!.getAlbum(), broadSearch: true)
                        let normAlbum2 = simplifyMusicText(title: songRef!.getAlbum(), broadSearch: true)
                        
                        if ((song?.getTrackNum() == songRef!.getTrackNum()) && (song?.getExplicit() == songRef?.getExplicit()) && (normAlbum1 == normAlbum2)) {
                            matchFound = true
                            lookForCloseMatch = false
                            debugPrint("Marked as exact match (e2) ")
                        }
                    } else {
                        // get Levenshtein distance between song titles
                        debugPrint("Resorting to Levenshtein distance for song comparison")
                        
                        let levNum = levDis(normTitle1, normTitle2)
                        if (levNum <= bestLevNumTitle) {
                            debugPrint("Best title Lev distance: \(levNum)")
                            bestLevNumTitle = levNum
                            
                            closeMatch = i
                            
                            var normAlbum1: String
                            var normAlbum2: String
                            
                            if (!vagueMatching) {
                                normAlbum1 = normalizeString(str: song!.getAlbum())
                                normAlbum2 = normalizeString(str: songRef!.getAlbum())
                            } else { // use vague comparison methods
                                normAlbum1 = simplifyMusicText(title: song!.getAlbum(), broadSearch: true)
                                normAlbum2 = simplifyMusicText(title: songRef!.getAlbum(), broadSearch: true)
                            }
                            
                            let levAlbum = levDis(normAlbum1, normAlbum2)
                            
                            if (levAlbum < bestLevNumAlbum) {
                                debugPrint("Best album Lev distance: \(levNum)")
                                bestLevNumAlbum = levAlbum
                                
                                veryCloseMatch = i
                                veryCloseMatchFound = true
                                debugPrint("Marked as very close match (v3)")
                                if (song?.getTrackNum() == songRef!.getTrackNum() && song?.getExplicit() == songRef?.getExplicit()) {
                                    matchFound = true
                                    lookForCloseMatch = false
                                    debugPrint("Marked as exact match (e2)")
                                }
                            }
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
            } else if (veryCloseMatchFound) {
                let attributes = processed.tracks.items[veryCloseMatch!]
                var artists: [String] = []
                for i in attributes.artists {
                    artists.append(i.name)
                }
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit, trackNum: attributes.track_number)
                debugPrint("Found a very close match: \(veryCloseMatch!)")
                song?.setTranslatedURL(link: generateLink(uri: attributes.uri))
                song?.setTranslatedImgURL(link: attributes.album.images[1].url)
                
                // broaden search?
                return .veryClose
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
                return .close
            } else {
                debugPrint("No matches")
                return .none
            }
        } else {
            return .none
        }
        
        return .exact
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

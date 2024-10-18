//
//  SpotifyArtistData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/6/23.
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
class SpotifyArtistData {
    private let artistID: String?
    var artist: Artist? = nil
    
    init(artistID: String?) {
        self.artistID = artistID
    }
    
    private var spotifyArtistJSON: SpotifyArtistDataRoot? = nil
    private var spotifySearchJSON: SpotifyArtistSearchRoot? = nil
    
    /* Start of JSON decoding structs */
    private struct SpotifyArtistDataRoot: Decodable {
        let name: String
        let images: [ProfileImage]
        let uri: String
    }
    
    private struct ProfileImage: Decodable {
        let url: String
    }
    
    private struct SpotifyArtistSearchRoot: Decodable {
        let artists: Artists
    }
    
    private struct Artists: Decodable {
        let items: [SpotifyArtistDataRoot]
    }
    
    /**
     Assings local variable `spotifySongJSON` to decoded JSON after querying API for song data using a song ID.
     */
    func getSpotifyArtistDataByID() async {
        let url = URL(string: "\(serverAddress)/spotify/artist/id/\(artistID!)")!
        debugPrint("Querying: \(url.absoluteString)")
        let urlSession = URLSession(configuration: sessionConfig)
        do {
            let (data, response) = try await urlSession.data(from: url)
            urlSession.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            self.spotifyArtistJSON = try JSONDecoder().decode(SpotifyArtistDataRoot.self, from: data)
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    /**
     Assings local variable `spotifySearchJSON` to decoded JSON after querying API for song data using relevant search parameters.
     - Parameter songRef: Song object containing song data from the original source.
     - Parameter narrowSearch: Whether or not to use broad search terms or to be more specific.
     */
    func getSpotifyArtistDataBySearch(artistRef: String, narrowSearch: Bool) async {
        var artistStr = simplifyMusicText(title: artistRef, broadSearch: false)
        
        debugPrint("Artist: \(artistStr)")
        
        var searchParams: String
        if (narrowSearch) {
            searchParams = "\(artistStr)"
        } else {
            debugPrint("Performing broader search")
            artistStr  = simplifyMusicText(title: artistRef, broadSearch: true)
            
            searchParams = "\(artistStr)"
        }
        
        let url = URL(string: "\(serverAddress)/spotify/artist/search/\(searchParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
        debugPrint("Querying: \(url.absoluteString)")
        let urlSession = URLSession(configuration: sessionConfig)
        do {
            let (data, response) = try await urlSession.data(from: url)
            urlSession.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            self.spotifySearchJSON = try JSONDecoder().decode(SpotifyArtistSearchRoot.self, from: data)
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
    func parseToObject(artistRef: String?, vagueMatching: Bool) -> TranslationMatchLevel {
        if let processed = spotifyArtistJSON {
            artist = Artist(name: processed.name)
        } else if let processed = spotifySearchJSON {
            let resultsCount = processed.artists.items.count
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
//            var veryCloseMatch: Int? = nil
            var bestLevNumTitle = 1000
            var lookForCloseMatch: Bool = true
//            var veryCloseMatchFound: Bool = false
            while (resultsCount > i && !matchFound) {
                let attributes = processed.artists.items[i]
                
                artist = Artist(name: attributes.name)
                
                debugPrint("Apple Artist: \(simplifyMusicText(title: (artist?.getName())!, broadSearch: false))")
                debugPrint("Input Artist: \(simplifyMusicText(title: artistRef!, broadSearch: false))")
                
                if (lookForCloseMatch) {
                    var normTitle1: String
                    var normTitle2: String
                    
                    if (!vagueMatching) {
                        normTitle1 = normalizeString(str: artist!.getName())
                        normTitle2 = normalizeString(str: artistRef!)
                    } else { // use vague comparison methods
                        normTitle1 = simplifyMusicText(title: artist!.getName(), broadSearch: true)
                        normTitle2 = simplifyMusicText(title: artistRef!, broadSearch: true)
                    }
                    
                    let levNum = levDis(normTitle1, normTitle2)
                    if (levNum == 0) {
                        bestLevNumTitle = levNum
                        
                        matchFound = true
                        lookForCloseMatch = false
                        debugPrint("Marked as exact match (e1)")
                    } else {
                        // get Levenshtein distance between song titles
                        
                        let levNum = levDis(normTitle1, normTitle2)
                        if (levNum <= bestLevNumTitle) {
                            debugPrint("Best title Lev distance: \(levNum)")
                            bestLevNumTitle = levNum
                            
                            closeMatch = i
                        }
                    }
                }
                
                i += 1
                debugPrint(i)
            }
            
            if matchFound {
                let attributes = processed.artists.items[i - 1]
                
                artist = Artist(name: attributes.name)
                debugPrint("Found an exact match")
                
                artist?.setTranslatedURL(link: generateLink(uri: attributes.uri))
                artist?.setTranslatedImgURL(link: attributes.images[1].url)
//            } else if (veryCloseMatchFound) {
//                let attributes = processed.tracks.items[veryCloseMatch!]
//                var artists: [String] = []
//                for i in attributes.artists {
//                    artists.append(i.name)
//                }
//                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit, trackNum: attributes.track_number)
//                debugPrint("Found a very close match: \(veryCloseMatch!)")
//                song?.setTranslatedURL(link: generateLink(uri: attributes.uri))
//                song?.setTranslatedImgURL(link: attributes.album.images[1].url)
//
//                // broaden search?
//                return .veryClose
            } else if (closeMatch != nil) {
                let attributes = processed.artists.items[i - 1]
                
                artist = Artist(name: attributes.name)
                debugPrint("Found a close match")
                
                artist?.setTranslatedURL(link: generateLink(uri: attributes.uri))
                artist?.setTranslatedImgURL(link: attributes.images[1].url)
                
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
        return "https://open.spotify.com/artist/\(uri.suffix(from: uri.index(after: uri.lastIndex(of: ":")!)))"
    }
    
    /**
     Gets and returns the full list of `Artist` objects from decoded JSON data returned by API search.
     - Returns: `List` of `Artist` objects
     */
    func getAllArtists() -> [Artist] {
        debugPrint("Getting all songs")
        var artists: [Artist] = []
        if let processed = spotifySearchJSON {
            for i in processed.artists.items {
                let attributes = i
                
                let artistItem = Artist(name: attributes.name)
                artistItem.setTranslatedURL(link: generateLink(uri: attributes.uri))
                if (attributes.images.count > 1) {
                    artistItem.setTranslatedImgURL(link: attributes.images[1].url)
                }
                artists.append(artistItem)
            }
        }
        
        // if array returned is empty, then the UI should reflect that
        return artists
    }
}

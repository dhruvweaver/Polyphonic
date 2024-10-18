//
//  AppleMusicArtistData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/6/23.
//

import Foundation

/**
 Class containing functions and structures critical to communicating with Apple Music's database, and for identifying a matching song.
 - Note: `parseToObject()` function only parses objects once decoded JSON data has been assigned within the class. Call either of the `getSpotifySongData` methods to do so.
 ~~~
 // initialize object
 let appleMusicData = AppleMusicSongData("0123456789")
 
 // initialize decoded JSON data within AppleMusicSongData object
 appleMusicData.getSpotifySongDataByID()
 
 // parse data into something usable,
 // will store usable `Song` object in public variable
 let accurate = appleMusicData.parseToObject()
 // handle whether search results were accurate enough, if applicable
 let song = appleMusicData.song
 
 // do something with the song
 ~~~
 */
class AppleMusicArtistData {
    private let artistID: String?
    var artist: Artist? = nil
    var artwork: String = ""
    
    init(artistID: String?) {
        self.artistID = artistID
    }
    
    private var appleMusicArtistJSON: AppleMusicArtistDataRoot? = nil
    
    /* Start of JSON decoding structs */
    private struct AppleMusicArtistDataRoot: Decodable {
        let data: [AppleMusicArtistDataData]
    }
    
    private struct AppleMusicArtistDataData: Decodable {
        let attributes: AppleMusicArtistAttributes
    }
    
    private struct AppleMusicArtistAttributes: Decodable {
        let url: String
        let name: String
        let artwork: Artwork?
    }
    
    private struct Artwork: Decodable {
        let url: String
    }
    
    private var appleMusicArtistSearchJSON: AppleMusicArtistSearchRoot? = nil
    
    private struct AppleMusicArtistSearchRoot: Decodable {
        let results: AppleMusicArtistSearchResults
    }
    
    private struct AppleMusicArtistSearchResults: Decodable {
        let artists: AppleMusicSearchArtists
    }
    
    private struct AppleMusicSearchArtists: Decodable {
        let data: [AppleMusicArtistDataData]
    }
    
    /* End of JSON decoding structs */
    
    /**
     Assings local variable `appleMusicSongJSON` to decoded JSON after querying API for song data using a song ID.
     */
    func getAppleMusicArtistDataByID() async {
        let url = URL(string: "\(serverAddress)/apple/artist/id/\(artistID!)")!
        debugPrint("Querying: \(url.absoluteString)")
//        let authValue: String = "Bearer \(appleMusicAuthKey)"
//        sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
        let urlSession = URLSession(configuration: sessionConfig)
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            urlSession.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            self.appleMusicArtistJSON = try JSONDecoder().decode(AppleMusicArtistDataRoot.self, from: data)
            debugPrint("Decoded!")
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    /**
     Assings local variable `spotifySearchJSON` to decoded JSON after querying API for song data using relevant search parameters.
     - Parameter songRef: Song object containing song data from the original source.
     - Parameter narrowSearch: Whether or not to use broad search terms or to be more specific.
     */
    func getAppleMusicArtistDataBySearch(artistRef: String, narrowSearch: Bool) async {
        if (!narrowSearch) {
            debugPrint("Broad search beginning")
        }
        
        // clean metadata and convert it to a form that will work with the API
        var artistStr = simplifyMusicText(title: artistRef, broadSearch: false)
        artistStr = normalizeString(str: artistStr).replacingOccurrences(of: " ", with: "+")
        
        var searchParams: String
        if (narrowSearch) {
            debugPrint("Artist: \(artistStr)")
            
            searchParams = "\(artistStr)"
        } else {
            artistStr  = simplifyMusicText(title: artistRef, broadSearch: true)
            artistStr = normalizeString(str: artistStr).replacingOccurrences(of: " ", with: "+")
            
            debugPrint("Artist: \(artistStr)")
            
            searchParams = "\(artistStr)"
        }
        let urlString = "\(serverAddress)/apple/artist/search/\(searchParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        let url = URL(string: urlString)!
        debugPrint("Querying: \(url.absoluteString)")
//        let authValue: String = "Bearer \(appleMusicAuthKey)"
//        sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
        let urlSession = URLSession(configuration: sessionConfig)
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            urlSession.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            debugPrint("Trying to parse")
            self.appleMusicArtistSearchJSON = try JSONDecoder().decode(AppleMusicArtistSearchRoot.self, from: data)
            debugPrint("Decoded!")
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
            self.appleMusicArtistJSON = nil
        }
    }
    
    /**
     Parses data from decoded JSON to a song object. If the data came from search results more processing is required, and the original `Song` object is compared with the search results to find the best match.
     The function will then return a `Bool` indicating whether or not a broader search is needed.
     - Parameter songRef: Reference `Song` object for checking against search results. Not needed if processing results from an ID search.
     - Parameter vagueMatching: Whether or not to use vague matching techniques. Useful if no exact results have been found.
     - Returns: `TranslationMatchLevel` indicating how close the match was and whether or not a broader search is needed. See documentation for `TranslationMatchLevel` for more.
     - Note: `parseToObject()` function only parses objects once decoded JSON data has been assigned within the class. Call either of the `getAppleMusicSongData` methods to do so.
     */
    func parseToObject(artistRef: String?, vagueMatching: Bool) -> TranslationMatchLevel {
        print("Parsing...")
        if let processed = appleMusicArtistJSON {
            if (processed.data.endIndex >= 1) { // should prevent crashes when there are no results. Needs further testing
                let attributes = processed.data[processed.data.endIndex - 1].attributes
                
                artist = Artist(name: attributes.name)
                artist?.setTranslatedURL(link: attributes.url)
            }
        } else if let processed = appleMusicArtistSearchJSON {
            let resultsCount = processed.results.artists.data.count
            debugPrint("Number of results: \(resultsCount)")
            // handle case where search is too narrow
            if (resultsCount == 0) {
                debugPrint("Apple Music search too narrow")
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
                let attributes = processed.results.artists.data[i].attributes
                
                artist = Artist(name: attributes.name)
                
                debugPrint("Apple Artist: \(artist!.getName())")
                debugPrint("Input Artist: \(artistRef!)")
                
                debugPrint("Image URL: \(attributes.artwork!.url)")
                
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
            
            // get and assign the link for the best match possible, if any
            if matchFound {
                let attributes = processed.results.artists.data[i - 1].attributes // needs to backtrack one step since while loop is post increment
                
                artist = Artist(name: attributes.name)
                debugPrint("Found an exact match")
                artist?.setTranslatedURL(link: attributes.url)
                if let artwork = attributes.artwork {
                    self.artwork = getImageURLDimensions(link: artwork.url)
                    artist?.setTranslatedImgURL(link: getImageURLDimensions(link: artwork.url))
                }
                
                print("URL: \(artist!.getTranslatedURLasString())")
//            } else if (veryCloseMatchFound) { // NO SUCH THING RIGHT NOW
//                let attributes = processed.results.artists.data[i - 1].attributes // needs to backtrack one step since while loop is post increment
//
//                artist = Artist(name: attributes.name)
//                debugPrint("Found a very close match: \(veryCloseMatch!)")
//                artist?.setTranslatedURL(link: attributes.url)
//                artist?.setTranslatedImgURL(link: getImageURLDimensions(link: attributes.artwork.url))
//
//                print("URL: \(artist!.getTranslatedURLasString())")
//                // broaden search?
//                return .veryClose
            } else if (closeMatch != nil) {
                let attributes = processed.results.artists.data[i - 1].attributes // needs to backtrack one step since while loop is post increment
                
                artist = Artist(name: attributes.name)
                debugPrint("Found a close match")
                artist?.setTranslatedURL(link: attributes.url)
                if let artwork = attributes.artwork {
                    self.artwork = getImageURLDimensions(link: artwork.url)
                    artist?.setTranslatedImgURL(link: getImageURLDimensions(link: artwork.url))
                }
                
                print("URL: \(artist!.getTranslatedURLasString())")
                
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
     Does string manipulation on the album art URL to get album art of the right dimensions (300x300).
     - Parameter link: Unprocessed URL to album art. Contains `{w}x{h}` for size parameters
     - Returns: Modified URL to album art.
     */
    private func getImageURLDimensions(link: String) -> String {
        var newLink = ""
        
        newLink = link.replacingOccurrences(of: "{w}", with: "300")
        newLink = newLink.replacingOccurrences(of: "{h}", with: "300")
        
        return newLink
    }
    
    // parsed list of songs for user to override results with alternate results
    /**
     Gets and returns the full list of `Artist` objects from decoded JSON data returned by API search.
     - Returns: `List` of `Artist` objects
     */
    func getAllArtists() -> [Artist] {
        debugPrint("Getting all songs")
        var artists: [Artist] = []
        if let processed = appleMusicArtistSearchJSON {
            for i in processed.results.artists.data {
                let attributes = i.attributes
                
                let artistItem = Artist(name: attributes.name)
                artistItem.setTranslatedURL(link: attributes.url)
                if let artwork = attributes.artwork {
                    artistItem.setTranslatedImgURL(link: getImageURLDimensions(link: artwork.url))
                }
                artists.append(artistItem)
            }
        }
        
        // if array returned is empty, then the UI should reflect that
        return artists
    }
}

//
//  AppleMusicSongData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/12/22.
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
class AppleMusicSongData {
    private let songID: String?
    var song: Song? = nil
    
    init(songID: String?) {
        self.songID = songID
    }
    
    private var appleMusicSongJSON: AppleMusicSongDataRoot? = nil
    
    /* Start of JSON decoding structs */
    private struct AppleMusicSongDataRoot: Decodable {
        let data: [AppleMusicSongDataData]
    }
    
    private struct AppleMusicSongDataData: Decodable {
        let attributes: AppleMusicAttributes
        let relationships: AppleMusicRelationships
    }
    
    private struct AppleMusicRelationships: Decodable {
        let albums: AppleMusicAlbumsData
    }
    
    private struct AppleMusicAlbumsData: Decodable {
        let data: [RelationshipsData]
    }
    
    private struct RelationshipsData: Decodable {
        let id: String
    }
    
    private struct AppleMusicAttributes: Decodable {
        let artistName: String
        let artwork: Artwork
        let url: String
        let name: String
        let isrc: String
        let trackNumber: Int
        let albumName: String
        let contentRating: String?
    }
    
    private struct Artwork: Decodable {
        let url: String
    }
    
    private var appleMusicSearchJSON: AppleMusicSearchRoot? = nil
    
    private struct AppleMusicSearchRoot: Decodable {
        let results: AppleMusicSearchResults
    }
    
    private struct AppleMusicSearchResults: Decodable {
        let songs: AppleMusicSearchSongs
    }
    
    private struct AppleMusicSearchSongs: Decodable {
        let data: [AppleMusicSearchData]
    }
    
    private struct AppleMusicSearchData: Decodable {
        let attributes: AppleMusicAttributes
    }
    /* End of JSON decoding structs */
    
    /**
     Assings local variable `appleMusicSongJSON` to decoded JSON after querying API for song data using a song ID.
     */
    func getAppleMusicSongDataByID() async {
        let url = URL(string: "\(serverAddress)/apple/song/id/\(songID!)")!
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
            self.appleMusicSongJSON = try JSONDecoder().decode(AppleMusicSongDataRoot.self, from: data)
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
    func getAppleMusicSongDataBySearch(songRef: Song, narrowSearch: Bool) async {
        if (!narrowSearch) {
            debugPrint("Broad search beginning")
        }
        
        // clean metadata and convert it to a form that will work with the API
        var songStr = songRef.getTitle()
        var artistStr = songRef.getArtists()[0]
        
        songStr = simplifyMusicText(title: songStr, broadSearch: false).replacingOccurrences(of: " ", with: "+")
        artistStr = normalizeString(str: artistStr).replacingOccurrences(of: " ", with: "+")
        
        var searchParams: String
        if (narrowSearch) {
            debugPrint("Song: \(songStr)")
            debugPrint("Artist: \(artistStr)")
            // album name removed from query. May reduce accuracy and/or increase search time, but may also help with getting the right results
            searchParams = "\(songStr)+\(artistStr)"
        } else {
            songStr = simplifyMusicText(title: songRef.getTitle(), broadSearch: true).replacingOccurrences(of: " ", with: "+")
            artistStr  = simplifyMusicText(title: songRef.getArtists()[0], broadSearch: true).replacingOccurrences(of: " ", with: "+")
            
            debugPrint("Song: \(songStr)")
            debugPrint("Artist: \(artistStr)")
            
            searchParams = "\(songStr)+\(artistStr)"
        }
        let urlString = "\(serverAddress)/apple/song/search/\(searchParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
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
            self.appleMusicSearchJSON = try JSONDecoder().decode(AppleMusicSearchRoot.self, from: data)
            debugPrint("Decoded!")
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
            self.appleMusicSongJSON = nil
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
    func parseToObject(songRef: Song?, vagueMatching: Bool) -> TranslationMatchLevel {
        print("Parsing...")
        if let processed = appleMusicSongJSON {
            if (processed.data.endIndex >= 1) { // should prevent crashes when there are no results. Needs further testing
                let attributes = processed.data[processed.data.endIndex - 1].attributes
                var explicit: Bool = false
                if (attributes.contentRating == "explicit") {
                    explicit = true
                }
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName, albumID: processed.data[processed.data.endIndex - 1].relationships.albums.data[0].id, explicit: explicit, trackNum: attributes.trackNumber)
                song?.setTranslatedURL(link: attributes.url)
            }
        } else if let processed = appleMusicSearchJSON {
            let resultsCount = processed.results.songs.data.count
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
            var veryCloseMatch: Int? = nil
            var bestLevNumTitle = 1000
            var bestLevNumAlbum = 5
            var lookForCloseMatch: Bool = true
            var veryCloseMatchFound: Bool = false
            while (resultsCount > i && !matchFound) {
                let attributes = processed.results.songs.data[i].attributes
                var explicit: Bool = false
                if (attributes.contentRating == "explicit") {
                    explicit = true
                }
                let albumID = URL(string: attributes.url)!.lastPathComponent
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName, albumID: albumID, explicit: explicit, trackNum: attributes.trackNumber)
                debugPrint(song!.getISRC())
                debugPrint(songRef!.getISRC())
                debugPrint(song!.getArtists()[0])
                debugPrint(songRef!.getArtists()[0])
                debugPrint("Apple Album: \(simplifyMusicText(title: (song?.getAlbum())!, broadSearch: false))  - track: \(song!.getTrackNum())")
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
            
            // get and assign the link for the best match possible, if any
            if matchFound {
                let attributes = processed.results.songs.data[i - 1].attributes // needs to backtrack one step since while loop is post increment
                var explicit: Bool = false
                if (attributes.contentRating == "explicit") {
                    explicit = true
                }
                let albumID = URL(string: attributes.url)!.lastPathComponent
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName, albumID: albumID, explicit: explicit, trackNum: attributes.trackNumber)
                debugPrint("Found an exact match")
                song?.setTranslatedURL(link: attributes.url)
                song?.setTranslatedImgURL(link: getImageURLDimensions(link: attributes.artwork.url))
                
                print("URL: \(song!.getTranslatedURLasString())")
            } else if (veryCloseMatchFound) {
                let attributes = processed.results.songs.data[veryCloseMatch!].attributes
                var explicit: Bool = false
                if (attributes.contentRating == "explicit") {
                    explicit = true
                }
                let albumID = URL(string: attributes.url)!.lastPathComponent
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName, albumID: albumID, explicit: explicit, trackNum: attributes.trackNumber)
                debugPrint("Found a very close match: \(veryCloseMatch!)")
                song?.setTranslatedURL(link: attributes.url)
                song?.setTranslatedImgURL(link: getImageURLDimensions(link: attributes.artwork.url))
                debugPrint("Image: \(attributes.artwork.url)")
                
                // broaden search?
                return .veryClose
            } else if (closeMatch != nil) {
                let attributes = processed.results.songs.data[closeMatch!].attributes
                var explicit: Bool = false
                if (attributes.contentRating == "explicit") {
                    explicit = true
                }
                let albumID = URL(string: attributes.url)!.lastPathComponent
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName, albumID: albumID, explicit: explicit, trackNum: attributes.trackNumber)
                debugPrint("Found a close match")
                song?.setTranslatedURL(link: attributes.url)
                song?.setTranslatedImgURL(link: getImageURLDimensions(link: attributes.artwork.url))
                debugPrint("Image: \(attributes.artwork.url)")
                
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
     Gets and returns the full list of `Song` objects from decoded JSON data returned by API search.
     - Returns: `List` of `Song` objects
     */
    func getAllSongs() -> [Song] {
        debugPrint("Getting all songs")
        var songs: [Song] = []
        if let processed = appleMusicSearchJSON {
            for i in processed.results.songs.data {
                let attributes = i.attributes
                var explicit: Bool = false
                if (attributes.contentRating == "explicit") {
                    explicit = true
                }
                let albumID = URL(string: attributes.url)!.lastPathComponent
                let songItem = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName, albumID: albumID, explicit: explicit, trackNum: attributes.trackNumber)
                songItem.setTranslatedURL(link: attributes.url)
                songItem.setTranslatedImgURL(link: getImageURLDimensions(link: attributes.artwork.url))
                songs.append(songItem)
            }
        }
        
        // if array returned is empty, then the UI should reflect that
        return songs
    }
}


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
        let url = URL(string: "https://api.music.apple.com/v1/catalog/us/songs/\(songID!)")!
        debugPrint("Querying: \(url.absoluteString)")
        let sessionConfig = URLSessionConfiguration.default
        let authValue: String = "Bearer \(appleMusicAuthKey)"
        sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
        let urlSession = URLSession(configuration: sessionConfig)
        
        do {
            let (data, response) = try await urlSession.data(from: url)
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
        // clean metadata and convert it to a form that will work with the API
        var songStr = songRef.getTitle()
        songStr = songStr.replacingOccurrences(of: "(", with: "")
        songStr = songStr.replacingOccurrences(of: ")", with: "")
        songStr = cleanAppleMusicText(title: songStr, forSearching: true).replacingOccurrences(of: " ", with: "+")
        var albumStr = cleanAppleMusicText(title: songRef.getAlbum(), forSearching: true).replacingOccurrences(of: " ", with: "+")
        albumStr = albumStr.replacingOccurrences(of: songStr, with: "")
        let artistStr = cleanArtistName(name: songRef.getArtists()[0], forSearching: true).replacingOccurrences(of: " ", with: "+")
        debugPrint("Song: \(songStr)")
        debugPrint("Album: \(albumStr)")
        debugPrint("Artist: \(artistStr)")
        
        var searchParams: String
        if (narrowSearch) {
            // album name removed from query. May reduce accuracy and/or increase search time, but may also help with getting the right results
            searchParams = "\(songStr)+\(artistStr)"
        } else {
            searchParams = "\(songStr)+\(artistStr)"
        }
        let urlString = "https://api.music.apple.com/v1/catalog/us/search?types=songs&term=\(searchParams)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: urlString)!
        debugPrint("Querying: \(url.absoluteString)")
        let sessionConfig = URLSessionConfiguration.default
        let authValue: String = "Bearer \(appleMusicAuthKey)"
        sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
        let urlSession = URLSession(configuration: sessionConfig)
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            self.appleMusicSearchJSON = try JSONDecoder().decode(AppleMusicSearchRoot.self, from: data)
            debugPrint("Decoded!")
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    /**
     Parses data from decoded JSON to a song object. If the data came from search results more processing is required, and the original `Song` object is compared with the search results to find the best match.
     The function will then return a `Bool` indicating whether or not a broader search is needed.
     - Parameter songRef: Reference `Song` object for checking against search results. Not needed if processing results from an ID search.
     - Returns: `Bool` indicating whether or not a broader search is needed. `True` means results were acceptable.
     - Note: `parseToObject()` function only parses objects once decoded JSON data has been assigned within the class. Call either of the `getAppleMusicSongData` methods to do so.
     */
    func parseToObject(songRef: Song?) -> Bool {
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
                return false
            }
            
            var i = 0
            var matchFound: Bool! = false
            var closeMatch: Int? = nil
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
                debugPrint("Apple Album: \(cleanSpotifyText(title: (song?.getAlbum())!, forSearching: false))")
                debugPrint("Input Album: \(cleanSpotifyText(title: (songRef?.getAlbum())!, forSearching: false))")
                
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
                    } else if (cleanSpotifyText(title: (song?.getAlbum())!, forSearching: false) == cleanSpotifyText(title: songRef!.getAlbum(), forSearching: false)) {
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
                return veryCloseMatchFound
            } else {
                debugPrint("No matches")
                return false
            }
        }
        
        return true
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


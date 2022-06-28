//
//  AppleMusicSongData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/12/22.
//

import Foundation

class AppleMusicSongData {
    private let songID: String?
    var song: Song? = nil
    
    init(songID: String?) {
        self.songID = songID
    }
    
    private var appleMusicSongJSON: AppleMusicSongDataRoot? = nil
    
    private struct AppleMusicSongDataRoot: Decodable {
        let data: [AppleMusicSongDataData]
    }
    
    private struct AppleMusicSongDataData: Decodable {
        let attributes: AppleMusicAttributes
        let relationships: AppleMusicRelationships
    }
    
    private struct AppleMusicRelationships: Decodable {
        let data: [RelationshipsData]
    }
    
    private struct RelationshipsData: Decodable {
        let id: String
    }
    
    private struct AppleMusicAttributes: Decodable {
        let artistName: String
        let url: String
        let name: String
        let isrc: String
        let albumName: String
        let contentRating: String?
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
    
    // TODO: NEEDS LOTS OF WORK ON NULL SAFETY
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
            searchParams = songStr
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
    
    // TODO: Needs to differentiate between songs released as a single vs those released with the album. Right now it tends to only pick the album version
    func parseToObject(songRef: Song?) -> Bool {
        print("Parsing...")
        if let processed = appleMusicSongJSON {
            if (processed.data.endIndex >= 1) { // should prevent crashes when there are no results. Needs further testing
                let attributes = processed.data[processed.data.endIndex - 1].attributes
                var explicit: Bool = false
                if (attributes.contentRating == "explicit") {
                    explicit = true
                }
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName, albumID: processed.data[processed.data.endIndex - 1].relationships.data[0].id, explicit: explicit)
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
            while (resultsCount > i && !matchFound) {
                let attributes = processed.results.songs.data[i].attributes
                var explicit: Bool = false
                if (attributes.contentRating == "explicit") {
                    explicit = true
                }
                let albumID = URL(string: attributes.url)!.lastPathComponent
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName, albumID: albumID, explicit: explicit)
                debugPrint(song!.getISRC())
                debugPrint(songRef!.getISRC())
                debugPrint(song!.getArtists()[0])
                debugPrint(songRef!.getArtists()[0])
                debugPrint("Apple Album: \(song!.getAlbum())")
                debugPrint("Input Album: \(songRef!.getAlbum())")
                
                // if there is an exact match with the ISRC, then the search can stop
                if (cleanAppleMusicText(title: song!.getAlbum(), forSearching: true) == cleanAppleMusicText(title: songRef!.getAlbum(), forSearching: true)) {
                    if (song?.getISRC() == songRef!.getISRC() && song?.getExplicit() == songRef?.getExplicit()) {
                        matchFound = true
                    } else {
                        closeMatch = i
                    }
                    // if there is not an exact match, look for the next best match. If there are still alternatives, keep looking for an exact match
                } else if (lookForCloseMatch && song?.getExplicit() == songRef?.getExplicit() && (((song?.getAlbum() == songRef!.getAlbum() || cleanAppleMusicText(title: (song?.getAlbum())!, forSearching: false) == cleanAppleMusicText(title: songRef!.getAlbum(), forSearching: false)) && cleanAppleMusicText(title: (song?.getTitle())!, forSearching: false) == cleanAppleMusicText(title: songRef!.getTitle(), forSearching: false) && cleanArtistName(name: song!.getArtists()[0], forSearching: false) == cleanArtistName(name: songRef!.getArtists()[0], forSearching: false)))) {
                    debugPrint("Marked as close match")
                    // bookmark and come back to this one if nothing else matches
                    closeMatch = i
                    lookForCloseMatch = false
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
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName, albumID: albumID, explicit: explicit)
                debugPrint("Found an exact match")
                song?.setTranslatedURL(link: attributes.url)
                print("URL: \(song!.getTranslatedURLasString())")
            } else if (closeMatch != nil) {
                let attributes = processed.results.songs.data[closeMatch!].attributes
                var explicit: Bool = false
                if (attributes.contentRating == "explicit") {
                    explicit = true
                }
                let albumID = URL(string: attributes.url)!.lastPathComponent
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName, albumID: albumID, explicit: explicit)
                debugPrint("Found a close match")
                song?.setTranslatedURL(link: attributes.url)
            } else {
                debugPrint("No matches")
            }
        }
        
        return true
    }
}


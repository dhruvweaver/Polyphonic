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
            searchParams = "\(songStr)+\(artistStr)+\(albumStr)"
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
                debugPrint("Apple Album: \(cleanSpotifyText(title: (song?.getAlbum())!, forSearching: true))")
                debugPrint("Input Album: \(cleanSpotifyText(title: songRef!.getAlbum(), forSearching: true))")
                
                if (song?.getISRC() == songRef!.getISRC()) {
                    if (cleanText(title: song!.getAlbum()) == cleanText(title: songRef!.getAlbum())) {
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
                    if (cleanText(title: song!.getAlbum()) == cleanText(title: songRef!.getAlbum())) {
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
            }
        }
        
        return true
    }
    
    private func getImageURLDimensions(link: String) -> String {
        var newLink = ""
        
        newLink = link.replacingOccurrences(of: "{w}", with: "300")
        newLink = newLink.replacingOccurrences(of: "{h}", with: "300")
        
        return newLink
    }
}


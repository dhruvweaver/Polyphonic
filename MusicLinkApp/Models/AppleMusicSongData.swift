//
//  AppleMusicSongData.swift
//  MusicLinkApp
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
    
    var appleMusicSongJSON: AppleMusicSongDataRoot? = nil
    
    struct AppleMusicSongDataRoot: Decodable {
        let data: [AppleMusicSongDataData]
    }
    
    struct AppleMusicSongDataData: Decodable {
        let attributes: AppleMusicAttributes
    }
    
    struct AppleMusicAttributes: Decodable {
        let artistName: String
        let url: String
        let name: String
        let isrc: String
        let albumName: String
    }
    
    private var appleMusicSearchJSON: AppleMusicSearchRoot? = nil
    
    struct AppleMusicSearchRoot: Decodable {
        let results: AppleMusicSearchResults
    }
    
    struct AppleMusicSearchResults: Decodable {
        let songs: AppleMusicSearchSongs
    }
    
    struct AppleMusicSearchSongs: Decodable {
        let data: [AppleMusicSearchData]
    }
    
    struct AppleMusicSearchData: Decodable {
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
    func getAppleMusicSongDataBySearch(songRef: Song) async {
        var songStr = songRef.getTitle().lowercased().replacingOccurrences(of: " ", with: "+")
        songStr = songStr.replacingOccurrences(of: "(", with: "")
        songStr = songStr.replacingOccurrences(of: ")", with: "")
        songStr = cleanSongTitle(title: songStr, forSearching: true)
        var albumStr = songRef.getAlbum().lowercased().replacingOccurrences(of: " ", with: "+")
        albumStr = cleanSongTitle(title: albumStr, forSearching: true)
        let artistStr = songRef.getArtists()[0].lowercased().replacingOccurrences(of: " ", with: "+")
        debugPrint("Song: \(songStr)")
        debugPrint("Album: \(albumStr)")
        debugPrint("Artist: \(artistStr)")
        
        let urlString = "https://api.music.apple.com/v1/catalog/us/search?types=songs&term=\(songStr)+\(albumStr)+\(artistStr)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
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
    
    // removes items in parentheses and after dashes
    private func cleanSongTitle(title: String, forSearching: Bool) -> String {
        var clean = title
        if let indDash = clean.firstIndex(of: "-") {
            clean = String(clean[clean.startIndex...clean.index(indDash, offsetBy: -2)])
        }
        if let indParen = clean.firstIndex(of: "(") {
            clean = String(clean[clean.startIndex...clean.index(indParen, offsetBy: -2)])
        }
        
        clean = clean.replacingOccurrences(of: "/", with: "")
        clean = clean.replacingOccurrences(of: "\\", with: "")
        clean = clean.replacingOccurrences(of: "'", with: "")
        clean = clean.replacingOccurrences(of: "\"", with: "")
        
        if (forSearching) {
            if (title.contains("Remix") && !clean.contains("Remix")) {
                clean.append(contentsOf: "+remix")
            }
            if (title.contains("Deluxe") && !clean.contains("Deluxe")) {
                clean.append(contentsOf: "+deluxe")
            }
            if (title.contains("Acoustic") && !clean.contains("Acoustic")) {
                clean.append(contentsOf: "+acoustic")
            }
            if (title.contains("Demo") && !clean.contains("Demo")) {
                clean.append(contentsOf: "+demo")
            }
            debugPrint(clean)
        }
        
        clean = clean.lowercased()
        
        return clean
    }
    
    // TODO: Needs to differentiate between songs released as a single vs those released with the album. Right now it tends to only pick the album version
    // new processing ideas: identify songs with cleaned titles and albums, compare by date and ISRC, primarily
    // clean artist results with '&' character, somehow avoid splitting artists like "Simon & Garfunkel"
    func parseToObject(songRef: Song?) {
        print("Parsing...")
        if let processed = appleMusicSongJSON {
            if (processed.data.endIndex >= 1) { // should prevent crashes when there are no results. Needs further testing
                let attributes = processed.data[processed.data.endIndex - 1].attributes
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName)
                song?.setTranslatedURL(link: attributes.url)
            }
        } else if let processed = appleMusicSearchJSON {
            var i = 0
            var matchFound: Bool = false
            var closeMatch: Int? = nil
            var lookForCloseMatch: Bool = true
            while processed.results.songs.data.count > i && !matchFound {
                let attributes = processed.results.songs.data[i].attributes
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName)
                debugPrint(song!.getISRC())
                debugPrint(songRef!.getISRC())
                debugPrint("Input   Album: \(songRef!.getAlbum())")
                debugPrint("Spotify Album: \(song!.getAlbum())")
                
                if (song?.getISRC() == songRef!.getISRC()) && (((song?.getAlbum() == songRef!.getAlbum() || cleanSongTitle(title: (song?.getAlbum())!, forSearching: false) == cleanSongTitle(title: songRef!.getAlbum(), forSearching: false)))) {
                    matchFound = true
                } else if (lookForCloseMatch && !(song?.getISRC() == songRef!.getISRC()) && (((song?.getAlbum() == songRef!.getAlbum() || cleanSongTitle(title: (song?.getAlbum())!, forSearching: false) == cleanSongTitle(title: songRef!.getAlbum(), forSearching: false)) && cleanSongTitle(title: (song?.getTitle())!, forSearching: false) == cleanSongTitle(title: songRef!.getTitle(), forSearching: false) && song?.getArtists()[0] == songRef!.getArtists()[0]))) {
                    debugPrint("Found close match")
                    // bookmark and come back to this one if nothing else
                    closeMatch = i
                    lookForCloseMatch = false
                }
                
                i += 1
                debugPrint(i)
            }
            
            if matchFound {
                let attributes = processed.results.songs.data[i - 1].attributes
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName)
                debugPrint("Found an exact match")
                song?.setTranslatedURL(link: attributes.url)
            } else if (!matchFound && closeMatch != nil) {
                let attributes = processed.results.songs.data[closeMatch!].attributes
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName)
                debugPrint("Found a close match")
                song?.setTranslatedURL(link: attributes.url)
            } else {
                debugPrint("No matches")
            }
        }
    }
}


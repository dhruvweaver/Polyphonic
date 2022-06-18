//
//  SpotifySongData.swift
//  MusicLinkApp
//
//  Created by Dhruv Weaver on 6/12/22.
//

import Foundation

class SpotifySongData {
    private let songID: String?
    private let authKey: String!
    var song: Song? = nil
    
    init(songID: String?, authKey: String) {
        self.songID = songID
        self.authKey = authKey
    }
    
    var spotifySongJSON: SpotifySongDataRoot? = nil
    var spotifySearchJSON: SpotifySongSearchRoot? = nil
    
    struct SpotifySongDataRoot: Decodable {
        let album: Album
        let artists: [Artist]
        let external_ids: ExternalIDs
        let name: String
        let uri: String
    }
    
    struct Album: Decodable {
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
    
    func getSpotifySongDataByID() async {
        let url = URL(string: "https://api.spotify.com/v1/tracks/\(songID!)")!
        let sessionConfig = URLSessionConfiguration.default
        let authValue: String = "Bearer \(authKey!)"
        sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
        let urlSession = URLSession(configuration: sessionConfig)
        do {
            let (data, _) = try await urlSession.data(from: url)
            //            if let httpResponse = response as? HTTPURLResponse {
            //                print(httpResponse.statusCode)
            //            }
            self.spotifySongJSON = try JSONDecoder().decode(SpotifySongDataRoot.self, from: data)
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    func getSpotifySOngDatayBySearch(songRef: Song) async {
        var songStr = songRef.getTitle()
        //        songStr = songStr.replacingOccurrences(of: "(", with: "")
        //        songStr = songStr.replacingOccurrences(of: ")", with: "")
        songStr = cleanSongTitle(title: songStr, forSearching: true)
        let artistStr = songRef.getArtists()[0]
        
        let searchParams = "track:\(songStr) artist:\(artistStr)&type=track"
        
        let url = URL(string: "https://api.spotify.com/v1/search?q=\(searchParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
        debugPrint("Querying: \(url.absoluteString)")
        let sessionConfig = URLSessionConfiguration.default
        let authValue: String = "Bearer \(authKey!)"
        debugPrint(authKey!)
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
    
    private func generateLink(uri: String) -> String {
        return "https://open.spotify.com/track/\(uri.suffix(from: uri.index(after: uri.lastIndex(of: ":")!)))"
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
                clean.append(contentsOf: " remix")
            }
            if (title.contains("Deluxe") && !clean.contains("Deluxe")) {
                clean.append(contentsOf: " deluxe")
            }
            if (title.contains("Acoustic") && !clean.contains("Acoustic")) {
                clean.append(contentsOf: " acoustic")
            }
            if (title.contains("Demo") && !clean.contains("Demo")) {
                clean.append(contentsOf: " demo")
            }
            debugPrint(clean)
        }
        
        clean = clean.lowercased()
        
        return clean
    }
    
    func parseToObject(songRef: Song?) {
        if let processed = spotifySongJSON {
            var artists: [String] = []
            for i in processed.artists {
                artists.append(i.name)
            }
            song = Song(title: processed.name, ISRC: processed.external_ids.isrc, artists: artists, album: processed.album.name)
        } else if let processed = spotifySearchJSON {
            var i = 0
            var matchFound: Bool = false
            var closeMatch: Int? = nil
            var lookForCloseMatch: Bool = true
            while processed.tracks.items.count > i && !matchFound {
                let attributes = processed.tracks.items[i]
                var artists: [String] = []
                for j in attributes.artists {
                    artists.append(j.name)
                }
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name)
                debugPrint(song!.getISRC())
                debugPrint(songRef!.getISRC())
                debugPrint("Input Album: \(songRef!.getAlbum())")
                debugPrint("Apple Album: \(song!.getAlbum())")
                
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
                let attributes = processed.tracks.items[i - 1]
                var artists: [String] = []
                for i in attributes.artists {
                    artists.append(i.name)
                }
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name)
                debugPrint("Found an exact match")
                song?.setTranslatedURL(link: generateLink(uri: attributes.uri))
            } else if (!matchFound && closeMatch != nil) {
                let attributes = processed.tracks.items[closeMatch!]
                var artists: [String] = []
                for i in attributes.artists {
                    artists.append(i.name)
                }
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name)
                debugPrint("Found a close match")
                song?.setTranslatedURL(link: generateLink(uri: attributes.uri))
            }
        }
    }
}

//
//  AppleMusicSongData.swift
//  MusicLinkApp
//
//  Created by Dhruv Weaver on 6/12/22.
//

import Foundation

class AppleMusicSongData {
    private let songID: String?
    private let songISRC: String!
    var song: Song? = nil
    
    init(songID: String?, songISRC: String) {
        self.songID = songID
        self.songISRC = songISRC
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
    
    var appleMusicSearchJSON: AppleMusicSearchRoot? = nil
    
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
    
    func getAppleMusicSongDataBySearch(songRef: Song) async {
        var songStr = songRef.getTitle().lowercased().replacingOccurrences(of: " ", with: "+")
        if let indDash = songStr.firstIndex(of: "-") {
            songStr = String(songStr[songStr.startIndex...songStr.index(indDash, offsetBy: -2)])
        }
        let albumStr = songRef.getAlbum().lowercased().replacingOccurrences(of: " ", with: "+")
        let artistStr = songRef.getArtists()[0].lowercased().replacingOccurrences(of: " ", with: "+")
        debugPrint("Song: \(songStr)")
        debugPrint("Album: \(albumStr)")
        debugPrint("Artist: \(artistStr)")
        
        
        let url = URL(string: "https://api.music.apple.com/v1/catalog/us/search?types=songs&term=\(songStr)+\(albumStr)+\(artistStr)")!
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
    func parseToObject(songRef: Song) {
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
            while processed.results.songs.data.count > i && !matchFound {
                let attributes = processed.results.songs.data[i].attributes
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName)
                debugPrint(song!.getISRC())
                debugPrint(songRef.getISRC())
                matchFound = (song?.getAlbum() == songRef.getAlbum() || song?.getISRC() == songRef.getISRC() || song?.getArtists()[0] == songRef.getArtists()[0])
                song?.setTranslatedURL(link: attributes.url)
                
                i += 1
                debugPrint(i)
            }
        }
    }
}


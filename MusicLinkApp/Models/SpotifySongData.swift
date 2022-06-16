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
        let songStr = songRef.getTitle()
        let artistStr = songRef.getArtists()[0]
        
        let searchParams = "track:\(songStr) artist:\(artistStr)&type=track"
        
        let url = URL(string: "https://api.spotify.com/v1/search?q=\(searchParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
        let sessionConfig = URLSessionConfiguration.default
        let authValue: String = "Bearer \(authKey!)"
        sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
        let urlSession = URLSession(configuration: sessionConfig)
        do {
            let (data, _) = try await urlSession.data(from: url)
            //            if let httpResponse = response as? HTTPURLResponse {
            //                print(httpResponse.statusCode)
            //            }
            self.spotifySearchJSON = try JSONDecoder().decode(SpotifySongSearchRoot.self, from: data)
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    private func generateLink(uri: String) -> String {
        var linkStr = ""
        print(uri)
        linkStr = "https://open.spotify.com/track/\(uri.suffix(from: uri.index(after: uri.lastIndex(of: ":")!)))"
        print(linkStr)
        return linkStr
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
            while processed.tracks.items.count > i && !matchFound {
                let attributes = processed.tracks.items[i]
                var artists: [String] = []
                for i in attributes.artists {
                    artists.append(i.name)
                }
                song = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name)
                debugPrint(song!.getISRC())
                debugPrint(songRef!.getISRC())
                matchFound = (song?.getAlbum() == songRef!.getAlbum() || song?.getISRC() == songRef!.getISRC() || song?.getArtists()[0] == songRef!.getArtists()[0])
                song?.setTranslatedURL(link: generateLink(uri: attributes.uri))
                
                i += 1
                debugPrint(i)
            }
        }
    }
    
    // TODO: get/make Spotify link from API response and send to translatedURL of Song object
}

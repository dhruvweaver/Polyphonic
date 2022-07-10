//
//  SpotifyAlbumData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/27/22.
//

import Foundation

class SpotifyAlbumData {
    private let albumID: String?
    var album: Album? = nil
    
    init(albumID: String?) {
        self.albumID = albumID
    }
    
    private var spotifyAlbumJSON: SpotifyAlbumDataRoot? = nil
//    private var spotifyAlbumSearchJSON: SpotifyAlbumSearchRoot? = nil
    
    struct SpotifyAlbumDataRoot: Decodable {
        let artists: [Artist]
        let external_ids: ExternalIDs
        let name: String
        let label: String
        let id: String
        let tracks: MusicItems
        let total_tracks: Int
    }
    
    struct Artist: Decodable {
        let name: String
    }
    
    struct ExternalIDs: Decodable {
        let upc: String
    }
    
    struct MusicItems: Decodable {
        let items: [Item]
    }
    
    struct Item: Decodable {
        let explicit: Bool
        let id: String
    }
    
    private var spotifyAccessJSON: SpotifyAccessData? = nil
    struct SpotifyAccessData: Decodable {
        let access_token: String
    }
    
    func getSpotifyAuthKey() async -> String? {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        let urlSession = URLSession.shared
        let spotifyClientString = (spotifyClientID + ":" + spotifyClientSecret).toBase64()
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(spotifyClientString)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let postString = "grant_type=client_credentials"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        do {
            let (data, _) = try await urlSession.data(for: request)
            spotifyAccessJSON = try JSONDecoder().decode(SpotifyAccessData.self, from: data)
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
        
        var accessKey: String? = nil
        
        if let processed = spotifyAccessJSON {
            accessKey = processed.access_token
        }
        
        return accessKey
    }
    
    var spotifyURL: String = ""
    
    func getSpotifyAlbumDataByID() async {
        let url = URL(string: "https://api.spotify.com/v1/albums/\(albumID!)")!
        let sessionConfig = URLSessionConfiguration.default
        // get authorization key from Spotify
        if let authKey = await getSpotifyAuthKey() {
            let authValue: String = "Bearer \(authKey)"
            sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
            let urlSession = URLSession(configuration: sessionConfig)
            do {
                let (data, response) = try await urlSession.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse.statusCode)
                }
                self.spotifyAlbumJSON = try JSONDecoder().decode(SpotifyAlbumDataRoot.self, from: data)
                if let parsedData = spotifyAlbumJSON {
                    spotifyURL = "https://open.spotify.com/album/\(parsedData.id)"
                }
            } catch {
                debugPrint("Error loading \(url): \(String(describing: error))")
            }
        }
    }
    
    func parseToObject(songRef: Song?) -> Bool {
        if let processed = spotifyAlbumJSON {
            var artists: [String] = []
            for i in processed.artists {
                artists.append(i.name)
            }
            
            // see if the album contains any explicit tracks; this will help to get the right version of the right album later
            var keySongID = processed.tracks.items[0].id
            for i in processed.tracks.items {
                if (i.explicit) {
                    keySongID = i.id
                }
            }
            
            album = Album(title: processed.name, UPC: processed.external_ids.upc, artists: artists, songCount: processed.total_tracks, label: processed.label)
            album?.setKeySongID(id: keySongID)
        }
        
        return true
    }
}

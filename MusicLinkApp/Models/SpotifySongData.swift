//
//  SpotifySongData.swift
//  MusicLinkApp
//
//  Created by Dhruv Weaver on 6/12/22.
//

import Foundation

class SpotifySongData {
    private let songID: String!
    private let authKey: String!
    var song: Song? = nil
    
    init(songID: String, authKey: String) {
        self.songID = songID
        self.authKey = authKey
    }
    
    var spotifySongJSON: SpotifySongDataRoot? = nil
    
    struct SpotifySongDataRoot: Decodable {
        let album: Album
        let artists: [Artist]
        let external_ids: ExternalIDs
        let name: String
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
    
    
    func getSpotifySongData() async {
        let url = URL(string: "https://api.spotify.com/v1/tracks/\(songID!)")!
        let sessionConfig = URLSessionConfiguration.default
        let authValue: String = "Bearer \(authKey!)"
        sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
        let urlSession = URLSession(configuration: sessionConfig)
        print("Auth: \(authKey!)")
        do {
            let (data, response) = try await urlSession.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            self.spotifySongJSON = try JSONDecoder().decode(SpotifySongDataRoot.self, from: data)
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    func parseToObject() {
        if let processed = spotifySongJSON {
            var artists: [String] = []
            for i in processed.artists {
                artists.append(i.name)
            }
            song = Song(title: processed.name, ISRC: processed.external_ids.isrc, artists: artists, album: processed.album.name)
        }
    }
}

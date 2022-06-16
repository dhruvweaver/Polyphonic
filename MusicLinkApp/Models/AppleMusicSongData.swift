//
//  AppleMusicSongData.swift
//  MusicLinkApp
//
//  Created by Dhruv Weaver on 6/12/22.
//

import Foundation
import MusicKit

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
    
    func getAppleMusicSongDataByISRC() async {
        let url = URL(string: "https://api.music.apple.com/v1/catalog/us/songs?filter[isrc]=\(songISRC!)")!
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
            print("Decoded!")
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    func parseToObject() {
        print("Parsing...")
        if let processed = appleMusicSongJSON {
            if (processed.data.endIndex >= 1) { // should prevent crashes when there are no results. Needs further testing
                let attributes = processed.data[processed.data.endIndex - 1].attributes
                song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName)
                song?.setTranslatedURL(link: attributes.url)
            }
        }
    }
}


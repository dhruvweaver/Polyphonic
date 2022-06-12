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
        let data: AppleMusicSongDataData
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
        let urlSession = URLSession.shared
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            self.appleMusicSongJSON = try JSONDecoder().decode(AppleMusicSongDataRoot.self, from: data)
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    func parseToObject() {
        if let processed = appleMusicSongJSON {
            let attributes = processed.data.attributes
            song = Song(title: attributes.name, ISRC: attributes.isrc, artists: [attributes.artistName], album: attributes.albumName)
            song?.setTranslatedURL(link: attributes.url)
        }
    }
}


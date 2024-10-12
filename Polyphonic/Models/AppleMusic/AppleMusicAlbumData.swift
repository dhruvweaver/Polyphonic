//
//  AppleMusicAlbumData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/27/22.
//

import Foundation

/**
 Class containing functions and structures critical to communicating with Apple Music's database, and for getting album data.
 - Note: `parseToObject()` function only parses objects once decoded JSON data has been assigned within the class. Call `getAppleMusicAlbumDataByID` to do so.
 ~~~
 // initialize object
 let appleMusicData = AppleMusicAlbumData())
 
 // initialize decoded JSON data within AppleMusicSongData object
 appleMusicData.getAppleMusicAlbumDataByID()
 
 // parse data into something usable,
 // will store usable `Album` object in public variable
 appleMusicData.parseToObject()
 let album = appleMusicData.album
 
 // do something with the album
 ~~~
 */
class AppleMusicAlbumData {
    private let albumID: String?
    var album: Album? = nil
    
    init(albumID: String?) {
        self.albumID = albumID
    }
    
        private var appleMusicAlbumJSON: AppleMusicAlbumDataRoot? = nil
    private var appleMusicAlbumSearchJSON: AppleMusicAlbumDataRoot? = nil
    
    private struct AppleMusicAlbumDataRoot: Decodable {
        let data: [AppleAlbumSearchData]
    }
    
    private struct AppleAlbumSearchData: Decodable {
        let attributes: AppleMusicAlbumAttributes
        let relationships: AppleMusicRelationships
    }
    
    // TODO: support single vs album
    private struct AppleMusicAlbumAttributes: Decodable {
        let artistName: String
        let url: String
        let trackCount: Int
        let name: String
        let recordLabel: String
        let upc: String
    }
    
    private struct AppleMusicRelationships: Decodable {
        let tracks: AppleMusicTrackData
    }
    
    private struct AppleMusicTrackData: Decodable {
        let data: [AppleMusicSongItem]
    }
    
    private struct AppleMusicSongItem: Decodable {
        let id: String
        let attributes: AppleMusicAttributes
    }
    
    private struct AppleMusicAttributes: Decodable {
        let contentRating: String?
    }
    
    var appleURL: String = ""
    
    /**
     Assings local variable `appleMusicAlbumJSON` to decoded JSON after querying API for album data using an album ID.
     */
    func getAppleAlbumDataByID() async {
        let url = URL(string: "\(serverAddress)/apple/album/id/\(albumID!)")!
        debugPrint("Querying: \(url.absoluteString)")
//        let authValue: String = "Bearer \(appleMusicAuthKey)"
//        sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
        let urlSession = URLSession(configuration: sessionConfig)

        do {
            let (data, response) = try await urlSession.data(from: url)
            urlSession.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.statusCode)
            }
            self.appleMusicAlbumJSON = try JSONDecoder().decode(AppleMusicAlbumDataRoot.self, from: data)
            if let parsedData = appleMusicAlbumJSON {
                appleURL = parsedData.data[0].attributes.url
            }
            debugPrint("Decoded!")
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    /**
     Parses data from decoded JSON to an album object.
     - Note: `parseToObject()` function only parses objects once decoded JSON data has been assigned within the class. Call `getAppleMusicAlbumDataByID` to do so.
     */
    func parseToObject(albumRef: Album?) -> Bool {
        if let processed = appleMusicAlbumJSON {
            if (processed.data.endIndex >= 1) {
                let attributes = processed.data[processed.data.endIndex - 1].attributes
                
                var keySongID = processed.data[processed.data.endIndex - 1].relationships.tracks.data[0].id
                for i in processed.data[processed.data.endIndex - 1].relationships.tracks.data {
                    if (i.attributes.contentRating == "explicit") {
                        keySongID = i.id
                    }
                }
                
                album = Album(title: attributes.name, UPC: attributes.upc, artists: [attributes.artistName], songCount: attributes.trackCount, label: attributes.recordLabel)
                album?.setKeySongID(id: keySongID)
            }
        }
        
        return true
    }
}

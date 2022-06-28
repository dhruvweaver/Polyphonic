//
//  AppleMusicAlbumData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/27/22.
//

import Foundation

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
        let attributes: AppleMusicAttributes
    }
    
    // TODO: support single vs album
    private struct AppleMusicAttributes: Decodable {
        let artistName: String
        let url: String
        let trackCount: Int
        let name: String
        let recordLabel: String
        let upc: String
    }
    
    var appleURL: String = ""
    
    func getAppleAlbumDataByID() async {
        let url = URL(string: "https://api.music.apple.com/v1/catalog/us/albums/\(albumID!)")!
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
            self.appleMusicAlbumJSON = try JSONDecoder().decode(AppleMusicAlbumDataRoot.self, from: data)
            if let parsedData = appleMusicAlbumJSON {
                appleURL = parsedData.data[0].attributes.url
            }
            debugPrint("Decoded!")
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
    }
    
    func parseToObject(albumRef: Album?) -> Bool {
        if let processed = appleMusicAlbumJSON {
            if (processed.data.endIndex >= 1) {
                let attributes = processed.data[processed.data.endIndex - 1].attributes
                album = Album(title: attributes.name, UPC: attributes.upc, artists: [attributes.artistName], songCount: attributes.trackCount, label: attributes.recordLabel)
            }
        } else if let processed = appleMusicAlbumSearchJSON {
            let resultsCount = processed.data.count
            
            var i = 0
            var matchFound: Bool! = false
            var closeMatch: Int? = nil
            var lookForCloseMatch: Bool = true
            while (resultsCount > i && !matchFound) {
                let attributes = processed.data[i].attributes
                album = Album(title: attributes.name, UPC: attributes.upc, artists: [attributes.artistName], songCount: attributes.trackCount, label: attributes.recordLabel)
                debugPrint(album!.getUPC())
                debugPrint(albumRef!.getUPC())
                debugPrint(album!.getArtists()[0])
                debugPrint(albumRef!.getArtists()[0])
                debugPrint("Apple Album: \(album!.getTitle())")
                debugPrint("Input Album: \(albumRef!.getTitle())")
                
                // if there is an exact match with the ISRC, then the search can stop
                if (album?.getTitle() == albumRef?.getTitle() && album?.getSongCount() == albumRef?.getSongCount() && album?.getLabel() == albumRef?.getLabel()) {
                    matchFound = true
                    // if there is not an exact match, look for the next best match. If there are still alternatives, keep looking for an exact match
                } else if (lookForCloseMatch && ((album?.getTitle() == albumRef?.getTitle() && album?.getSongCount() == albumRef?.getSongCount()) || (cleanText(title: (album?.getTitle())!) == cleanText(title: (albumRef?.getTitle())!) && album?.getLabel() == albumRef?.getLabel()))) {
                    debugPrint("Marked as close match")
                    // bookmark and come back to this one if nothing else matches
                    closeMatch = i
                    lookForCloseMatch = false
                }
                
                i += 1
                debugPrint(i)
            }
            
            // get and assign the link for the best match possible, if any
            if matchFound {
                let attributes = processed.data[i - 1].attributes // needs to backtrack one step since while loop is post increment
                album = Album(title: attributes.name, UPC: attributes.upc, artists: [attributes.artistName], songCount: attributes.trackCount, label: attributes.recordLabel)
                debugPrint("Found an exact match")
                album?.setTranslatedURL(link: attributes.url)
                print("URL: \(album!.getTranslatedURLasString())")
            } else if (closeMatch != nil) {
                let attributes = processed.data[closeMatch!].attributes
                album = Album(title: attributes.name, UPC: attributes.upc, artists: [attributes.artistName], songCount: attributes.trackCount, label: attributes.recordLabel)
                debugPrint("Found a close match")
                album?.setTranslatedURL(link: attributes.url)
            } else {
                debugPrint("No matches")
            }
        }
        
        return true
    }
}

//
//  Artist.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/6/23.
//

import Foundation
import UIKit

/**
 Class containing important details and parameters for identifying artists.
 */
class Artist {
    private let name: String!
    private var translatedURL: URL?
    private var translatedImgURL: URL?
    private var translatedImgData: Data?
    
    init(name: String) {
        self.name = name
    }
    
    /**
     - Returns: Artist's name.
     */
    func getName() -> String {
        return name
    }
    
    /**
     - Parameter link: Link to the artist on the output platform.
     */
    func setTranslatedURL(link: String) {
        translatedURL = URL(string: link)
    }
    
    func getTranslatedURL() -> URL? {
        return translatedURL
    }
    
    /**
     - Returns: Translated URL as a `String` if it is valid, otherwise returns a message reflecting an error.
     */
    func getTranslatedURLasString() -> String {
        if let translatedURL = translatedURL {
            return translatedURL.absoluteString
        } else {
            return "There was no translation available"
        }
    }
    
    /**
     - Parameter link: Link to the album art on the output platform.
     */
    func setTranslatedImgURL(link: String) {
        translatedImgURL = URL(string: link)
    }
    
    /**
     - Returns: Translated artist's profile picture URL as a `String` if it is valid, otherwise returns a link to an image of a question mark.
     */
    func getTranslatedImgURL() -> URL? {
        if let translatedImgURL = translatedImgURL {
            return translatedImgURL
        }
        return nil
    }
    
    /**
     Asyncronously gets image data from the `translatedImgURL` and saves it to `translatedImgData` in the `Song` object.
     */
    func setTranslatedImgData() async {
        if let url = self.getTranslatedImgURL() {
            translatedImgData = await getImageData(imageURL: url)
        } else {
            let image = UIImage(named: "NoMusic")
            translatedImgData = image?.pngData()
        }
    }
    
    /**
     - Returns: Image data previously gathered from the internet. `nil` if there is none.
     */
    func getTranslatedImgData() -> Data? {
        return translatedImgData
    }
}

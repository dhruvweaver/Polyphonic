//
//  Playlist.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/13/22.
//

import Foundation

class Playlist {
    private let title: String
    private let songs: [Song]
    private let creator: String
    private var imageURL: URL?
    
    init(title: String, songs: [Song], creator: String) {
        self.title = title
        self.songs = songs
        self.creator = creator
    }
    
    func getTitle() -> String {
        return title
    }
    
    func getSongs() -> [Song] {
        return songs
    }
    
    func getCreator() -> String {
        return creator
    }
    
    /**
     - Parameter link: Link to the playlist image.
     */
    func setImageURL(link: String) {
        imageURL = URL(string: link)
    }
    
    /**
     - Returns: Playlist's image URL as a `String` if it is valid, otherwise returns a link to an image of a question mark.
     */
    func getImageURL() -> URL {
        if let imageURL = imageURL {
            return imageURL
        }
        return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Question_mark_%28black%29.svg/800px-Question_mark_%28black%29.svg.png")!
    }
}

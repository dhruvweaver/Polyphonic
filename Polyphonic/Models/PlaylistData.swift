//
//  PlaylistData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/13/22.
//

import Foundation

class PlaylistData {
    var currentProgress: Int = 0
    
    // identifies link's source platform
    /**
     Sets `starterSource` variable to the platform of origin of the provided starting link.
     */
    private func findPlatform(url: URL) -> Platform {
        var platform: Platform = .unknown
        
        let linkString = url.absoluteString
        if (linkString.contains("apple")) {
            platform = Platform.appleMusic
        } else if (linkString.contains("spotify")) {
            platform = Platform.spotify
        }
        
        return platform
    }
    
    /**
     Gets the appropriate playlist ID given a link and a platform.
     - Parameter platform: `Platform` enum type.
     - Parameter url: URL to playlist.
     - Returns: Song ID as a `String`.
     */
    private func getPlaylistID(platform: Platform, url: URL) -> String {
        var id: String = ""
        
        if (platform == Platform.spotify) {
            // gets Spotify songID from provided link. This is located at the end of a Spotify link
            id = url.lastPathComponent
        } else if (platform == Platform.appleMusic) {
            let linkStr = url.absoluteString
            if let index = linkStr.lastIndex(of: "=") {
                // gets id from end of link string
                id = String(linkStr[linkStr.index(index, offsetBy: 1)...linkStr.index(linkStr.endIndex, offsetBy: -1)])
            }
        }
        return id
    }
    
    func processPlaylistItems(playlistLink: String) async -> Playlist {
        // replace with playlist title if all goes well
        var title = "Something went wrong"
        let songs: [Song] = []
        let creator = "Unknown"
        var playlist = Playlist(title: title, songs: songs, creator: creator)
        
        if let url = URL(string: playlistLink) {
            let platform = findPlatform(url: url)
            let id = getPlaylistID(platform: platform, url: url)
            
            if (platform == .spotify) {
                let spotify = SpotifyPlaylistData(playlistID: id)
                playlist = await spotify.getPlaylistData()
            } else if (platform == .spotify) {
                title = "No Apple Music support yet"
            }
        } else {
            title = "Invalid URL"
        }
        
        return playlist
    }
}

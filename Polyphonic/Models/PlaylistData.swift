//
//  PlaylistData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/13/22.
//

import Foundation

class PlaylistData {
    var currentProgress: Int = 0
    
    private var playlist: Playlist? = nil
    private var success = false
    
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
    
    func processPlaylistItems(playlistLink: String) async -> (Playlist, Bool) {
        // replace with playlist title if all goes well
        var title = "Something went wrong"
        let songs: [Song] = []
        let creator = "Unknown"
        success = false
        playlist = Playlist(title: title, songs: songs, creator: creator)
        
        if let url = URL(string: playlistLink) {
            let platform = findPlatform(url: url)
            let id = getPlaylistID(platform: platform, url: url)
            
            if (platform == .spotify) {
                let spotify = SpotifyPlaylistData(playlistID: id)
                let results = await spotify.getPlaylistData()
                playlist = results.0
                success = results.1
            } else if (platform == .appleMusic) {
                title = "No Apple Music support yet"
            }
        } else {
            title = "Invalid URL"
        }
        
        // force unwrapping because it was assigned in the previous line
        return (playlist!, success)
    }
    
    private func generateSongJSON() -> String {
        var text = ""
        
        if (success && playlist!.getSongs().count > 0) {
            for i in playlist!.getSongs().dropLast() {
                let song = i
                text += """
    {
        \"title\": \"\(song.getTitle())\",
        \"ISRC\": \"\(song.getISRC())\",
        \"artist\": \"\(song.getArtists()[0])\",
        \"album\": \"\(song.getAlbum())\",
        \"albumID\": \"\(song.getAlbumID())\",
        \"explicit\": \(song.getExplicit()),
        \"trackNum\": \(song.getTrackNum())
    },

"""
            }
            let song = playlist!.getSongs().last!
            text += """
    {
        \"title\": \"\(song.getTitle())\",
        \"ISRC\": \"\(song.getISRC())\",
        \"artist\": \"\(song.getArtists()[0])\",
        \"album\": \"\(song.getAlbum())\",
        \"albumID\": \"\(song.getAlbumID())\",
        \"explicit\": \(song.getExplicit()),
        \"trackNum\": \(song.getTrackNum())
    }

"""
        }
        
        return text
    }
    
    private func generatePlaylistJSON() -> String {
        var text = ""
        
        if (success) {
            text = """
{
\"title\": \"\(playlist!.getTitle())\",
\"creator\": \"\(playlist!.getCreator())\",
\"imageURL\": \"\(playlist!.getImageURL())\",
\"songs\": [
\(generateSongJSON())
],
\"error\": false
}
"""
        } else {
            text = "{\"error\": true}"
        }
        
        return text
    }
    
    func writePlaylistJSON() {
        let str = generatePlaylistJSON().toBase64()
        let fileName = playlist!.getTitle().replacingOccurrences(of: " ", with: "-")
        let path = getDocumentsDirectory().appendingPathComponent("\(fileName).polyphonic")
        
        do {
            try str.write(to: path, atomically: true, encoding: .utf8)
            let input = try String(contentsOf: path)
            print(input)
        } catch {
            print(error.localizedDescription)
        }
    }
}

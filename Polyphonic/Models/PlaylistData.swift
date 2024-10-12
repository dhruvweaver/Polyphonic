//
//  PlaylistData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/18/23.
//

import Foundation

class Playlist {
    let id: String
    let name: String
    let creator: String
    let platform: Platform
    let originalURL: URL?
    var converted: Bool
    var songs: [Song]
    
    var imageURL: URL?
    
    init(id: String, name: String, creator: String, platform: Platform, originalURL: URL?, converted: Bool, songs: [Song]) {
        self.id = id
        self.name = name
        self.creator = creator
        self.platform = platform
        self.originalURL = originalURL
        self.converted = converted
        self.songs = songs
    }
    
    func setImageURL(link: String) {
        imageURL = URL(string: link)
    }
    
    /**
     - Returns: Translated song's album art URL as a `String` if it is valid, otherwise returns a link to an image of a question mark.
     */
    func getImageURL() -> URL? {
        if let imageURL = imageURL {
            return imageURL
        }
        return nil
    }
}

class ProgressCounter {
    var value = 0
    
    func increment() {
        value += 1
    }
    
    func reset() {
        value = 0
    }
}

// identifies link's source platform
/**
 Returns the platform of origin of the provided starting link.
 */
private func findPlatform(link: URL) -> Platform {
    let linkString = link.absoluteString
    if (linkString.contains("apple")) {
        return .appleMusic
    } else if (linkString.contains("spotify")) {
        return .spotify
    }
    
    return .unknown
}

/**
 Gets the appropriate song ID given a link and a starter platform.
 - Parameter platform: `Platform` enum type.
 - Parameter link: `URL` for the input playlist.
 - Returns: Song ID as a `String`.
 */
private func getPlaylistID(platform: Platform, link: URL) -> String {
    var id: String = ""
    
    if (platform == Platform.spotify) {
        // gets Spotify songID from provided link. This is located at the end of a Spotify link
        id = link.lastPathComponent
    } else if (platform == Platform.appleMusic) {
        id = link.lastPathComponent
    }
    
    return id
}

func getPlaylistData(fromURL url: String) async -> (String, Playlist?) {
    var result: (Playlist, Bool)? = nil
    
    var link: URL
    
    if let playlistLink = URL(string: url) {
        if (playlistLink.host != "open.spotify.com" && playlistLink.host != "music.apple.com") {
            return ("Link not supported", nil)
        } else {
            link = playlistLink
        }
    } else {
        return ("Bad link", nil)
    }
    
    let platform = findPlatform(link: link)
    let id = getPlaylistID(platform: platform, link: link)
    
    if (platform == .spotify) {
        let spotifyPlaylist = SpotifyPlaylistData(playlistID: id)
        result = await spotifyPlaylist.getPlaylistData(originalLink: link)
    }
    // TODO: apple music playlists
    
    if let result = result {
        if result.1 == true {
            return ("Success", result.0)
        } else {
            return ("No playlist found", nil)
        }
    } else {
        return ("No valid input", nil)
    }
}

func getPlaylistData(fromCode code: String) async -> (String, Playlist?) {
    if containsOnlyLettersAndNumbers(code) {
        if let playlist = await getPolyphonicPlaylistData(id: code) {
            return ("Success", playlist)
        } else {
            return ("No playlist found", nil)
        }
    } else {
        return ("Not valid input", nil)
    }
}

func convertToPolyphonicPlaylistData(playlist: Playlist) -> PolyphonicPlaylist? {
    var contents: [PolyphonicPlaylistContent] = []
    
    for (i, song) in playlist.songs.enumerated() {
        var originalStr: String = "none"
        if let originalURL = song.getOriginalURL() {
            originalStr = originalURL.absoluteString
        }
        
        let contentItem = PolyphonicPlaylistContent(id: "s\(playlist.id)", key_id: "\(playlist.id)\(i + 1)", title: song.getTitle(), playlist_track_num: i + 1, isrc: song.getISRC(), artist: song.getArtists()[0], album: song.getAlbum(), album_id: song.getAlbumID(), explicit: song.getExplicit(), original_url: originalStr, converted_url: song.getTranslatedURL()?.absoluteString, confidence: song.getConfidence(), track_num: song.getTrackNum())
        
        contents.append(contentItem)
    }
    
    var newPlaylistData: PolyphonicPlaylist?
    
    var originalStr: String = "nil"
    if let originalURL = playlist.originalURL {
        originalStr = originalURL.absoluteString
    }
    
    var platformStr: String = "unknown"
    if playlist.platform == .spotify {
        platformStr = "spotify"
    } else if playlist.platform == .appleMusic {
        platformStr = "apple music"
    }
    
    newPlaylistData = PolyphonicPlaylist(id: "s\(playlist.id)", name: playlist.name, creator: playlist.creator, song_count: playlist.songs.count, platform: platformStr, original_url: originalStr, converted: playlist.converted, content: contents)
    
    return newPlaylistData
}

func translatePlaylistContent(playlist: Playlist, counter: ProgressCounter) async {
    await withTaskGroup(of: Void.self) { group in
        for (i, currentSong) in playlist.songs.enumerated() {
            usleep(20000) // wait to reduce server load slightly
            
            group.addTask {
                var musicData: MusicData? = MusicData()
                
                let results = await musicData!.translateData(link: currentSong.getOriginalURL()!.absoluteString)
                musicData = nil
                
                if let song = results.1 {
                    song.alts = results.5
                    song.setConfidence(level: results.7.rawValue)
                    song.setOriginalURL(link: currentSong.getOriginalURL()!.absoluteString)
                    
                    
                    playlist.songs[i] = song
                    playlist.converted = true
                }
             
                counter.increment()
            }
        }
    }
}

//
//  Playlist.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/18/23.
//

import Foundation

struct PolyphonicPlaylist: Decodable {
    let id: String
    let name: String
    let creator: String
    let song_count: Int
    let platform: String
    let original_url: String
    let converted: Bool
    let content: [PolyphonicPlaylistContent]
}

struct PolyphonicPlaylistContent: Decodable {
    let id: String
    let key_id: String
    let title: String
    let playlist_track_num: Int
    let isrc: String
    let artist: String
    let album: String
    let album_id: String
    let explicit: Bool
    let original_url: String
    let converted_url: String?
    let confidence: Int
    let track_num: Int
}

func postPolyphonicPlaylistData(playlistData: PolyphonicPlaylist) async -> Bool {
    var contentJson: [[String:Any]] = []
    
    for i in playlistData.content {
        contentJson.append([
            "id" : i.id,
            "key_id": i.key_id,
            "title" : i.title,
            "playlist_track_num" : i.playlist_track_num,
            "isrc" : i.isrc,
            "artist" : i.artist,
            "album" : i.album,
            "album_id" : i.album_id,
            "explicit" : i.explicit,
            "original_url" : i.original_url,
            "converted_url" : i.converted_url as Any,
            "confidence" : i.confidence,
            "track_num" : i.track_num
        ])
    }
    
    let json: [String:Any] = [
        "id" : playlistData.id,
        "name" : playlistData.name,
        "creator" : playlistData.creator,
        "song_count" : playlistData.song_count,
        "platform" : playlistData.platform,
        "original_url" : playlistData.original_url,
        "converted" : playlistData.converted,
        "content" : contentJson
    ]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json)
    debugPrint(json)
    
    let url = URL(string: "\(serverAddress)/playlist/")!
    debugPrint("Querying: \(url.absoluteString)")
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = jsonData
    
    do {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        if let httpResponse = response as? HTTPURLResponse {
            debugPrint(httpResponse.statusCode)
        }
        print(String(decoding: data, as: UTF8.self))
        
        return true
    } catch {
        debugPrint("Error loading \(url): \(String(describing: error))")
        
        return false
    }
}

private func convertDataToSongList(playlistData: PolyphonicPlaylist) -> [Song] {
    var songs: [Song] = []
    
    for content in playlistData.content {
        let song = Song(title: content.title, ISRC: content.isrc, artists: [content.artist], album: content.album, albumID: content.album_id, explicit: content.explicit, trackNum: content.track_num)
        song.setConfidence(level: content.confidence)
        
        songs.append(song)
    }
    
    return songs
}

func getPolyphonicPlaylistData(id: String) async -> Playlist? {
    var playlist: Playlist? = nil
    
    var playlistData: PolyphonicPlaylist
    
    let url = URL(string: "\(serverAddress)/playlist/\(id)")!
    debugPrint("Querying: \(url.absoluteString)")
    let urlSession = URLSession(configuration: sessionConfig)
    do {
        let (data, response) = try await urlSession.data(from: url)
        urlSession.finishTasksAndInvalidate()
        if let httpResponse = response as? HTTPURLResponse {
            print(httpResponse.statusCode)
        }
        playlistData = try JSONDecoder().decode(PolyphonicPlaylist.self, from: data)
        
        // convert decoded JSON to Playlist object
        var platform: Platform
        if (playlistData.platform == "spotify") {
            platform = .spotify
        } else if (playlistData.platform == "appleMusic") {
            platform = .appleMusic
        } else {
            platform = .unknown
        }
        
        let songs = convertDataToSongList(playlistData: playlistData)
        
        if let originalURL = URL(string: playlistData.original_url) {
            playlist = Playlist(id: playlistData.id, name: playlistData.name, creator: playlistData.creator, platform: platform, originalURL: originalURL, converted: playlistData.converted, songs: songs)
        }
    } catch {
        debugPrint("Error loading \(url): \(String(describing: error))")
    }
    
    return playlist
}

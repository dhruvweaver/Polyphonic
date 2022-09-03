//
//  PlaylistData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/13/22.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import MusicKit

class PlaylistData {
    private let db = Firestore.firestore()
    
    var currentProgress: Int = 0
    
    private var playlist: Playlist? = nil
    private var success = false
    private var playlistID: String? = nil
    private var platform: Platform = .unknown
    
    // identifies link's source platform
    /**
     Sets `starterSource` variable to the platform of origin of the provided starting link.
     */
    private func findPlatform(url: URL) {
        let linkString = url.absoluteString
        if (linkString.contains("apple")) {
            platform = Platform.appleMusic
        } else if (linkString.contains("spotify")) {
            platform = Platform.spotify
        }
    }
    
    /**
     Gets the appropriate playlist ID given a link and a platform.
     - Parameter platform: `Platform` enum type.
     - Parameter url: URL to playlist.
     - Returns: Song ID as a `String`.
     */
    private func getPlaylistID(platform: Platform, url: URL) {
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
        
        playlistID = id
    }
    
    func processPlaylistLink(playlistLink: String) async -> (Playlist, Bool) {
        // replace with playlist title if all goes well
        var title = "Something went wrong"
        let songs: [Song] = []
        let creator = "Unknown"
        success = false
        playlist = Playlist(title: title, songs: songs, creator: creator)
        
        if let url = URL(string: playlistLink) {
            findPlatform(url: url)
            getPlaylistID(platform: platform, url: url)
            
            if (platform == .spotify) {
                let spotify = SpotifyPlaylistData(playlistID: playlistID!)
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
    
    struct PlaylistData: Codable {
        let title: String
        let creator: String
        let imageURL: String
        let songs: [SongData]
    }
    
    struct SongData: Codable {
        let title: String
        let isrc: String
        let artist: String
        let album: String
        let albumID: String
        let explicit: Bool
        let trackNum: Int
    }
    
    // Get playlist from DB
    func processPlaylistByID(playlistID: String) async -> (Playlist, Bool) {
        // replace with playlist title if all goes well
        var title = "This ID is not available"
        var songs: [Song] = []
        var creator = "Unknown"
        success = false
        playlist = Playlist(title: title, songs: songs, creator: creator)
        
        let docRef = db.collection("playlists").document(playlistID)
        
        do {
            let document = try await docRef.getDocument()
            if document.exists {
                do {
                    let playlistData: PlaylistData = try document.data(as: PlaylistData.self)
                    title = playlistData.title
                    creator = playlistData.creator
                    
                    for i in playlistData.songs {
                        let song = Song(title: i.title, ISRC: i.isrc, artists: [i.artist], album: i.album, albumID: i.albumID, explicit: i.explicit, trackNum: i.trackNum)
                        songs.append(song)
                    }
                    
                    playlist = Playlist(title: title, songs: songs, creator: creator)
                    playlist?.setImageURL(link: playlistData.imageURL)
                    success = true
                    
                    //                    do {
                    //                        try await db.collection("playlists").document(generatePlaylistDBID()).delete()
                    //                        debugPrint("Successfully deleted playlist \(playlistID)")
                    //                    } catch {
                    //                        debugPrint("Could not delete playlist")
                    //                    }
                } catch {
                    debugPrint("Could not parse data")
                }
            } else {
                print("Document does not exist")
            }
        } catch {
            debugPrint("Error getting playlist data")
        }
        
        return (playlist!, success)
    }
    
    // creates JSON-ized list of song data for db
    private func generateSongList() -> [[String : Any]] {
        var songList: [[String : Any]] = []
        if (success && playlist!.getSongs().count > 0) {
            for i in playlist!.getSongs() {
                let song = i
                var songData: [String : Any]
                
                songData = [
                    "title" : song.getTitle(),
                    "isrc" : song.getISRC(),
                    "artist" : song.getArtists()[0],
                    "album" : song.getAlbum(),
                    "albumID" : song.getAlbumID(),
                    "explicit" : song.getExplicit(),
                    "trackNum" : song.getTrackNum()
                ]
                songList.append(songData)
            }
        }
        
        return songList
    }
    
    // Creates a unique playlist ID for db storage and access
    private func generatePlaylistDBID() -> String {
        var dbID: String = ""
        if (platform == .spotify) {
            dbID = "S\(playlistID!)"
        }
        
        return dbID
    }
    
    // Writes playlist data to Firebase db
    func writePlaylistJSON() -> String {
        let songs = generateSongList()
        let id = generatePlaylistDBID()
        // Add a new document in collection "cities"
        db.collection("playlists").document(id).setData([
            "title": playlist!.getTitle(),
            "creator": playlist!.getCreator(),
            "imageURL": playlist!.getImageURL().absoluteString,
            "songs" : songs
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
        
        return id
    }
    
    // Imports playlist data into destination platform
    func importPlaylist(playlistPlatform: Platform, playlistSongs: [Song], title: String) async {
        if (playlistPlatform == .appleMusic) {
            let json: [String:Any] = ["attributes" : ["name":title]]
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            debugPrint(json)
            
            let url = URL(string: "https://api.music.apple.com/v1/me/library/playlists")!
            debugPrint("Querying: \(url.absoluteString)")
            let sessionConfig = URLSessionConfiguration.default
            let authValue: String = "Bearer \(appleMusicAuthKey)"
            
            var userToken: String
            
            let userTokenProvider = MusicUserTokenProvider.init()
            do {
                userToken = try await userTokenProvider.userToken(for: appleMusicAuthKey, options: MusicTokenRequestOptions.init())
                debugPrint("Got user token")
                sessionConfig.httpAdditionalHeaders = ["Authorization": authValue, "Music-User-Token": userToken]
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                debugPrint(userToken)
                //            request.httpBody = jsonData
                let urlSession = URLSession(configuration: sessionConfig)
                
                do {
                    let (data, response) = try await urlSession.upload(for: request, from: jsonData!)
                    if let httpResponse = response as? HTTPURLResponse {
                        print(httpResponse.statusCode)
                        
                        if (httpResponse.statusCode == 201) {
                            debugPrint("Created new playlist!")
                        } else {
                            debugPrint("Could not create the playlist")
                        }
                    }
                } catch {
                    debugPrint("Error loading \(url): \(String(describing: error))")
                }
            } catch {
                debugPrint("Could not get user token")
            }
        }
    }
}

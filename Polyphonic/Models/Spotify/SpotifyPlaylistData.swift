//
//  SpotifyPlaylistData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 7/13/22.
//

import Foundation

class SpotifyPlaylistData {
    private var id: String
    
    init(playlistID: String) {
        self.id = playlistID
    }
    
    private var spotifyPlaylistJSON: SpotifyPlaylistDataRoot? = nil
    private var spotifyPlaylistNextJSON: Tracks? = nil
    
    /* Start of JSON decoding structs */
    private struct SpotifyPlaylistDataRoot: Decodable {
        let name: String
        let images: [PlaylistImage]
        let owner: PlaylistOwner
        let tracks: Tracks
        //        let total: Int
    }
    
    private struct PlaylistImage: Decodable {
        let url: String
    }
    
    private struct PlaylistOwner: Decodable {
        let display_name: String
    }
    
    private struct Tracks: Decodable {
        let items: [PlaylistItem]
        let next: String?
    }
    
    private struct PlaylistItem: Decodable {
        let track: SpotifySongDataRoot
    }
    
    private struct SpotifySongDataRoot: Decodable {
        let album: Album
        let artists: [Artist]
        let explicit: Bool
        let external_ids: ExternalIDs
        let name: String
        let track_number: Int
        let uri: String
    }
    
    private struct Album: Decodable {
        let id: String
        let name: String
        let images: [ArtImage]
    }
    
    private struct ArtImage: Decodable {
        let url: String
    }
    
    private struct Artist: Decodable {
        let name: String
    }
    
    private struct ExternalIDs: Decodable {
        let isrc: String
    }
    /* End of JSON decoding structs */
    
    /**
     Assings local variable `spotifyPlaylistJSON` to decoded JSON after querying API for playlist data using a playlist ID.
     */
    func getSpotifyPlaylistDataByID() async {
        let url = URL(string: "https://api.spotify.com/v1/playlists/\(id)")!
        let sessionConfig = URLSessionConfiguration.default
        // get authorization key from Spotify
        if let authKey = await getSpotifyAuthKey() {
            let authValue: String = "Bearer \(authKey)"
            sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
            debugPrint("Querying: \(url.absoluteString)")
            let urlSession = URLSession(configuration: sessionConfig)
            do {
                let (data, response) = try await urlSession.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse.statusCode)
                }
                self.spotifyPlaylistJSON = try JSONDecoder().decode(SpotifyPlaylistDataRoot.self, from: data)
            } catch {
                debugPrint("Error loading \(url): \(String(describing: error))")
            }
        }
    }
    
    func getNextSpotifyPlaylistData(next: String) async {
        let url = URL(string: next)!
        let sessionConfig = URLSessionConfiguration.default
        // get authorization key from Spotify
        if let authKey = await getSpotifyAuthKey() {
            let authValue: String = "Bearer \(authKey)"
            sessionConfig.httpAdditionalHeaders = ["Authorization": authValue]
            debugPrint("Querying: \(url.absoluteString)")
            let urlSession = URLSession(configuration: sessionConfig)
            do {
                let (data, response) = try await urlSession.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse.statusCode)
                }
                self.spotifyPlaylistNextJSON = try JSONDecoder().decode(Tracks.self, from: data)
            } catch {
                debugPrint("Error loading \(url): \(String(describing: error))")
            }
        }
    }
    
    func getPlaylistData() async -> (Playlist, Bool) {
        var playlist = Playlist(title: "Could not parse playlist data", songs: [], creator: "Unknown")
        var success = false
        
        await getSpotifyPlaylistDataByID()
        
        if let processed = spotifyPlaylistJSON {
            let title = processed.name
            var songs: [Song] = []
            
            for i in processed.tracks.items{
                let attributes = i.track
                var artists: [String] = []
                for j in attributes.artists {
                    artists.append(j.name)
                }
                let songItem = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit, trackNum: attributes.track_number)
                songItem.setTranslatedURL(link: generateLink(uri: attributes.uri))
                songItem.setTranslatedImgURL(link: attributes.album.images[1].url)
                songs.append(songItem)
                
                success = true
            }
            
            // check to see if there are more tracks to get. Spotify will only return 100 at a time
            var nextURL = ""
            if let next = processed.tracks.next {
                nextURL = next
                debugPrint("Need to get more tracks...")
                var getMore = true
                while (getMore) {
                    await getNextSpotifyPlaylistData(next: nextURL)
                
                    if let nextProcessed = spotifyPlaylistNextJSON {
                        for i in nextProcessed.items {
                            let attributes = i.track
                            var artists: [String] = []
                            for j in attributes.artists {
                                artists.append(j.name)
                            }
                            let songItem = Song(title: attributes.name, ISRC: attributes.external_ids.isrc, artists: artists, album: attributes.album.name, albumID: attributes.album.id, explicit: attributes.explicit, trackNum: attributes.track_number)
                            songItem.setTranslatedURL(link: generateLink(uri: attributes.uri))
                            songItem.setTranslatedImgURL(link: attributes.album.images[1].url)
                            songs.append(songItem)
                        }
                        
                        if let next = nextProcessed.next {
                            nextURL = next
                        } else {
                            getMore = false
                        }
                    }
                }
            }
            
            playlist = Playlist(title: title, songs: songs, creator: processed.owner.display_name)
            playlist.setImageURL(link: processed.images[0].url)
            //            return playlist
        }
        
        debugPrint("Success? \(success)")
        return (playlist, success)
    }
    
    /**
     Generates link to a song given its Spotify URI.
     - Parameter uri: URI as provided by Spotify.
     - Returns: URL in `String` form.
     */
    private func generateLink(uri: String) -> String {
        return "https://open.spotify.com/track/\(uri.suffix(from: uri.index(after: uri.lastIndex(of: ":")!)))"
    }
}

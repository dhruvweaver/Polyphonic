//
//  SongData.swift
//  MusicLinkApp
//
//  Created by Dhruv Weaver on 6/11/22.
//

import Foundation

class SongData {
    private var starterLink: URL? = nil
    
    init() {
        
    }
    
    enum Platform {
        case unknown, spotify, appleMusic
    }
    private var starterSource: Platform = Platform.unknown
    
    var songData: Song? = nil
    
    private var spotifyAccessJSON: SpotifyAccessData? = nil
    struct SpotifyAccessData: Decodable {
        let access_token: String
    }
    
    private func findPlatform() {
        let linkString = starterLink!.absoluteString
        if (linkString.contains("apple")) {
            starterSource = Platform.appleMusic
        } else if (linkString.contains("spotify")) {
            starterSource = Platform.spotify
        }
    }
    
    private func getSpotifyAuthKey() async -> String? {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        let urlSession = URLSession.shared
        let spotifyClientString = (spotifyClientID + ":" + spotifyClientSecret).toBase64()
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(spotifyClientString)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        let postString = "grant_type=client_credentials"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        do {
            let (data, _) = try await urlSession.data(for: request)
            spotifyAccessJSON = try JSONDecoder().decode(SpotifyAccessData.self, from: data)
        } catch {
            debugPrint("Error loading \(url): \(String(describing: error))")
        }
        
        var accessKey: String? = nil
        
        if let processed = spotifyAccessJSON {
            accessKey = processed.access_token
        }
        
        return accessKey
    }
    
    // currently only outputs song name
    private func findTranslatedLink() async -> String? {
        var output: String? = nil
        // first identify which platform the link starts with
        findPlatform()
        
        if (starterSource == Platform.spotify) {
            print("Link is from Spotify")
            // Spotify API call can be made with the Spotify ID. This is located at the end of a Spotify link
            let spotifyID = starterLink!.lastPathComponent
            // get authorization key from Spotify
            if let authKey = await getSpotifyAuthKey() {
                let spotify = SpotifySongData(songID: spotifyID, authKey: authKey)
                await spotify.getSpotifySongData()
                spotify.parseToObject()
                
                if let spotifySong = spotify.song {
                    songData = Song(title: spotifySong.getTitle(), ISRC: spotifySong.getISRC(), artists: spotifySong.getArtists(), album: spotifySong.getAlbum())
                    if let songData = songData {
                        let appleMusic = AppleMusicSongData(songID: nil, songISRC: songData.getISRC())
                        await appleMusic.getAppleMusicSongDataBySearch(songRef: spotifySong)
                        appleMusic.parseToObject(songRef: spotifySong)
                        if let translatedSongData = appleMusic.song {
                            debugPrint("Spotify Artist: \(spotifySong.getArtists()[0])")
                            debugPrint("Apple   Artist: \(translatedSongData.getArtists()[0])")
                            
                            if (spotifySong.getAlbum() == translatedSongData.getAlbum()) || (spotifySong.getTitle() == translatedSongData.getTitle()) || (spotifySong.getArtists()[0] == translatedSongData.getArtists()[0]) {
                                output = translatedSongData.getTranslatedURLasString()
                            }
                        }
                    }
                }
            }
        }
        
        return output
    }
    
    func translateData(link: String) async -> String {
        if let songLink = URL(string: link) {
            starterLink = songLink
        } else {
            return "Bad link"
        }
        
        var link: String?
        link = await findTranslatedLink()
        
        if link != nil {
            return link!
        } else {
            return "No equivalent song or there was an error"
        }
    }
}


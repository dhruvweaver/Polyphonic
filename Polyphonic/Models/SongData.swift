//
//  SongData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/11/22.
//

import Foundation

class SongData {
    private var starterLink: URL? = nil
    
    init() {
        
    }
    
    // enum to help determing which platform the link comes from (and later, which it should translate to)
    enum Platform {
        case unknown, spotify, appleMusic
    }
    private var starterSource: Platform = Platform.unknown
    
    var songData: Song? = nil
    
    // identifies link's source platform
    private func findPlatform() {
        let linkString = starterLink!.absoluteString
        if (linkString.contains("apple")) {
            starterSource = Platform.appleMusic
        } else if (linkString.contains("spotify")) {
            starterSource = Platform.spotify
        }
    }
    
    private func getSongID(platform: Platform) -> String {
        var id: String = ""
        
        if (platform == Platform.spotify) {
            // gets Spotify songID from provided link. This is located at the end of a Spotify link
            id = starterLink!.lastPathComponent
        } else if (platform == Platform.appleMusic) {
            let linkStr = starterLink!.absoluteString
            if let index = linkStr.lastIndex(of: "=") {
                // gets id from end of link string
                id = String(linkStr[linkStr.index(index, offsetBy: 1)...linkStr.index(linkStr.endIndex, offsetBy: -1)])
            }
        }
        return id
    }
    
    private func translateSpotifyToAppleMusic() async -> String? {
        var translatedLink: String? = nil
        print("Link is from Spotify")
        // Spotify API call can be made with the Spotify ID, get song ID
        let spotifyID = getSongID(platform: Platform.spotify)
        // create SpotifySongData object
        let spotify = SpotifySongData(songID: spotifyID)
        // create song object from HTTP request
        await spotify.getSpotifySongDataByID()
        spotify.parseToObject(songRef: nil)
        // if all goes well, continue to translation
        if let spotifySong = spotify.song {
            songData = Song(title: spotifySong.getTitle(), ISRC: spotifySong.getISRC(), artists: spotifySong.getArtists(), album: spotifySong.getAlbum())
            // create AppleMusicSongData object
            let appleMusic = AppleMusicSongData(songID: nil)
            // this function will talk to the Apple Music API, it requires already known song data
            await appleMusic.getAppleMusicSongDataBySearch(songRef: spotifySong)
            appleMusic.parseToObject(songRef: spotifySong)
            if let translatedSongData = appleMusic.song {
                debugPrint("Spotify Artist: \(spotifySong.getArtists()[0])")
                debugPrint("Apple   Artist: \(translatedSongData.getArtists()[0])")
                // ensure that the translated song matches the original before returning a link -- NOT DOING THAT ANYMORE. MAY NEED TO BRING IT BACK
                translatedLink = translatedSongData.getTranslatedURLasString()
            }
        }
        
        
        return translatedLink
    }
    
    private func translateAppleMusicToSpotify() async -> String? {
        var translatedLink: String? = nil
        print("Link is from Apple Music")
        // Apple Music API call will be made with the Apple Music ID, get song ID
        let appleMusicID = getSongID(platform: Platform.appleMusic)
        // create AppleMusicSongData object
        let appleMusic = AppleMusicSongData(songID: appleMusicID)
        await appleMusic.getAppleMusicSongDataByID()
        appleMusic.parseToObject(songRef: nil)
        // if all goes well, continue to translation
        if let appleMusicSong = appleMusic.song {
            // create SpotifySongData object
            let spotify = SpotifySongData(songID: nil)
            // this function will talk to the Spotify API, it requires already known song data
            await spotify.getSpotifySongDatayBySearch(songRef: appleMusicSong)
            spotify.parseToObject(songRef: appleMusicSong)
            if let translatedSongData = spotify.song {
                debugPrint("Spotify Artist: \(translatedSongData.getArtists()[0])")
                debugPrint("Apple   Artist: \(appleMusicSong.getArtists()[0])")
                // ensure that the translated song matches the original before returning a link -- NOT DOING THAT ANYMORE. MAY NEED TO BRING IT BACK
                translatedLink = translatedSongData.getTranslatedURLasString()
            }
        }
        
        return translatedLink
    }
    
    private func findTranslatedLink() async -> String? {
        var output: String? = nil
        // first identify which platform the link starts with
        findPlatform()
        
        if (starterSource == Platform.spotify) {
            // get Apple Music link from Spotify link
            output = await translateSpotifyToAppleMusic()
        } else if (starterSource == Platform.appleMusic) {
            // get Spotify link from Apple Music link
            output = await translateAppleMusicToSpotify()
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

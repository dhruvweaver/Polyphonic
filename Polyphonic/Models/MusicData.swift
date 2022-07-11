//
//  SongData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/11/22.
//

import Foundation


enum MusicType {
    case song, album
}

class MusicData {
    private var starterLink: URL? = nil
    
    init() {
        
    }
    
    // enum to help determing which platform the link comes from (and later, which it should translate to)
    enum Platform {
        case unknown, spotify, appleMusic
    }
    private var starterSource: Platform = Platform.unknown
    
    var song: Song? = nil
    var albumData: Album? = nil
    
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
    
    private func getAlbumID(platform: Platform) -> String {
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
    
    private func translateSpotifyToAppleMusic() async -> (String?, Song?, [String], [Song]) {
        var translatedLink: String? = nil
        var translatedSong: Song? = nil
        var altSongURLs: [String] = []
        var altSongs: [Song] = []
        print("Link is from Spotify")
        // Spotify API call can be made with the Spotify ID, get song ID
        let spotifyID = getSongID(platform: Platform.spotify)
        // create SpotifySongData object
        let spotify = SpotifySongData(songID: spotifyID)
        // create song object from HTTP request
        await spotify.getSpotifySongDataByID()
        _ = spotify.parseToObject(songRef: nil)
        // if all goes well, continue to translation
        if let spotifySong = spotify.song {
            song = Song(title: spotifySong.getTitle(), ISRC: spotifySong.getISRC(), artists: spotifySong.getArtists(), album: spotifySong.getAlbum(), albumID: spotifySong.getAlbumID(), explicit: spotifySong.getExplicit(), trackNum: spotifySong.getTrackNum())
            // create AppleMusicSongData object
            let appleMusic = AppleMusicSongData(songID: nil)
            // this function will talk to the Apple Music API, it requires already known song data
            await appleMusic.getAppleMusicSongDataBySearch(songRef: spotifySong, narrowSearch: true)
            // parse func returns bool depending on whether the search was too limited. True means it was fine, otherwise broaden the search
            if (appleMusic.parseToObject(songRef: spotifySong)) {
                if let translatedSongData = appleMusic.song {
                    debugPrint("Spotify Artist: \(spotifySong.getArtists()[0])")
                    debugPrint("Apple   Artist: \(translatedSongData.getArtists()[0])")
                    // ensure that the translated song matches the original before returning a link -- NOT DOING THAT ANYMORE. MAY NEED TO BRING IT BACK
                    translatedLink = translatedSongData.getTranslatedURLasString()
                    
                    translatedSong = translatedSongData
                    altSongs = appleMusic.getAllSongs()
                    
                    for i in altSongs {
                        let altURL = i.getTranslatedURLasString()
                        debugPrint("Alt: \(altURL)")
                        altSongURLs.append(altURL)
                    }
                }
            } else {
                debugPrint("Trying search again")
                await appleMusic.getAppleMusicSongDataBySearch(songRef: spotifySong, narrowSearch: false)
                _ = appleMusic.parseToObject(songRef: spotifySong)
                if let translatedSongData = appleMusic.song {
                    debugPrint("Spotify Artist: \(spotifySong.getArtists()[0])")
                    debugPrint("Apple   Artist: \(translatedSongData.getArtists()[0])")
                    // ensure that the translated song matches the original before returning a link -- NOT DOING THAT ANYMORE. MAY NEED TO BRING IT BACK
                    translatedLink = translatedSongData.getTranslatedURLasString()
                    
                    translatedSong = translatedSongData
                    altSongs = appleMusic.getAllSongs()
                    
                    for i in altSongs {
                        let altURL = i.getTranslatedURLasString()
                        debugPrint("Alt: \(altURL)")
                        altSongURLs.append(altURL)
                    }
                }
            }
        }
        
        return (translatedLink, translatedSong, altSongURLs, altSongs)
    }
    
    private func translateAppleMusicToSpotify() async -> (String?, Song?, [String], [Song]) {
        var translatedLink: String? = nil
        var translatedSong: Song? = nil
        var altSongURLs: [String] = []
        var altSongs: [Song] = []
        
        print("Link is from Apple Music")
        // Apple Music API call will be made with the Apple Music ID, get song ID
        let appleMusicID = getSongID(platform: Platform.appleMusic)
        // create AppleMusicSongData object
        let appleMusic = AppleMusicSongData(songID: appleMusicID)
        await appleMusic.getAppleMusicSongDataByID()
        _ = appleMusic.parseToObject(songRef: nil)
        // if all goes well, continue to translation
        if let appleMusicSong = appleMusic.song {
            // create SpotifySongData object
            let spotify = SpotifySongData(songID: nil)
            // this function will talk to the Spotify API, it requires already known song data
            await spotify.getSpotifySongDataBySearch(songRef: appleMusicSong, narrowSearch: true)
            // parse func returns bool depending on whether the search was too limited. True means it was fine, otherwise broaden the search
            if (spotify.parseToObject(songRef: appleMusicSong)) {
                if let translatedSongData = spotify.song {
                    debugPrint("Spotify Artist: \(translatedSongData.getArtists()[0])")
                    debugPrint("Apple   Artist: \(appleMusicSong.getArtists()[0])")
                    // ensure that the translated song matches the original before returning a link -- NOT DOING THAT ANYMORE. MAY NEED TO BRING IT BACK
                    translatedLink = translatedSongData.getTranslatedURLasString()
                    
                    translatedSong = translatedSongData
                    altSongs = spotify.getAllSongs()
                    
                    for i in altSongs {
                        let altURL = i.getTranslatedURLasString()
                        debugPrint("Alt: \(altURL)")
                        altSongURLs.append(altURL)
                    }
                }
            } else {
                debugPrint("Trying search again")
                await spotify.getSpotifySongDataBySearch(songRef: appleMusicSong, narrowSearch: false)
                _ = spotify.parseToObject(songRef: appleMusicSong)
                if let translatedSongData = spotify.song {
                    debugPrint("Spotify Artist: \(translatedSongData.getArtists()[0])")
                    debugPrint("Apple   Artist: \(appleMusicSong.getArtists()[0])")
                    // ensure that the translated song matches the original before returning a link -- NOT DOING THAT ANYMORE. MAY NEED TO BRING IT BACK
                    translatedLink = translatedSongData.getTranslatedURLasString()
                    
                    translatedSong = translatedSongData
                    altSongs = spotify.getAllSongs()
                    
                    for i in altSongs {
                        let altURL = i.getTranslatedURLasString()
                        debugPrint("Alt: \(altURL)")
                        altSongURLs.append(altURL)
                    }
                }
            }
        }
        
        return (translatedLink, translatedSong, altSongURLs, altSongs)
    }
    
    // translates album from Spotify to Apple Music
    private func translateAlbumSpotifyToAppleMusic() async -> (String?, Song?, [String], [Song]) {
        var translatedLink: String? = nil
        var translatedSong: Song? = nil
        var altSongURLs: [String] = []
        var altSongs: [Song] = []
        
        debugPrint("Album link is from Spotify")
        // Spotify API call can be made with the Spotify ID, get song ID
        let spotifyID = getAlbumID(platform: .spotify)
        debugPrint(spotifyID)
        // create SpotifySongData object
        let spotify = SpotifyAlbumData(albumID: spotifyID)
        // create song object from HTTP request
        await spotify.getSpotifyAlbumDataByID()
        _ = spotify.parseToObject(songRef: nil)
        // if all goes well, continue to translation
        if let spotifyAlbum = spotify.album {
            debugPrint(spotifyAlbum.getTitle())
            debugPrint(spotifyAlbum.getKeySongID())
            // setup key song link for accurate album fetching
            let spotifySongData = SpotifySongData(songID: spotifyAlbum.getKeySongID())
            await spotifySongData.getSpotifySongDataByID()
            _ = spotifySongData.parseToObject(songRef: nil)
            if let spotifySong = spotifySongData.song {
                debugPrint(spotifySong.getTitle())
                // create AppleMusicSongData object
                let appleMusic = AppleMusicSongData(songID: nil)
                // this function will talk to the Apple Music API, it requires already known song data
                await appleMusic.getAppleMusicSongDataBySearch(songRef: spotifySong, narrowSearch: true)
                // parse func returns bool depending on whether the search was too limited. True means it was fine, otherwise broaden the search
                if (appleMusic.parseToObject(songRef: spotifySong)) {
                    if let translatedSongData = appleMusic.song {
                        debugPrint("Spotify Album: \(spotifySong.getAlbum())")
                        debugPrint("Apple   Album: \(translatedSongData.getAlbum())")
                        // find album link through translated song
                        let appleAlbum = AppleMusicAlbumData(albumID: translatedSongData.getAlbumID())
                        await appleAlbum.getAppleAlbumDataByID()
                        translatedLink = appleAlbum.appleURL
                        
                        translatedSong = translatedSongData
                        // get alternate song objects from Apple Music object
                        altSongs = appleMusic.getAllSongs()
                        
                        // get alternate URLs from Apple Music object
                        for i in altSongs {
                            let album = AppleMusicAlbumData(albumID: i.getAlbumID())
                            await album.getAppleAlbumDataByID()
                            let altURL = album.appleURL
                            debugPrint("Alt: \(altURL)")
                            altSongURLs.append(altURL)
                        }
                    }
                } else {
                    debugPrint("Trying search again")
                    await appleMusic.getAppleMusicSongDataBySearch(songRef: spotifySong, narrowSearch: false)
                    _ = appleMusic.parseToObject(songRef: spotifySong)
                    if let translatedSongData = appleMusic.song {
                        debugPrint("Spotify Album: \(spotifySong.getAlbum())")
                        debugPrint("Apple   Album: \(translatedSongData.getAlbum())")
                        // find album link through translated song
                        let appleAlbum = AppleMusicAlbumData(albumID: translatedSongData.getAlbumID())
                        await appleAlbum.getAppleAlbumDataByID()
                        translatedLink = appleAlbum.appleURL
                        
                        translatedSong = translatedSongData
                        altSongs = appleMusic.getAllSongs()
                        
                        for i in altSongs {
                            let album = AppleMusicAlbumData(albumID: i.getAlbumID())
                            await album.getAppleAlbumDataByID()
                            let altURL = album.appleURL
                            debugPrint("Alt: \(altURL)")
                            altSongURLs.append(altURL)
                        }
                    }
                }
            }
        }
        
        return (translatedLink, translatedSong, altSongURLs, altSongs)
    }
    
    // translates album from Spotify to Apple Music
    private func translateAlbumAppleMusicToSpotify() async -> (String?, Song?, [String], [Song]) {
        var translatedLink: String? = nil
        var translatedSong: Song? = nil
        var altSongURLs: [String] = []
        var altSongs: [Song] = []
        
        debugPrint("Album link is from Apple Music")
        // Spotify API call can be made with the Spotify ID, get song ID
        let appleMusicID = getAlbumID(platform: .spotify)
        debugPrint(appleMusicID)
        // create SpotifySongData object
        let appleMusic = AppleMusicAlbumData(albumID: appleMusicID)
        // create song object from HTTP request
        await appleMusic.getAppleAlbumDataByID()
        _ = appleMusic.parseToObject(albumRef: nil)
        // if all goes well, continue to translation
        if let appleMusicAlbum = appleMusic.album {
            debugPrint(appleMusicAlbum.getTitle())
            debugPrint(appleMusicAlbum.getKeySongID())
            // setup key song link for accurate album fetching
            let appleMusicSongData = AppleMusicSongData(songID: appleMusicAlbum.getKeySongID())
            await appleMusicSongData.getAppleMusicSongDataByID()
            _ = appleMusicSongData.parseToObject(songRef: nil)
            if let appleMusicSong = appleMusicSongData.song {
                debugPrint(appleMusicSong.getTitle())
                // create AppleMusicSongData object
                let spotify = SpotifySongData(songID: nil)
                // this function will talk to the Apple Music API, it requires already known song data
                await spotify.getSpotifySongDataBySearch(songRef: appleMusicSong, narrowSearch: true)
                // parse func returns bool depending on whether the search was too limited. True means it was fine, otherwise broaden the search
                if (spotify.parseToObject(songRef: appleMusicSong)) {
                    if let translatedSongData = spotify.song {
                        debugPrint("Spotify Album: \(appleMusicSong.getAlbum())")
                        debugPrint("Apple   Album: \(translatedSongData.getAlbum())")
                        // find album link through translated song
                        let spotifyAlbum = SpotifyAlbumData(albumID: translatedSongData.getAlbumID())
                        await spotifyAlbum.getSpotifyAlbumDataByID()
                        translatedLink = spotifyAlbum.spotifyURL
                        
                        translatedSong = translatedSongData
                        altSongs = spotify.getAllSongs()
                        
                        for i in altSongs {
                            let album = SpotifyAlbumData(albumID: i.getAlbumID())
                            await album.getSpotifyAlbumDataByID()
                            let altURL = album.spotifyURL
                            debugPrint("Alt: \(altURL)")
                            altSongURLs.append(altURL)
                        }
                    }
                } else {
                    debugPrint("Trying search again")
                    await spotify.getSpotifySongDataBySearch(songRef: appleMusicSong, narrowSearch: false)
                    _ = spotify.parseToObject(songRef: appleMusicSong)
                    if let translatedSongData = spotify.song {
                        debugPrint("Spotify Album: \(appleMusicSong.getAlbum())")
                        debugPrint("Apple   Album: \(translatedSongData.getAlbum())")
                        // find album link through translated song
                        let spotifyAlbum = SpotifyAlbumData(albumID: translatedSongData.getAlbumID())
                        await spotifyAlbum.getSpotifyAlbumDataByID()
                        translatedLink = spotifyAlbum.spotifyURL
                        
                        translatedSong = translatedSongData
                        altSongs = spotify.getAllSongs()
                        
                        for i in altSongs {
                            let album = SpotifyAlbumData(albumID: i.getAlbumID())
                            await album.getSpotifyAlbumDataByID()
                            let altURL = album.spotifyURL
                            debugPrint("Alt: \(altURL)")
                            altSongURLs.append(altURL)
                        }
                    }
                }
            }
        }
        
        return (translatedLink, translatedSong, altSongURLs, altSongs)
    }
    
    private func findTranslatedLink() async -> (String?, Song?, MusicType, [String], [Song]) {
        var musicLink: String? = nil
        var keySong: Song? = nil
        var type: MusicType = .song
        var altURLs: [String] = []
        var altkeySongs: [Song] = []
        
        // first identify which platform the link starts with
        findPlatform()
        
        if (starterSource == Platform.spotify) {
            // get Apple Music link from Spotify link
            if (starterLink!.absoluteString.contains("track")) {
                let results = await translateSpotifyToAppleMusic()
                musicLink = results.0
                keySong = results.1
                type = .song
                altURLs = results.2
                altkeySongs = results.3
            } else if (starterLink!.absoluteString.contains("album")) {
                let results = await translateAlbumSpotifyToAppleMusic()
                musicLink = results.0
                keySong = results.1
                type = .album
                altURLs = results.2
                altkeySongs = results.3
            }
        } else if (starterSource == Platform.appleMusic) {
            // get Spotify link from Apple Music link
            if (starterLink!.absoluteString.contains("i=")) {
                let results = await translateAppleMusicToSpotify()
                musicLink = results.0
                keySong = results.1
                type = .song
                altURLs = results.2
                altkeySongs = results.3
            } else {
                let results = await translateAlbumAppleMusicToSpotify()
                musicLink = results.0
                keySong = results.1
                type = .album
                altURLs = results.2
                altkeySongs = results.3
            }
        }
        
        return (musicLink, keySong, type, altURLs, altkeySongs)
    }
    
    func translateData(link: String) async -> (String, Song?, MusicType, [String], [Song]) {
        if let songLink = URL(string: link) {
            if (songLink.host != "open.spotify.com" && songLink.host != "music.apple.com") {
                return ("Link is from an unsupported source", nil, .song, [], [])
            } else {
                starterLink = songLink
            }
        } else {
            return ("Bad link", nil, .song, [], [])
        }
        
        var link: String?
        let results = await findTranslatedLink()
        link = results.0
        
        if link != nil {
            return (link!, results.1, results.2, results.3, results.4)
        } else {
            // TODO: allow user to browse for alts if there was no exact hit. Will need to check if alternatives are available
            return ("No equivalent song or there was an error", nil, .song, [], [])
        }
    }
}


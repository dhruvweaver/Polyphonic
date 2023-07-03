//
//  SongData.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/11/22.
//

import Foundation

/**
 Enum specifying the source music type. Either a Song or Album.
 */
enum MusicType {
    case song, album
}

/**
 Enum specifying how close a given match is. This can be used for determining whether to try a broader search.
 none = 0
 close = 1
 veryClose = 2
 exact = 3
 */
enum TranslationMatchLevel: Int {
    case none = 0, close, veryClose, exact
}

/**
 Class containing key music translating functions.
 */
class MusicData {
    private var starterLink: URL? = nil
    
    init() {
        
    }
    
    /**
     Enum specifying which platform the link comes from.
     */
    enum Platform {
        case unknown, spotify, appleMusic
    }
    private var starterSource: Platform = Platform.unknown
    
    var song: Song? = nil
    var albumData: Album? = nil
    
    // identifies link's source platform
    /**
     Sets `starterSource` variable to the platform of origin of the provided starting link.
     */
    private func findPlatform() {
        let linkString = starterLink!.absoluteString
        if (linkString.contains("apple")) {
            starterSource = Platform.appleMusic
        } else if (linkString.contains("spotify")) {
            starterSource = Platform.spotify
        }
    }
    
    /**
     Gets the appropriate song ID given a link and a starter platform.
     - Parameter platform: `Platform` enum type.
     - Returns: Song ID as a `String`.
     */
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
    
    /**
     Gets the appropriate album ID given a link and a starter platform.
     - Parameter platform: `Platform` enum type.
     - Returns: Album ID as a `String`.
     */
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
    
    /**
     Translates song links from Spotify to Apple Music.
     - Returns: response containing a `String` for the translated link, a `Song` for the translated song object, a `List` of  alternate URLs as `String`s,  a `List` of alternate `Song` objects, and the match confidence as a `TranslationMatchLevel`.
     */
    private func translateSpotifyToAppleMusic() async -> (String?, Song?, [String], [Song], TranslationMatchLevel) {
        var translatedLink: String? = nil
        var translatedSong: Song? = nil
        var altSongURLs: [String] = []
        var altSongs: [Song] = []
        var match: TranslationMatchLevel = .none
        
        print("Link is from Spotify")
        // Spotify API call can be made with the Spotify ID, get song ID
        let spotifyID = getSongID(platform: Platform.spotify)
        // create SpotifySongData object
        let spotify = SpotifySongData(songID: spotifyID)
        // create song object from HTTP request
        await spotify.getSpotifySongDataByID()
        _ = spotify.parseToObject(songRef: nil, vagueMatching: false)
        // if all goes well, continue to translation
        if let spotifySong = spotify.song {
            song = Song(title: spotifySong.getTitle(), ISRC: spotifySong.getISRC(), artists: spotifySong.getArtists(), album: spotifySong.getAlbum(), albumID: spotifySong.getAlbumID(), explicit: spotifySong.getExplicit(), trackNum: spotifySong.getTrackNum())
            // create AppleMusicSongData object
            let appleMusic = AppleMusicSongData(songID: nil)
            // this function will talk to the Apple Music API, it requires already known song data
            await appleMusic.getAppleMusicSongDataBySearch(songRef: spotifySong, narrowSearch: true)
            
            /*
             parse func returns `TranslationMatchLevel` enum depending on how successful the search was.
             A value of `exact` (3) means that there was an exact match, otherwise broaden the search
             */
            if (appleMusic.parseToObject(songRef: spotifySong, vagueMatching: false).rawValue == TranslationMatchLevel.exact.rawValue) {
                if let translatedSongData = appleMusic.song {
                    debugPrint("Spotify Artist: \(spotifySong.getArtists()[0])")
                    debugPrint("Apple   Artist: \(translatedSongData.getArtists()[0])")
                    // ensure that the translated song matches the original before returning a link -- NOT DOING THAT ANYMORE. MAY NEED TO BRING IT BACK
                    translatedLink = translatedSongData.getTranslatedURLasString()
                    
                    translatedSong = translatedSongData
                    altSongs = appleMusic.getAllSongs()
                    match = .exact
                    
                    for i in altSongs {
                        let altURL = i.getTranslatedURLasString()
                        debugPrint("Alt: \(altURL)")
                        altSongURLs.append(altURL)
                    }
                }
            } else { // an exact match was not found, so the search will be broadened
                debugPrint("No exact match, trying search again")
                
                await appleMusic.getAppleMusicSongDataBySearch(songRef: spotifySong, narrowSearch: false)
                
                /*
                 parse func returns `TranslationMatchLevel` enum depending on how successful the search was
                 A value of `exact` (3) means that there was an exact match, otherwise try matching again with less detail, but using the same search results
                 */
                if (appleMusic.parseToObject(songRef: spotifySong, vagueMatching: false).rawValue == TranslationMatchLevel.exact.rawValue) {
                    if let translatedSongData = appleMusic.song {
                        debugPrint("Spotify Artist: \(spotifySong.getArtists()[0])")
                        debugPrint("Apple   Artist: \(translatedSongData.getArtists()[0])")
                        
                        translatedLink = translatedSongData.getTranslatedURLasString()
                        
                        translatedSong = translatedSongData
                        altSongs = appleMusic.getAllSongs()
                        match = .exact
                        
                        for i in altSongs {
                            let altURL = i.getTranslatedURLasString()
                            debugPrint("Alt: \(altURL)")
                            altSongURLs.append(altURL)
                        }
                    }
                } else { // try matching results using more vague comparisons, we no longer care about how close the results are
                    debugPrint("No exact match, trying more vague matching")
                    
                    // assign match level here since it isn't always "exact"
                    match = appleMusic.parseToObject(songRef: spotifySong, vagueMatching: true)
                    
                    if let translatedSongData = appleMusic.song {
                        debugPrint("Spotify Artist: \(spotifySong.getArtists()[0])")
                        debugPrint("Apple   Artist: \(translatedSongData.getArtists()[0])")
                        
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
        }
        
        return (translatedLink, translatedSong, altSongURLs, altSongs, match)
    }
    
    /**
     Translates song links from Apple Music to Spotify.
     - Returns: response containing a `String` for the translated link, a `Song` for the translated song object, a `List` of  alternate URLs as `String`s, a `List` of alternate `Song` objects, and the match confidence as a `TranslationMatchLevel`.
     */
    private func translateAppleMusicToSpotify() async -> (String?, Song?, [String], [Song], TranslationMatchLevel) {
        var translatedLink: String? = nil
        var translatedSong: Song? = nil
        var altSongURLs: [String] = []
        var altSongs: [Song] = []
        var match: TranslationMatchLevel = .none
        
        print("Link is from Apple Music")
        // Apple Music API call will be made with the Apple Music ID, get song ID
        let appleMusicID = getSongID(platform: Platform.appleMusic)
        // create AppleMusicSongData object
        let appleMusic = AppleMusicSongData(songID: appleMusicID)
        await appleMusic.getAppleMusicSongDataByID()
        _ = appleMusic.parseToObject(songRef: nil, vagueMatching: false)
        // if all goes well, continue to translation
        if let appleMusicSong = appleMusic.song {
            // create SpotifySongData object
            let spotify = SpotifySongData(songID: nil)
            // this function will talk to the Spotify API, it requires already known song data
            await spotify.getSpotifySongDataBySearch(songRef: appleMusicSong, narrowSearch: true)
            // parse func returns bool depending on whether the search was too limited. True means it was fine, otherwise broaden the search
            
            /*
             parse func returns `TranslationMatchLevel` enum depending on how successful the search was.
             A value of `exact` (3) means that there was an exact match, otherwise broaden the search
             */
            if (spotify.parseToObject(songRef: appleMusicSong, vagueMatching: false).rawValue == TranslationMatchLevel.exact.rawValue) {
                if let translatedSongData = spotify.song {
                    debugPrint("Spotify Artist: \(translatedSongData.getArtists()[0])")
                    debugPrint("Apple   Artist: \(appleMusicSong.getArtists()[0])")
                    
                    translatedLink = translatedSongData.getTranslatedURLasString()
                    
                    translatedSong = translatedSongData
                    altSongs = spotify.getAllSongs()
                    match = .exact
                    
                    for i in altSongs {
                        let altURL = i.getTranslatedURLasString()
                        debugPrint("Alt: \(altURL)")
                        altSongURLs.append(altURL)
                    }
                }
            } else { // an exact match was not found, so the search will be broadened
                debugPrint("No exact match, trying search again")
                
                await spotify.getSpotifySongDataBySearch(songRef: appleMusicSong, narrowSearch: false)
                
                /*
                 parse func returns `TranslationMatchLevel` enum depending on how successful the search was
                 A value of `exact` (3) means that there was an exact match, otherwise try matching again with less detail, but using the same search results
                 */
                if (spotify.parseToObject(songRef: appleMusicSong, vagueMatching: false).rawValue == TranslationMatchLevel.exact.rawValue) {
                    if let translatedSongData = spotify.song {
                        debugPrint("Spotify Artist: \(translatedSongData.getArtists()[0])")
                        debugPrint("Apple   Artist: \(appleMusicSong.getArtists()[0])")
                        
                        translatedLink = translatedSongData.getTranslatedURLasString()
                        
                        translatedSong = translatedSongData
                        altSongs = spotify.getAllSongs()
                        match = .exact
                        
                        for i in altSongs {
                            let altURL = i.getTranslatedURLasString()
                            debugPrint("Alt: \(altURL)")
                            altSongURLs.append(altURL)
                        }
                    }
                } else { // try matching results using more vague comparisons, we no longer care about how close the results are
                    debugPrint("No exact match, trying more vague matching")
                    
                    // assign match level here since it isn't always "exact"
                    match = spotify.parseToObject(songRef: appleMusicSong, vagueMatching: true)
                    
                    if let translatedSongData = spotify.song {
                        debugPrint("Spotify Artist: \(translatedSongData.getArtists()[0])")
                        debugPrint("Apple   Artist: \(appleMusicSong.getArtists()[0])")
                        
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
        }
        
        return (translatedLink, translatedSong, altSongURLs, altSongs, match)
    }
    
    /**
     Translates album links from Spotify to Apple Music.
     - Returns: response containing a `String` for the translated link, a `Song` for the key translated song object, a `List` of  alternate key song URLs as `String`s, a `List` of alternate key `Song` objects, and the match confidence as a `TranslationMatchLevel`.
     */
    private func translateAlbumSpotifyToAppleMusic() async -> (String?, Song?, [String], [Song], TranslationMatchLevel) {
        var translatedLink: String? = nil
        var translatedSong: Song? = nil
        var altSongURLs: [String] = []
        var altSongs: [Song] = []
        var match: TranslationMatchLevel = .none
        
        debugPrint("Album link is from Spotify")
        // Spotify API call can be made with the Spotify ID, get song ID
        let spotifyID = getAlbumID(platform: .spotify)
        debugPrint(spotifyID)
        // create SpotifySongData object
        let spotify = SpotifyAlbumData(albumID: spotifyID)
        // create song object from HTTP request
        await spotify.getSpotifyAlbumDataByID()
        spotify.parseToObject()
        // if all goes well, continue to translation
        if let spotifyAlbum = spotify.album {
            debugPrint(spotifyAlbum.getTitle())
            debugPrint(spotifyAlbum.getKeySongID())
            // setup key song link for accurate album fetching
            let spotifySongData = SpotifySongData(songID: spotifyAlbum.getKeySongID())
            await spotifySongData.getSpotifySongDataByID()
            _ = spotifySongData.parseToObject(songRef: nil, vagueMatching: false)
            if let spotifySong = spotifySongData.song {
                debugPrint(spotifySong.getTitle())
                // create AppleMusicSongData object
                let appleMusic = AppleMusicSongData(songID: nil)
                // this function will talk to the Apple Music API, it requires already known song data
                await appleMusic.getAppleMusicSongDataBySearch(songRef: spotifySong, narrowSearch: true)
                
                /*
                 parse func returns `TranslationMatchLevel` enum depending on how successful the search was.
                 A value of `close` (1) or better means that there was a match, otherwise broaden the search
                 */
                match = appleMusic.parseToObject(songRef: spotifySong, vagueMatching: false) // assign match here because there are many accepted levels
                if (match.rawValue >= TranslationMatchLevel.close.rawValue) {
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
                    
                    match = appleMusic.parseToObject(songRef: spotifySong, vagueMatching: false) // assign match here because there are many accepted levels
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
        
        return (translatedLink, translatedSong, altSongURLs, altSongs, match)
    }
    
    /**
     Translates album links from Apple Music to Spotify.
     - Returns: response containing a `String` for the translated link, a `Song` for the key translated song object, a `List` of  alternate key song URLs as `String`s, a `List` of alternate key `Song` objects, and the match confidence as a `TranslationMatchLevel`.
     */
    private func translateAlbumAppleMusicToSpotify() async -> (String?, Song?, [String], [Song], TranslationMatchLevel) {
        var translatedLink: String? = nil
        var translatedSong: Song? = nil
        var altSongURLs: [String] = []
        var altSongs: [Song] = []
        var match: TranslationMatchLevel = .none
        
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
            _ = appleMusicSongData.parseToObject(songRef: nil, vagueMatching: false)
            if let appleMusicSong = appleMusicSongData.song {
                debugPrint(appleMusicSong.getTitle())
                // create AppleMusicSongData object
                let spotify = SpotifySongData(songID: nil)
                // this function will talk to the Apple Music API, it requires already known song data
                await spotify.getSpotifySongDataBySearch(songRef: appleMusicSong, narrowSearch: true)
                
                /*
                 parse func returns `TranslationMatchLevel` enum depending on how successful the search was.
                 A value of `close` (1) or better means that there was a match, otherwise broaden the search
                 */
                match = spotify.parseToObject(songRef: appleMusicSong, vagueMatching: false) // assign match here because there are many accepted levels
                if (match.rawValue >= TranslationMatchLevel.close.rawValue) {
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
                    
                    match = spotify.parseToObject(songRef: appleMusicSong, vagueMatching: false) // assign match here because there are many accepted levels
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
        
        return (translatedLink, translatedSong, altSongURLs, altSongs, match)
    }
    
    /**
     Identify source platform, music type (song or album), and then call the related function to get the corresponding data from the output source.
     - Returns: response containing a `String` for the translated key song link, a `Song` for the key translated song object, a `MusicType` for determining how to interpret the results, a `List` of  alternate key song URLs as `String`s, a `List` of alternate key `Song` objects, and the match confidence as a `TranslationMatchLevel`.
     */
    private func findTranslatedLink() async -> (String?, Song?, MusicType, [String], [Song], TranslationMatchLevel) {
        var musicLink: String? = nil
        var keySong: Song? = nil
        var type: MusicType = .song
        var altURLs: [String] = []
        var altkeySongs: [Song] = []
        var match: TranslationMatchLevel = .none
        
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
                match = results.4
            } else if (starterLink!.absoluteString.contains("album")) {
                let results = await translateAlbumSpotifyToAppleMusic()
                musicLink = results.0
                keySong = results.1
                type = .album
                altURLs = results.2
                altkeySongs = results.3
                match = results.4
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
                match = results.4
            } else {
                let results = await translateAlbumAppleMusicToSpotify()
                musicLink = results.0
                keySong = results.1
                type = .album
                altURLs = results.2
                altkeySongs = results.3
                match = results.4
            }
        }
        
        return (musicLink, keySong, type, altURLs, altkeySongs, match)
    }
    
    /**
     Ensures that the provided URL (in `String` form) is valid, and if so gets data related to the translated results.
     If that data is valid it is returned as is, otherwise an error message will replace the translated link and the other data will be returned as empty. The `MusicType` will be `.song` in this scenario.
     - Parameter link: Link to be translated.
     - Returns: response containing a `String` for the translated key song link, a `Song` for the key translated song object, a `MusicType` for determining how to interpret the results, a `List` of  alternate key song URLs as `String`s, a `List` of alternate key `Song` objects, and the match confidence as a `TranslationMatchLevel`.
     */
    func translateData(link: String) async -> (String, Song?, MusicType, [String], [Song], TranslationMatchLevel) {
        if let songLink = URL(string: link) {
            if (songLink.host != "open.spotify.com" && songLink.host != "music.apple.com") {
                return ("Link not supported", nil, .song, [], [], .none)
            } else {
                starterLink = songLink
            }
        } else {
            return ("Bad link", nil, .song, [], [], .none)
        }
        
        var link: String?
        let results = await findTranslatedLink()
        link = results.0
        
        if link != nil {
            return (link!, results.1, results.2, results.3, results.4, results.5)
        } else {
            // TODO: allow user to browse for alts if there was no exact hit. Will need to check if alternatives are available
            return ("No equivalent song or there was an error", nil, .song, [], [], .none)
        }
    }
}


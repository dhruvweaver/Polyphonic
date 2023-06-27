//
//  Utilities.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/21/22.
//

import Foundation

/**
 For use when querying Spotify's API.
 Removes words in parentheses, after dashes, and optionally adds back any important search terms that may have been removed.
 Such as for remixes and deluxe editions.
 - Parameter title: Title of the song or album to be cleaned for searching.
 - Parameter forSearching: Whether or not to add search terms from parentheses/after dashes back to the title.
 - Returns: Cleaned title.
 */
func cleanSpotifyText(title: String, forSearching: Bool) -> String {
    var clean = title
    
    // normalize everything to lowercased lettering
    clean = clean.lowercased()
    clean = uncensorText(text: clean)
    
    clean = clean.replacingOccurrences(of: " - ", with: " 𝜌 ")
    clean = clean.replacingOccurrences(of: "+-+", with: " 𝜌 ")
    if let indDash = clean.firstIndex(of: "𝜌") {
        clean = String(clean[clean.startIndex...clean.index(indDash, offsetBy: -2)])
    }
    clean = clean.replacingOccurrences(of: "+", with: " ")
    clean = clean.replacingOccurrences(of: "-", with: "+")
    if let indParen = clean.firstIndex(of: "(") {
        clean = String(clean[clean.startIndex...clean.index(indParen, offsetBy: -2)])
    }
    if let indColon = clean.firstIndex(of: ":") {
        clean = String(clean[clean.startIndex...clean.index(indColon, offsetBy: -1)])
    }
    
    // remove special characters
    clean = clean.replacingOccurrences(of: "/", with: "")
    clean = clean.replacingOccurrences(of: "\\", with: "")
    clean = clean.replacingOccurrences(of: "'", with: "")
    clean = clean.replacingOccurrences(of: "\"", with: "")
    clean = clean.replacingOccurrences(of: ",", with: "")
    clean = clean.replacingOccurrences(of: ". ", with: " ")
    clean = clean.replacingOccurrences(of: " & ", with: " ")
    
    // add key search terms based on what was removed from qualifiers in original song or album name
    if (forSearching) {
        if (title.contains("Remix") && !clean.contains("Remix")) {
            clean.append(contentsOf: " remix")
        }
        if (title.contains("Deluxe") && !clean.contains("Deluxe")) {
            clean.append(contentsOf: " deluxe")
        }
        if (title.contains("Acoustic") && !clean.contains("Acoustic")) {
            clean.append(contentsOf: " acoustic")
        }
        if (title.contains("Demo") && !clean.contains("Demo")) {
            clean.append(contentsOf: " demo")
        }
        if (title.contains("Radio") && !clean.contains("Radio")) {
            clean.append(contentsOf: " radio")
        }
        if (title.contains("Edit") && !title.contains("Edition") && !clean.contains("Edit")) {
            clean.append(contentsOf: " edit")
        }
        if (title.contains("Edition") && !clean.contains("Edition")) {
            clean.append(contentsOf: " edition")
        }
        if (title.contains("EP") && !clean.contains("EP")) {
            clean.append(contentsOf: " ep")
        }
    }
    
    return clean
}

// removes items in parentheses and after dashes, adds important search terms like remixes and deluxe editions
/**
 For use when querying Apple Music's API.
 Removes words in parentheses, after dashes, and optionally adds back any important search terms that may have been removed.
 Such as for remixes and deluxe editions. Formats title with "+" replacing spaces.
 - Parameter title: Title of the song or album to be cleaned for searching.
 - Parameter forSearching: Whether or not to add search terms from parentheses/after dashes back to the title.
 - Returns: Cleaned title.
 */
func cleanAppleMusicText(title: String, forSearching: Bool) -> String {
    var clean = title
    
    clean = clean.lowercased()
    
    clean = clean.replacingOccurrences(of: " - ", with: " 𝜌 ")
    clean = clean.replacingOccurrences(of: "+-+", with: " 𝜌 ")
    if let indDash = clean.firstIndex(of: "𝜌") {
        clean = String(clean[clean.startIndex...clean.index(indDash, offsetBy: -2)])
    }
    clean = clean.replacingOccurrences(of: "+", with: " ")
    clean = clean.replacingOccurrences(of: "-", with: "+")
    if let indParen = clean.firstIndex(of: "(") {
        clean = String(clean[clean.startIndex...clean.index(indParen, offsetBy: -2)])
    }
    if let indColon = clean.firstIndex(of: ":") {
        clean = String(clean[clean.startIndex...clean.index(indColon, offsetBy: -1)])
    }
    
    // TODO: replace with REGEX
    clean = clean.replacingOccurrences(of: "/", with: "")
    clean = clean.replacingOccurrences(of: "\\", with: "")
    clean = clean.replacingOccurrences(of: "'", with: "")
    clean = clean.replacingOccurrences(of: "\"", with: "")
    clean = clean.replacingOccurrences(of: ",", with: "")
    clean = clean.replacingOccurrences(of: ". ", with: " ")
    clean = clean.replacingOccurrences(of: " & ", with: " ")
    
    if (forSearching) {
        if (title.contains("Remix") && !clean.contains("Remix")) {
            clean.append(contentsOf: "+remix")
        }
        if (title.contains("Deluxe") && !clean.contains("Deluxe")) {
            clean.append(contentsOf: "+deluxe")
        }
        if (title.contains("Acoustic") && !clean.contains("Acoustic")) {
            clean.append(contentsOf: "+acoustic")
        }
        if (title.contains("Demo") && !clean.contains("Demo")) {
            clean.append(contentsOf: "+demo")
        }
        if (title.contains("Radio") && !clean.contains("Radio")) {
            clean.append(contentsOf: "+radio")
        }
        if (title.contains("Edit") && !title.contains("Edition") && !clean.contains("Edit")) {
            clean.append(contentsOf: "+edit")
        }
        if (title.contains("Edition") && !clean.contains("Edition")) {
            clean.append(contentsOf: "+edition")
        }
        if (title.contains("EP") && !clean.contains("EP")) {
            clean.append(contentsOf: "+ep")
        }
    }
    
    clean = uncensorText(text: clean)
    
    return clean
}

/**
 Cleans text by removing special characters from a `String`.
 - Parameter text: Text to be cleaned.
 - Returns: Cleaned text.
 */
func cleanText(text: String) -> String {
    debugPrint(text)
    var clean = text
    clean = removeSpecialCharsFromString(text: clean)
    
    clean = clean.lowercased()
    return clean
}

/**
 Uncesors text. Useful when interpreting song and album names from Apple Music, which come back censored.
 - Parameter text: Text to be uncesored.
 - Returns: Uncensored text.
 */
func uncensorText(text: String) -> String {
    var uncensored = text
    uncensored = uncensored.replacingOccurrences(of: "f****n", with: "")
    uncensored = uncensored.replacingOccurrences(of: "f**k", with: "")
    
    return uncensored
}

// removes ampersands and dashes in artist names to simplify search and reduce errors
/**
 Removes ampersands and dashes in artist names to simplify search terms and reduce errors.
 - Parameter name: Name to be cleaned.
 - Parameter forSearching: If true, replaces "-" with "+" to not avoid errors.
 - Returns: Cleaned artist name.
 */
func cleanArtistName(name: String, forSearching: Bool) -> String {
    var clean = name
    if (forSearching) {
        clean = clean.replacingOccurrences(of: "-", with: "+")
    }
    clean = clean.replacingOccurrences(of: " & ", with: "*")
    if let indSep = clean.firstIndex(of: "*") {
        clean = String(clean[clean.startIndex...clean.index(indSep, offsetBy: -1)])
    }
    
    clean = clean.lowercased()
    
    return clean
}

/**
 Removes special characters from a `String`.
 - Parameter text: Text to have special characters removed.
 - Returns: Text without special characters.
 */
func removeSpecialCharsFromString(text: String) -> String {
    let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
    return text.filter {okayChars.contains($0) }
}

/**
 Gets image data from a URL, must verify that `artURLasString` is not `nil`.
 - Returns: `Data` containing image data that was found from URL. Can return `nil` if there is a problem.
 */
func getImageData(imageURL: URL) async -> Data? {
    var imageData: Data? = nil
    
    print("Getting image from \(imageURL.absoluteString)")
    
    // Creating a session object with the default configuration
    let urlSession = URLSession(configuration: .default)
    
    do {
        let (data, _) = try await urlSession.data(from: imageURL)
        debugPrint("Decoded image!")
        
        imageData = data
    } catch {
        debugPrint("Error loading \(imageURL): \(String(describing: error))")
        
        imageData = nil
    }
    
    return imageData
}

// removes duplicates from list of Song objects
//func removeDuplicates(songs: inout [Song]) {
//    let uniqueSongs = Array(Set(songs))
//    songs = uniqueSongs
//}

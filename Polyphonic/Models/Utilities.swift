//
//  Utilities.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/21/22.
//

import Foundation

// removes items in parentheses and after dashes, adds important search terms like remixes and deluxe editions
func cleanSpotifyText(title: String, forSearching: Bool) -> String {
    var clean = title
    clean = clean.replacingOccurrences(of: " - ", with: " * ")
    clean = clean.replacingOccurrences(of: "+-+", with: " * ")
    if let indDash = clean.firstIndex(of: "*") {
        clean = String(clean[clean.startIndex...clean.index(indDash, offsetBy: -2)])
    }
    clean = clean.replacingOccurrences(of: "+", with: " ")
    clean = clean.replacingOccurrences(of: "-", with: "+")
    if let indParen = clean.firstIndex(of: "(") {
        clean = String(clean[clean.startIndex...clean.index(indParen, offsetBy: -2)])
    }
    if let indColon = clean.firstIndex(of: ":") {
        clean = String(clean[clean.startIndex...clean.index(indColon, offsetBy: -2)])
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
        debugPrint(clean)
    }
    
    // normalize everything to lowercased lettering
    clean = clean.lowercased()
    
    return clean
}

// removes items in parentheses and after dashes, adds important search terms like remixes and deluxe editions
func cleanAppleMusicText(title: String, forSearching: Bool) -> String {
    var clean = title
    clean = clean.replacingOccurrences(of: " - ", with: " * ")
    clean = clean.replacingOccurrences(of: "+-+", with: " * ")
    if let indDash = clean.firstIndex(of: "*") {
        clean = String(clean[clean.startIndex...clean.index(indDash, offsetBy: -2)])
    }
    clean = clean.replacingOccurrences(of: "+", with: " ")
    clean = clean.replacingOccurrences(of: "-", with: "+")
    if let indParen = clean.firstIndex(of: "(") {
        clean = String(clean[clean.startIndex...clean.index(indParen, offsetBy: -2)])
    }
    if let indColon = clean.firstIndex(of: ":") {
        clean = String(clean[clean.startIndex...clean.index(indColon, offsetBy: -2)])
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
        debugPrint(clean)
    }
    
    clean = clean.lowercased()
    
    return clean
}

// removes ampersands and dashes in artist names to simplify search and reduce errors
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

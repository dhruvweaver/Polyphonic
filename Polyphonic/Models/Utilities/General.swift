//
//  Utilities.swift
//  Polyphonic
//
//  Created by Dhruv Weaver on 6/21/22.
//

import Foundation

/**
 Calculate Levenshtein distance between two strings. Distance is determined by number of edits needed to make one string match the other.
 - Parameter str1: First string to be compared.
 - Parameter str2: Second string to be compared.
 - Returns Levenshtein distance between both strings. The lower the better.
 */
func levDis(_ str1: String, _ str2: String) -> Int {
    let empty = [Int](repeating:0, count: str2.count)
    var last = [Int](0...str2.count)

    for (i, char1) in str1.enumerated() {
        var cur = [i + 1] + empty
        for (j, char2) in str2.enumerated() {
            cur[j + 1] = char1 == char2 ? last[j] : min(last[j], last[j + 1], cur[j]) + 1
        }
        last = cur
    }
    return last.last!
}

/**
 Simplify music text for search optimization. Also allows for more or less information to be kept after simplification.
 - Parameter title: String to be simplified.
 - Parameter broadSearch: Whether or not to include details (remastered, remix, etc) after simplification.
 - Returns Simplified string.
 */
func simplifyMusicText(title: String, broadSearch: Bool) -> String {
    var simpleText = title
    var remaster: Bool = false
    var remix: Bool = false
    
//    debugPrint("Original text: \(simpleText)")
    
    // Ignore case sensitivity
    simpleText = simpleText.lowercased()
    
    // keep remaster as search term if needed
    if (!broadSearch && simpleText.contains("remaster")) {
        remaster = true
    }
    
    // remove text after a dash unless it's used to define a remix
    if (simpleText.contains("remix")) {
        remix = true
    }
    
    // handle featured artists. If not a broad search, they will be removed by the parenthesis
    if (!broadSearch) {
        let pattern = "\\(feat\\.\\s*([^)]*)\\)"
        let regex = try! NSRegularExpression(pattern: pattern)

        let range = NSRange(simpleText.startIndex..<simpleText.endIndex, in: simpleText)
        simpleText = regex.stringByReplacingMatches(in: simpleText, options: [], range: range, withTemplate: "$1")
    }
    
    // Remove words in parentheses
    simpleText = simpleText.replacingOccurrences(of: "\\([^()]*\\)", with: "", options: .regularExpression)
    // Remove words in brackets
    simpleText = simpleText.replacingOccurrences(of: "\\[[^()]*\\]", with: "", options: .regularExpression)
    // remove text after dash
    simpleText = removeTextAfterDash(simpleText)
    
    simpleText = uncensorText(text: simpleText)
    
    // Remove special characters
    simpleText = simpleText.replacingOccurrences(of: "-", with: " ")
    
    var characterSet: CharacterSet
    let specialChars = "àáâäèéêëìíîïòóôöùúûüñçðæ:"
    let specialSet = CharacterSet(charactersIn: "\(specialChars)")
    
    if (!broadSearch) {
        simpleText = convertToLatinCharacters(simpleText)
        characterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz1234567890.& ").union(specialSet)
    } else {
        characterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz1234567890 ").union(specialSet)
    }
    simpleText = simpleText.components(separatedBy: characterSet.inverted).joined(separator: "")
    
   
    if (!broadSearch) {
        if (remaster) {
            // add remaster keyword
            simpleText = "\(simpleText) remaster"
        }
        if (remix) {
            // add remaster keyword
            simpleText = "\(simpleText) remix"
        }
    }
    
    // Remove unnecessary words if they are not the only word in the song
    characterSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
    let components = simpleText.components(separatedBy: characterSet)
    let words = components.filter { !$0.isEmpty }
    
    if (words.count > 1) {
        var unnecessaryWords = ["a", "an", "in", "on", "at", "and", "or", "degrees"] // these could be problematic
        
        if (broadSearch) {
            unnecessaryWords.append("remastered")
            unnecessaryWords.append("remaster")
            unnecessaryWords.append("remix")
            unnecessaryWords.append("mix")
        }
        
        let wordPattern = "\\b(" + unnecessaryWords.joined(separator: "|") + ")\\b"
        simpleText = simpleText.replacingOccurrences(
            of: wordPattern,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
    }
    
    simpleText = simpleText.replacingOccurrences(of: "&", with: " ")
    
    // Simplify variations
    
    // Step 6: Extract key words
    let keywords = simpleText.components(separatedBy: .whitespaces)
        .filter { !$0.isEmpty }
    
    // Join the keywords with a space to form the final simplified query
    let finalText = keywords.joined(separator: " ")
    
    return finalText
}

/**
 Converts all characters in a string to latin characters.
 - Parameter input: String to be converted.
 - Returns Converted string.
 */
func convertToLatinCharacters(_ input: String) -> String {
    let mutableString = NSMutableString(string: input) as CFMutableString
    CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
    CFStringTransform(mutableString, nil, kCFStringTransformStripCombiningMarks, false)
    return mutableString as String
}

/**
 Removes all text in a string after a hyphen (includes spacing, i.e. "` - `").
 - Parameter input: String to have hyphenated section removed.
 - Returns String without text after hyphenation.
 */
func removeTextAfterDash(_ input: String) -> String {
    let components = input.components(separatedBy: " - ")
    if let firstComponent = components.first {
        return firstComponent.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
        return input
    }
}

/**
 Normalize string, particularly useful for comparing strings with Levenshtein distance.
 - Parameter str: String to be normalized.
 - Returns Normalized string.
 */
func normalizeString(str: String) -> String {
    var normalizedStr = str.lowercased()
    normalizedStr = str.trimmingCharacters(in: .whitespacesAndNewlines)
    normalizedStr = str.replacingOccurrences(of: "[^a-zA-Z0-9]+", with: "", options: .regularExpression)
    normalizedStr = str.precomposedStringWithCanonicalMapping
    
    return normalizedStr
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

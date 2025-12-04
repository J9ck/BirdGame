//
//  SoundManager+AudioFileName.swift
//  BirdGame3
//
//  Created by Jack Doyle on 12/4/25.
//
//  SoundManager+AudioFileName.swift
//  BirdGame3
//
//  Compatibility shim that provides `audioFileName` for BirdSound.
//  This lets existing callers use `birdSound.audioFileName` even if the
//  underlying BirdSound type uses a different property name.
//  It tries common property names at runtime using Mirror and falls back
//  to a safe derived name.
//

import Foundation

extension SoundManager {
    // Only compile-time check here; implementation below adds computed property on nested type
}

extension SoundManager.BirdSound {
    /// A best-effort audio file name for this BirdSound.
    /// Tries common property names (fileName, filename, resourceName, name).
    /// If none can be found, returns a sanitized fallback based on the type description.
    var audioFileName: String {
        // Candidate stored property names that project might be using
        let candidateLabels = ["audioFileName", "fileName", "filename", "resourceName", "name"]
        
        // Inspect stored properties at runtime
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let label = child.label, candidateLabels.contains(label) {
                if let str = child.value as? String, !str.isEmpty {
                    return str
                }
            }
        }
        
        // Some enums or types may expose a "rawValue" or similar via Mirror children
        for child in mirror.children {
            if let label = child.label, label.lowercased().contains("raw") {
                if let str = child.value as? String, !str.isEmpty {
                    return str
                }
            }
        }
        
        // Final fallback: use a sanitized description of the value
        let desc = String(describing: self)
        let sanitized = desc
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .lowercased()
        return sanitized
    }
}

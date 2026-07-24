//
//  FilesProvide.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 23.07.26.
//

import Foundation
import UniformTypeIdentifiers

@Observable
class WallpaperUrlProvider {
    private var currentlyAccessedFolder: URL?
    
    func startAccessingSecurityScopedResource(at url: URL) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        if hasAccess {
            currentlyAccessedFolder = url
        }
    }
    
    func stopAccessingSecurityScopedResource() {
        currentlyAccessedFolder?.stopAccessingSecurityScopedResource()
        currentlyAccessedFolder = nil
    }
    
    func retrieveMediaURLs(from url: URL?) -> [URL] {
        guard let url = url else { return [] }
        
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            return try getDirectoryItems(from: url, conformsToContentType: .audiovisualContent)
        } catch {
            print("Failed to read directory: \(error.localizedDescription)")
            return []
        }
    }
}

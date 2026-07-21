//
//  AppConfigService.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import Foundation

class SettingsService {
    private static let moviesDirectoryKey = "moviesDirectoryBookmark"
    private static let selectedMovieFilenameKey = "selectedMovieFilename"
    
    // Retain global access so the wallpaper background process can read the video files
    static var accessedDirectoryURL: URL?
    
    static func loadSettings() -> Settings {
        let moviesDirectory = loadBookmark(forKey: moviesDirectoryKey)
        var selectedMovie: URL? = nil
        
        if let directory = moviesDirectory {
            updateDirectoryAccess(directory)
            
            if let filename = UserDefaults.standard.string(forKey: selectedMovieFilenameKey) {
                selectedMovie = directory.appendingPathComponent(filename)
            }
        }
        
        return Settings(moviesDirectory: moviesDirectory, selectedMovie: selectedMovie)
    }
    
    static func storeSettings(settings: Settings) {
        if let directory = settings.moviesDirectory {
            updateDirectoryAccess(directory)
            saveBookmark(for: directory, key: moviesDirectoryKey)
        } else {
            UserDefaults.standard.removeObject(forKey: moviesDirectoryKey)
        }
        
        if let movieURL = settings.selectedMovie {
            UserDefaults.standard.set(movieURL.lastPathComponent, forKey: selectedMovieFilenameKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedMovieFilenameKey)
        }
    }
    
    static func updateDirectoryAccess(_ url: URL) {
        accessedDirectoryURL?.stopAccessingSecurityScopedResource()
        if url.startAccessingSecurityScopedResource() {
            accessedDirectoryURL = url
        }
    }
    
    // MARK: - Bookmark Helpers
    private static func saveBookmark(for url: URL, key: String) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: key)
        } catch {
            print("Failed to save bookmark for \(key): \(error.localizedDescription)")
        }
    }
    
    private static func loadBookmark(forKey key: String) -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                saveBookmark(for: url, key: key)
            }
            
            return url
        } catch {
            print("Failed to resolve bookmark: \(error.localizedDescription)")
            return nil
        }
    }
}

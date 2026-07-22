//
//  SettingsProvider.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import Foundation

class SettingsProvider {
    private static let settingKeyWallpaperDirectory = "wallpaperDirectoryBookmark"
    private static let settingKeySelectedWallpaperFilename = "selectedWallpaperFilename"
    private static let settingKeySuffleIntervalInMin = "suffleIntervalInMin"
    private static let settingKeyAutoFadeDurationInSec = "autoFadeDurationInSec"
    
    // Retain global access so the wallpaper background process can read the video files
    static var accessedDirectoryURL: URL?
    
    static func loadSettings() -> Settings {
        let wallpaperDirecotory = loadBookmark(forKey: settingKeyWallpaperDirectory)
        if let directory = wallpaperDirecotory {
            updateDirectoryAccess(directory)
        }
        
        var selectedWallpaper: URL? = nil
        if let filename = UserDefaults.standard.string(forKey: settingKeySelectedWallpaperFilename) {
            selectedWallpaper = URL.init(string: filename)
        }
        
        let suffleIntervalInMin: Int? = UserDefaults.standard.integer(forKey: settingKeySuffleIntervalInMin)
        let autoFadeDurationInSec: Int? = UserDefaults.standard.integer(forKey: settingKeyAutoFadeDurationInSec)
        
        let loaded_settings = Settings(
            wallpaperDirectory: wallpaperDirecotory,
            selectedWallpaper: selectedWallpaper,
            autoFadeDurationInSec: autoFadeDurationInSec,
            shuffleIntervalInMin: suffleIntervalInMin,
        )
        print("loaded \(loaded_settings)")
        return loaded_settings
    }
    
    static func storeSettings(settings: Settings) {
        print("storing \(settings)")
        handleStoringBookmark(for: settings.wallpaperDirectory, key: settingKeyWallpaperDirectory)
        handleStoringValue(for: settings.selectedWallpaper?.absoluteString, key: settingKeySelectedWallpaperFilename)
        handleStoringValue(for: settings.shuffleIntervalInMin, key: settingKeySuffleIntervalInMin)
        handleStoringValue(for: settings.autoFadeDurationInSec, key: settingKeyAutoFadeDurationInSec)
    }
    
    static func handleStoringBookmark(for url: URL?, key: String) {
        if let nonNilUrl = url {
            updateDirectoryAccess(nonNilUrl)
            saveBookmark(for: nonNilUrl, key: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    static func handleStoringValue(for value: Any?, key: String) {
        if let nonNilValue = value {
            UserDefaults.standard.set(nonNilValue, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
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

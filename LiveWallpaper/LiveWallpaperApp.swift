//
//  LiveWallpaperApp.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct LiveWallpaperApp: App {
    // Load settings once at the App level
    @State private var settings = SettingsProvider.loadSettings()
    @State private var wallpapers: [URL] = []
    @StateObject private var wallpaperManagerService: WallpaperWindowManager
    @StateObject private var wallpaperShuffler: WallpaperShuffler
    @Environment(\.openWindow) private var openWindow
    
    init() {
        let loadedSettings = SettingsProvider.loadSettings()
            
        _settings = State(initialValue: loadedSettings)
        _wallpapers = State(initialValue: Self.retrieveMediaURLs(from: loadedSettings.wallpaperDirectory))
        
        let windowManager = WallpaperWindowManager(initialURL: loadedSettings.selectedWallpaper)
        _wallpaperManagerService = StateObject(wrappedValue: windowManager)
        
        let shuffler = WallpaperShuffler(
            currentWallpaperUrl: loadedSettings.selectedWallpaper,
            wallpaperDirectory: loadedSettings.wallpaperDirectory,
            shuffleIntervalInMin: loadedSettings.shuffleIntervalInMin
        )
        
        shuffler.onWallpaperChanged = { [weak windowManager] url in
            windowManager?.updateVideo(url: url)
        }
        
        _wallpaperShuffler = StateObject(wrappedValue: shuffler)
    }
    
    var body: some Scene {
        MainMenu(selectedWallpaper: $settings.selectedWallpaper, wallpapers: wallpapers)
            .onOpenSettings {
                openWindow(id: "settingsWindow")
            }
            .onChange(of: settings.selectedWallpaper) { _, newVideoUrl in
                wallpaperManagerService.updateVideo(url: newVideoUrl)
            }
        
        Window("Settings", id: "settingsWindow") {
            SettingsView(settings: $settings)
                .frame(minWidth: 600, minHeight: 400)
                .onChange(of: settings.selectedWallpaper) { _, newVideoUrl in
                    wallpaperManagerService.updateVideo(url: newVideoUrl)
                }
                .onChange(of: settings.wallpaperDirectory) { _, newDirectory in
                    wallpaperShuffler.updateWallpaperDirectory(newDirectory)
                    wallpapers = Self.retrieveMediaURLs(from: newDirectory)
                }
                .onChange(of: settings.shuffleIntervalInMin) { _, newInterval in
                    wallpaperShuffler.updateShuffleInterval(intervalInMin: newInterval)
                }
        }
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
    }
    
    private static func retrieveMediaURLs(from url: URL?) -> [URL] {
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

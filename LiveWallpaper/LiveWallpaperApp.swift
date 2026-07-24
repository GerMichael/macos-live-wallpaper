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
    @State private var settingsStore: SettingsStore
    @State private var wallpapers: [URL] = []
    @StateObject private var wallpaperManagerService: WallpaperWindowManager
    @StateObject private var wallpaperShuffler: WallpaperShuffler
    @Environment(\.openWindow) private var openWindow
    
    private let wallpaperUrlProvider = WallpaperUrlProvider()
    
    init() {
        let loadedSettings = SettingsProvider.loadSettings()
            
        _settingsStore = State(initialValue: SettingsStore(settings: loadedSettings))
        _wallpapers = State(initialValue: wallpaperUrlProvider.retrieveMediaURLs(from: loadedSettings.wallpaperDirectory))
        
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
        Group {
            MainMenu(selectedWallpaper: $settingsStore.current.selectedWallpaper, wallpapers: wallpapers)
                .onOpenSettings {
                    openWindow(id: "settingsWindow")
                }
            
            Window("Settings", id: "settingsWindow") {
                SettingsView()
                    .frame(minWidth: 600, minHeight: 400)
            }
            .defaultPosition(.center)
            .windowStyle(.hiddenTitleBar)
        }
        .environment(settingsStore)
        .environment(wallpaperUrlProvider)
        .onChange(of: settingsStore.current) { _, newSettings in
            SettingsProvider.storeSettings(settings: newSettings)
        }
        .onChange(of: settingsStore.current.selectedWallpaper) { _, newVideoUrl in
            wallpaperManagerService.updateVideo(url: newVideoUrl)
        }
        .onChange(of: settingsStore.current.wallpaperDirectory) { _, newDirectory in
            wallpaperShuffler.updateWallpaperDirectory(newDirectory)
            wallpapers = wallpaperUrlProvider.retrieveMediaURLs(from: newDirectory)
        }
        .onChange(of: settingsStore.current.shuffleIntervalInMin) { _, newInterval in
            wallpaperShuffler.updateShuffleInterval(intervalInMin: newInterval)
        }
    }
}

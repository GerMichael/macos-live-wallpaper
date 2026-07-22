//
//  LiveWallpaperApp.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI

@main
struct LiveWallpaperApp: App {
    // Load settings once at the App level
    @State private var settings = SettingsProvider.loadSettings()
    @StateObject private var wallpaperManagerService: WallpaperWindowManager
    @StateObject private var wallpaperShuffler: WallpaperShuffler
    @Environment(\.openWindow) private var openWindow
    
    init() {
        let loadedSettings = SettingsProvider.loadSettings()
            
        _settings = State(initialValue: loadedSettings)
        
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
        MenuBarExtra("Live Wallpaper", systemImage: "photo.tv") {
            Button("Settings...") {
                openWindow(id: "settingsWindow")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            Button("Quit Live Wallpaper") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        
        Window("Settings", id: "settingsWindow") {
            SettingsView(settings: $settings)
                .frame(minWidth: 600, minHeight: 400)
                .onChange(of: settings.selectedWallpaper) { _, newVideoUrl in
                    wallpaperManagerService.updateVideo(url: newVideoUrl)
                }
                .onChange(of: settings.wallpaperDirectory) { _, newDirectory in
                    wallpaperShuffler.updateWallpaperDirectory(newDirectory)
                }
                .onChange(of: settings.shuffleIntervalInMin) { _, newInterval in
                    wallpaperShuffler.updateShuffleInterval(intervalInMin: newInterval)
                }
        }
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
    }
}

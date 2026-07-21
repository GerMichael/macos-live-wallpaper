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
    @State private var settings = SettingsService.loadSettings()
    @StateObject private var wallpaperManagerService: WallpaperManager
    @Environment(\.openWindow) private var openWindow
    
    init() {
            // Load settings immediately on app launch
            let loadedSettings = SettingsService.loadSettings()
            
            // Initialize state with the loaded settings
            _settings = State(initialValue: loadedSettings)
            
            // Feed the initial selected movie directly into the Wallpaper Manager
            _wallpaperManagerService = StateObject(wrappedValue: WallpaperManager(initialURL: loadedSettings.selectedMovie))
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
            // Pass the binding so changes reflect here
            SettingsView(settings: $settings)
                .frame(minWidth: 600, minHeight: 400)
                .onChange(of: settings.selectedMovie) { _, newVideoUrl in
                    wallpaperManagerService.updateVideo(url: newVideoUrl)
                }
        }
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
    }
}


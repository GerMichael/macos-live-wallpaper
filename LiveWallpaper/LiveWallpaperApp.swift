//
//  LiveWallpaperApp.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

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
            
        let store = SettingsStore(settings: loadedSettings)
        _settingsStore = State(initialValue: store)
        
        let urlProvider = WallpaperUrlProvider()
        _wallpapers = State(initialValue: urlProvider.retrieveMediaURLs(from: loadedSettings.wallpaperDirectory))
        
        let windowManager = WallpaperWindowManager()
        _wallpaperManagerService = StateObject(wrappedValue: windowManager)
        LiveWallpaperApp.updateUrl(url: loadedSettings.selectedWallpaper, windowManager: windowManager, settings: store.current)
        
        let shuffler = WallpaperShuffler(
            currentWallpaperUrl: loadedSettings.selectedWallpaper,
            wallpaperDirectory: loadedSettings.wallpaperDirectory,
            shuffleIntervalInMin: loadedSettings.shuffleIntervalInMin
        )
        
        shuffler.onWallpaperChanged = { [weak windowManager] url in
            guard let windowManager else {
                return
            }
            LiveWallpaperApp.updateUrl(url: url, windowManager: windowManager, settings: store.current)
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
            LiveWallpaperApp.updateUrl(url: newVideoUrl, windowManager: wallpaperManagerService, settings: settingsStore.current)
        }
        .onChange(of: settingsStore.current.wallpaperDirectory) { _, newDirectory in
            wallpaperShuffler.updateWallpaperDirectory(newDirectory)
            wallpapers = wallpaperUrlProvider.retrieveMediaURLs(from: newDirectory)
        }
        .onChange(of: settingsStore.current.shuffleIntervalInMin) { _, newInterval in
            wallpaperShuffler.updateShuffleInterval(intervalInMin: newInterval)
        }.onChange(of: settingsStore.current.autoFadeDurationInSec) { _, newDuration in
            LiveWallpaperApp.updateUrl(url: settingsStore.current.selectedWallpaper, windowManager: wallpaperManagerService, settings: settingsStore.current, restorePlaybackProgress: true)
        }
    }
    
    private static func updateUrl(url: URL?, windowManager: WallpaperWindowManager, settings: Settings, restorePlaybackProgress: Bool = false) {
        guard let url else {
            return
        }
        Task { @MainActor in
            do {
                let videoItem = try await VideoItem.getAVPlayerItem(for: url, videoCompositionConfig: VideoCompositon.Configuration(
                    crossFadeDuration: settings.autoFadeDurationInSec != nil ? Double(settings.autoFadeDurationInSec!) : nil
                ))
                windowManager.replaceVideoItem(videoItem: videoItem, restorePlaybackProgress: restorePlaybackProgress)
            } catch {
                print("Could not update wallpaper: \(error.localizedDescription)")
            }
        }
    }
}

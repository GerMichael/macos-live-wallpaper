//
//  WallpaperManagerService.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI
import Combine
import AppKit
import AVFoundation

class WallpaperManager: ObservableObject {
    private var windows: [NSWindow] = []
    private var videoPlayers: [LoopingVideoPlayer] = []
    private var currentURL: URL?
    private var cancellables = Set<AnyCancellable>()
    
    init(initialURL: URL?) {
        self.currentURL = initialURL
        setupWallpaperWindows()
        
        // Listen for when monitors are connected or disconnected
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.setupWallpaperWindows()
            }
            .store(in: &cancellables)
    }
    
    private func setupWallpaperWindows() {
        // 1. Clean up old players and windows
        videoPlayers.forEach { $0.stop() }
        videoPlayers.removeAll()
        
        windows.forEach { $0.close() }
        windows.removeAll()
        
        // 2. Create a background window for EVERY connected screen
        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            let desktopLevel = Int(CGWindowLevelForKey(.desktopIconWindow)) - 1
            window.level = NSWindow.Level(desktopLevel)
            window.collectionBehavior = [.stationary, .ignoresCycle, .canJoinAllSpaces]
            window.ignoresMouseEvents = true
            window.backgroundColor = .black
            
            let playerView = VideoWallpaperView(frame: screen.frame)
            window.contentView = playerView
            
            window.orderFrontRegardless()
            windows.append(window)
        }
        
        // 3. If we have a video selected, apply it to all the new windows
        if let url = currentURL {
            applyVideoToWindows(url: url)
        }
    }
    
    func updateVideo(url: URL?) {
        self.currentURL = url
        
        windows.forEach { ($0.contentView as? VideoWallpaperView)?.playerLayer.player = nil }
        
        videoPlayers.forEach { $0.stop() }
        videoPlayers.removeAll()
        
        guard let url = url else {
            return
        }
        
        applyVideoToWindows(url: url)
    }
    
    private func applyVideoToWindows(url: URL) {
        for window in windows {
            if let playerView = window.contentView as? VideoWallpaperView {
                let player = LoopingVideoPlayer(url: url)
                playerView.playerLayer.player = player.player
                player.play()
                videoPlayers.append(player) // Retain the player in our array so it doesn't deallocate
            }
        }
    }
}

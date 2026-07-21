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
        setupObservers()
        
        // Listen for when monitors are connected or disconnected
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.setupWallpaperWindows()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Visibility & Optimization Observers
    
    private func setupObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let defaultCenter = NotificationCenter.default
        
        // A. Screen Sleep / Wake
        workspaceCenter.publisher(for: NSWorkspace.screensDidSleepNotification)
            .sink { [weak self] _ in self?.pauseAll() }
            .store(in: &cancellables)
        
        workspaceCenter.publisher(for: NSWorkspace.screensDidWakeNotification)
            .sink { [weak self] _ in self?.evaluateAllVisibilities() }
            .store(in: &cancellables)
        
        // B. Space Changes (Switching between desktops)
        workspaceCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in self?.evaluateAllVisibilities() }
            .store(in: &cancellables)
        
        // C. Window Occlusion (Covered by fullscreen apps or opaque windows)
        defaultCenter.publisher(for: NSWindow.didChangeOcclusionStateNotification)
            .sink { [weak self] notification in
                guard let self = self,
                      let window = notification.object as? NSWindow,
                      let index = self.windows.firstIndex(of: window),
                      index < self.videoPlayers.count else { return }
                
                self.evaluateVisibility(for: window, player: self.videoPlayers[index])
            }
            .store(in: &cancellables)
    }
    
    private func pauseAll() {
        videoPlayers.forEach { $0.pause() }
    }
    
    private func evaluateAllVisibilities() {
        for (index, window) in windows.enumerated() {
            guard index < videoPlayers.count else { continue }
            evaluateVisibility(for: window, player: videoPlayers[index])
        }
    }
    
    private func evaluateVisibility(for window: NSWindow, player: LoopingVideoPlayer) {
        if window.occlusionState.contains(.visible) {
            player.play()
        } else {
            player.pause()
        }
    }
    
    // MARK: - Window Management
    
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
            
            // Prevents macOS from animating during sleep/lock
            window.animationBehavior = .none
            window.isReleasedWhenClosed = false
            
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
                
                // Evaluate initial visibility instead of unconditionally calling play()
                evaluateVisibility(for: window, player: player)
                
                videoPlayers.append(player) // Retain the player in our array so it doesn't deallocate
            }
        }
    }
}

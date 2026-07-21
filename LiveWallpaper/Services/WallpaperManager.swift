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
    
    // Use a single player instead of an array
    private var videoPlayer: LoopingVideoPlayer?
    
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
            .sink { [weak self] _ in self?.videoPlayer?.pause() }
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
            .sink { [weak self] _ in
                // If any window's occlusion changes, re-evaluate global visibility
                self?.evaluateAllVisibilities()
            }
            .store(in: &cancellables)
    }
    
    private func evaluateAllVisibilities() {
        guard let player = videoPlayer else { return }
        
        // Check if the wallpaper is visible on AT LEAST ONE screen
        let isVisibleOnAnyScreen = windows.contains { window in
            window.occlusionState.contains(.visible)
        }
        
        if isVisibleOnAnyScreen {
            player.play()
        } else {
            player.pause()
        }
    }
    
    // MARK: - Window Management
    
    private func setupWallpaperWindows() {
        // 1. Clean up old player and windows
        videoPlayer?.stop()
        videoPlayer = nil
        
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
            
            window.isReleasedWhenClosed = false
            window.animationBehavior = .none
            
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
        
        videoPlayer?.stop()
        videoPlayer = nil
        
        guard let url = url else { return }
        
        applyVideoToWindows(url: url)
    }
    
    private func applyVideoToWindows(url: URL) {
        // 1. Instantiate the player exactly ONCE
        let player = LoopingVideoPlayer(url: url)
        self.videoPlayer = player
        
        // 2. Attach this single player to ALL windows
        for window in windows {
            if let playerView = window.contentView as? VideoWallpaperView {
                playerView.playerLayer.player = player.player
            }
        }
        
        // 3. Evaluate visibility to decide if it should start playing
        evaluateAllVisibilities()
    }
}

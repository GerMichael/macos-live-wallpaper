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

class WallpaperManagerService: ObservableObject {
    private var window: NSWindow?
    private var videoPlayer: LoopingVideoPlayer?
    
    init() {
        setupWallpaperWindow()
    }
    
    private func setupWallpaperWindow() {
        guard let screen = NSScreen.main else { return }
        
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
        window.backgroundColor = .clear
        
        let playerView = VideoWallpaperView(frame: screen.frame)
        window.contentView = playerView
        
        self.window = window
        
        // Use orderFrontRegardless() instead of makeKeyAndOrderFront()
        // because background windows shouldn't try to become key.
        window.orderFrontRegardless()
    }
    
    func updateVideo(url: URL?) {
        guard let playerView = window?.contentView as? VideoWallpaperView else { return }
        
        // Stop current video if one is playing
        videoPlayer?.stop()
        videoPlayer = nil
        playerView.playerLayer.player = nil
        
        // If a new URL is provided, start playing
        if let url = url {
            videoPlayer = LoopingVideoPlayer(url: url)
            playerView.playerLayer.player = videoPlayer?.player
            videoPlayer?.play()
        }
    }
}

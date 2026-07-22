//
//  WallpaperShuffler.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 22.07.26.
//

import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class WallpaperShuffler: ObservableObject {
    private var timer: Timer?
    private var wallpaperDirectory: URL?
    private var currentWallpaperUrl: URL?
    
    var onWallpaperChanged: ((URL) -> Void)?
    
    init(currentWallpaperUrl: URL?, wallpaperDirectory: URL?, shuffleIntervalInMin: Int?) {
        self.currentWallpaperUrl = currentWallpaperUrl
        self.wallpaperDirectory = wallpaperDirectory
        
        if let interval = shuffleIntervalInMin, interval > 0 {
            let shuffleIntervalInSec = TimeInterval(interval * 60)
            startNewTimer(timeInterval: shuffleIntervalInSec)
        }
    }
    
    func updateWallpaperDirectory(_ directory: URL?) {
        self.wallpaperDirectory = directory
    }
    
    func updateShuffleInterval(intervalInMin: Int?) {
        if let intervalInMin, intervalInMin > 0 {
            startNewTimer(timeInterval: TimeInterval(intervalInMin * 60))
        } else {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    private func startNewTimer(timeInterval: TimeInterval) {
        self.timer?.invalidate()
        print("Started new timer with interval \(timeInterval) seconds")
        self.timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateWallpaper()
            }
        }
    }
    
    private func updateWallpaper() {
        print("Try setting new random wallpaper")
        guard let directory = wallpaperDirectory else { return }
                
        let hasAccess = directory.startAccessingSecurityScopedResource()
        if !hasAccess { return }
        defer { directory.stopAccessingSecurityScopedResource() }
        
        do {
            let movieFiles = try getDirectoryItems(from: directory, conformsToContentType: .audiovisualContent)
            guard !movieFiles.isEmpty else { return }
            
            // Filter out the current wallpaper to ensure a new one is picked if possible
            let availableFiles = movieFiles.filter { $0 != currentWallpaperUrl }
            
            if let newWallpaper = availableFiles.randomElement() ?? movieFiles.randomElement() {
                self.currentWallpaperUrl = newWallpaper
                self.onWallpaperChanged?(newWallpaper)
            }
        } catch {
            print("Failed to read directory: \(error.localizedDescription)")
        }
    }
}

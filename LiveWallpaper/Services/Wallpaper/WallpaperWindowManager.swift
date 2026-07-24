//
//  WallpaperWindowManager.swift
//  LiveWallpaper
//

import SwiftUI
import Combine
import AppKit
import AVFoundation

final class WallpaperWindowManager: ObservableObject {

    private var windows: [NSWindow] = []

    private let playbackController = VideoPlaybackController()

    private var currentItem: AVPlayerItem? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Build windows first
        setupWallpaperWindows()
        setupObservers()

        NotificationCenter.default.publisher(
            for: NSApplication.didChangeScreenParametersNotification
        )
        .sink { [weak self] _ in
            self?.setupWallpaperWindows()
        }
        .store(in: &cancellables)
    }

    // MARK: - Observers

    private func setupObservers() {

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let defaultCenter = NotificationCenter.default

        workspaceCenter.publisher(for: NSWorkspace.screensDidSleepNotification)
            .sink { [weak self] _ in
                self?.playbackController.pause()
            }
            .store(in: &cancellables)

        workspaceCenter.publisher(for: NSWorkspace.screensDidWakeNotification)
            .sink { [weak self] _ in
                self?.evaluateAllVisibilities()
            }
            .store(in: &cancellables)

        workspaceCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.evaluateAllVisibilities()
            }
            .store(in: &cancellables)

        defaultCenter.publisher(for: NSWindow.didChangeOcclusionStateNotification)
            .sink { [weak self] _ in
                self?.evaluateAllVisibilities()
            }
            .store(in: &cancellables)
    }

    // MARK: - Visibility

    private func evaluateAllVisibilities() {

        guard playbackController.player != nil else {
            return
        }

        let visible = windows.contains {
            $0.occlusionState.contains(.visible)
        }

        if visible {
            playbackController.play()
        } else {
            playbackController.pause()
        }
    }

    // MARK: - Window Management

    private func setupWallpaperWindows() {

        // Destroy old windows ONLY.
        windows.forEach { $0.close() }
        windows.removeAll()

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
            window.collectionBehavior = [
                .stationary,
                .ignoresCycle,
                .canJoinAllSpaces
            ]

            window.ignoresMouseEvents = true
            
            updateWindowAppearance(window)

            let playerView = VideoWallpaperView(frame: screen.frame)
            window.contentView = playerView

            window.orderFrontRegardless()

            windows.append(window)
        }

        attachPlayerToWindows()

        evaluateAllVisibilities()
    }

    private func updateWindowAppearance(_ window: NSWindow) {
        let isReachable = currentItem != nil

        if isReachable {
            window.isOpaque = true
            window.backgroundColor = .black
        } else {
            window.isOpaque = false
            window.backgroundColor = .clear
        }
    }

    // MARK: - Video Application Helper

    @MainActor
    private func applyVideoUpdate(videoItem: AVPlayerItem?, restorePlaybackProgress: Bool) async {
        guard let videoItem else {
            return
        }
        if restorePlaybackProgress {
            await playbackController.hotUpdateVideo(playerItem: videoItem)
        } else {
            await playbackController.replaceVideo(playerItem: videoItem)
        }

        for window in windows {
            updateWindowAppearance(window)
        }

        attachPlayerToWindows()
        evaluateAllVisibilities()
    }

    // MARK: - Public API

    func replaceVideoItem(videoItem: AVPlayerItem?, restorePlaybackProgress: Bool = false) {
        currentItem = videoItem

        if restorePlaybackProgress {
            return replaceVideoItemButKeepPlaybackProgress(videoItem: videoItem)
        } else {
            return replaceVideoItemSmoothly(videoItem: videoItem)
        }
    }
    
    func replaceVideoItemButKeepPlaybackProgress(videoItem: AVPlayerItem?) {
        detachPlayerFromWindows()
        Task { @MainActor in
            await applyVideoUpdate(videoItem: videoItem, restorePlaybackProgress: true)
            for window in windows {
                window.contentView?.alphaValue = 1.0
            }
        }
    }
    
    func replaceVideoItemSmoothly(videoItem: AVPlayerItem?) {
        // Ensure window background is black so fading the content view reveals black
        for window in windows {
            window.backgroundColor = .black
        }

        // Quickly fade out the video view to black
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            for window in windows {
                window.contentView?.animator().alphaValue = 0.0
            }
        }, completionHandler: { [weak self] in
            guard let self = self else { return }

            // Detach active player from layers first so hardware decode surfaces are freed immediately
            self.detachPlayerFromWindows()

            Task { @MainActor in
                await self.applyVideoUpdate(videoItem: videoItem, restorePlaybackProgress: false)

                // Quickly fade the new video view back in from black
                await NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.15
                    for window in self.windows {
                        window.contentView?.animator().alphaValue = 1.0
                    }
                }
            }
        })
    }

    // MARK: - Helpers

    private func detachPlayerFromWindows() {
        for window in windows {
            if let playerView = window.contentView as? VideoWallpaperView {
                playerView.setPlayer(nil)
            }
        }
    }

    private func attachPlayerToWindows() {

        guard let player = playbackController.player else {
            detachPlayerFromWindows()
            return
        }

        for window in windows {

            guard let playerView = window.contentView as? VideoWallpaperView else {
                continue
            }
            
            playerView.setPlayer(player)
        }
    }
}

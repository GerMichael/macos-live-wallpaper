//
//  LoopingVideoPlayer.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import AVKit
import Foundation


class VideoLoopPlayer {
    let player = AVQueuePlayer()
    var looper: AVPlayerLooper?
    
    // Store the URL so we can recover the video if the player fails during sleep
    private let videoURL: URL

    init(url: URL) {
        self.videoURL = url
        setupPlayer()
    }
    
    private func setupPlayer() {
        player.isMuted = true
        let item = AVPlayerItem(url: videoURL)
        looper = AVPlayerLooper(
            player: player,
            templateItem: item
        )
    }

    func play() {
        // 1. Check if the media services died during a deep sleep
        if player.status == .failed || player.currentItem?.status == .failed {
            stop()
            setupPlayer()
        }
        
        // 2. Force the hardware decoder to render a new frame.
        // This clears the "black screen" by forcing a pipeline refresh.
        let currentTime = player.currentTime()
        player.seek(to: currentTime, toleranceBefore: .zero, toleranceAfter: .zero)
        
        player.play()
    }
    
    func pause() {
        player.pause()
    }

    func stop() {
        // 1. Disable the looper first so it stops trying to clone items
        looper?.disableLooping()
        looper = nil
        
        // 2. Pause and completely flush the queue
        player.pause()
        player.removeAllItems()
        
        // 3. Force the player to drop any currently held item
        player.replaceCurrentItem(with: nil)
    }
}

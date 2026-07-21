//
//  LoopingVideoPlayer.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import AVKit
import Foundation


class LoopingVideoPlayer {
    let player = AVQueuePlayer()
    var looper: AVPlayerLooper?

    init(url: URL) {
        player.isMuted = true
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(
            player: player,
            templateItem: item
        )
    }

    func play() {
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

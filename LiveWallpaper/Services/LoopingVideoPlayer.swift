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

    func stop() {
        player.pause()
        player.removeAllItems()
    }
}

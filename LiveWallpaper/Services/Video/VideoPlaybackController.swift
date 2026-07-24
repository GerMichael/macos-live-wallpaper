//
//  VideoPlaybackController.swift
//  LiveWallpaper
//

import Foundation
import AVFoundation

final class VideoPlaybackController {

    private var loopingPlayer: VideoLoopPlayer?

    var player: AVQueuePlayer? {
        loopingPlayer?.player
    }

    func updateVideo(playerItem: AVPlayerItem) async {
        stop()
        loopingPlayer = VideoLoopPlayer(item: playerItem)
    }

    func play() {
        loopingPlayer?.play()
    }

    func pause() {
        loopingPlayer?.pause()
    }

    func stop() {
        loopingPlayer?.stop()
        loopingPlayer = nil
    }
}

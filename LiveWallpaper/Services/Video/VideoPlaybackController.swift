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

    func updateVideo(url: URL?) {

        stop()

        guard let url else {
            return
        }

        loopingPlayer = VideoLoopPlayer(url: url)
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

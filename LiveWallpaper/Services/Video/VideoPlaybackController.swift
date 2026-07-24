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

    func replaceVideo(playerItem: AVPlayerItem) async {
        stop()
        loopingPlayer = VideoLoopPlayer(item: playerItem)
    }
    
    func hotUpdateVideo(playerItem: AVPlayerItem) async {
        pause()
        let currentPlaybackTime = loopingPlayer?.player.currentTime()
        stop()
        loopingPlayer = VideoLoopPlayer(item: playerItem)
        if let currentPlaybackTime {
            await loopingPlayer?.player.seek(to: currentPlaybackTime)
        }
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

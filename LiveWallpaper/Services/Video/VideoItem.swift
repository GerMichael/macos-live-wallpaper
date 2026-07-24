//
//  VideoItem.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 24.07.26.
//

import Foundation
import AVFoundation

class VideoItem {
    static func getAVPlayerItem(for url: URL, videoCompositionConfig: VideoCompositon.Configuration?) async throws -> AVPlayerItem {
        // Start accessing security-scoped resource if applicable.
        // Note: Do NOT call stopAccessingSecurityScopedResource() in a defer block here,
        // as AVPlayer needs file access while reading and playing the media.
        _ = url.startAccessingSecurityScopedResource()
        
        let aVURLAsset = AVURLAsset(url: url)
        
        if let videoCompositionConfig {
            let compositionResult = try await VideoCompositon.compose(for: aVURLAsset, options: videoCompositionConfig)
            let playerItem = AVPlayerItem(asset: compositionResult.composition)
            playerItem.videoComposition = compositionResult.videoComposition
            return playerItem
        }
        
        return AVPlayerItem(asset: aVURLAsset)
    }
}

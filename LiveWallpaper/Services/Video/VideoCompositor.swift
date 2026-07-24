//
//  VideoCompositor.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 24.07.26.
//

import Foundation
import AVFoundation

enum VideoCompositorError: Error {
    case noVideoTrack
    case cannotAddTrack
}

class VideoCompositor {
    
    struct Configuration {
        var blurRadius: Double?
        var crossFadeDuration: Double?
    }

    struct Result {
        let composition: AVComposition
        let videoComposition: AVVideoComposition
    }
        
    static func compose(for videoAsset: AVAsset, options compositionOptions: Configuration) async throws -> Result {
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first else {
            throw VideoCompositorError.noVideoTrack
        }
        
        let totalDuration = try await videoAsset.load(.duration)
        let preferredTimeScale = try await videoTrack.load(.naturalTimeScale)
                
        let composition = AVMutableComposition()
        
        var instructions: [AVVideoCompositionInstruction] = []
        
        if let crossFadeDuration = compositionOptions.crossFadeDuration, crossFadeDuration > 0 {
            instructions = try addCrossFadeTracksAndGetInstructions(
                crossFadeDuration: crossFadeDuration,
                totalDuration: totalDuration,
                preferredTimeScale: preferredTimeScale,
                composition: composition,
                videoTrack: videoTrack
            )
        } else {
            instructions = try addMainTrackAndGetNopInstructions(
                totalDuration: totalDuration,
                composition: composition,
                videoTrack: videoTrack
            )
        }
        
        let videoComposition = AVVideoComposition(
            configuration: AVVideoComposition.Configuration(
                frameDuration: CMTime(value: 1, timescale: 30),
                instructions: instructions,
                renderSize: try await videoTrack.load(.naturalSize)
            )
        )
        
        return Result(composition: composition, videoComposition: videoComposition)
    }
    
    /**
        Applys tracks for the cross fading effect and returns corresponding instructions.
        When the resulting tracks are played in a loop, the end of the result fades with its own next beginning.
        - Parameter crossFadeDuration: the duration of the cross fade
        - Parameter totalDuration: the total duration of the video
        - Parameter preferredTimeScale: the time scale of the effect
        - Parameter composition: the `AVMutableComposition` to add the required mutated tracks to
        - Parameter videoTrack: the original video track that the cross fade effect is based on.
        
        Consider a video of a sequence of frames ABCDEFG, with A...G being a frame, and a cross fade duration of x=2 frames.
        This method overlays the last x=2 frames of the end of the video onto the beginning of the video so that the new video consists of those two stacked tracks.
        The sub-track FG has a decreasing opacity from 1 to 0.
        ```
        input  = video: ABCDEFG, duration: 2
        result = overlayedTrack: FG
                 mainTrack:      ABCDE
        ```
     */
    private static func addCrossFadeTracksAndGetInstructions(
        crossFadeDuration: Double,
        totalDuration: CMTime,
        preferredTimeScale: CMTimeScale,
        composition: AVMutableComposition,
        videoTrack: AVAssetTrack
    ) throws -> [AVVideoCompositionInstruction] {
        var instructions: [AVVideoCompositionInstruction] = []
        let crossFadeTime = CMTime(seconds: min(crossFadeDuration, totalDuration.seconds - 0.1), preferredTimescale: preferredTimeScale)
        
        let trimmedDuration = totalDuration - crossFadeTime
        
        guard let trackMain = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let trackOverlayed = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoCompositorError.cannotAddTrack
        }
        
        // 1. Insert trimmed main body [0, totalDuration - crossFadeDuration]
        try trackMain.insertTimeRange(
            CMTimeRange(start: .zero, duration: trimmedDuration),
            of: videoTrack,
            at: .zero
        )
        
        // 2. Insert trailing end segment [totalDuration - crossFadeDuration, totalDuration]
        let endSegmentRange = CMTimeRange(start: trimmedDuration, duration: crossFadeTime)
        try trackOverlayed.insertTimeRange(
            endSegmentRange,
            of: videoTrack,
            at: .zero
        )
        
        // 3. Instruction for the cross-fade region [0, crossFadeDuration]
        let crossFadeInstruction = getInstructionForCrossFadeDuration(
            mainTrack: trackMain,
            overlayTrack: trackOverlayed,
            crossFadeDuration: crossFadeTime
        )
        instructions.append(crossFadeInstruction)
        
        // 4. Instruction for the remainder of the trimmed video [crossFadeDuration, trimmedDuration]
        let mainInstruction = getInstructionForAfterCrossFade(
            mainTrack: trackMain,
            duration: trimmedDuration,
            crossFadeDuration: crossFadeTime
        )
        instructions.append(mainInstruction)
        return instructions
    }
    
    private static func addMainTrackAndGetNopInstructions(
        totalDuration: CMTime,
        composition: AVMutableComposition,
        videoTrack: AVAssetTrack
    ) throws -> [AVVideoCompositionInstruction] {
        guard let trackMain = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoCompositorError.cannotAddTrack
        }
        
        try trackMain.insertTimeRange(
            CMTimeRange(start: .zero, duration: totalDuration),
            of: videoTrack,
            at: .zero
        )
        
        let mainInstruction = getInstructionForAfterCrossFade(
            mainTrack: trackMain,
            duration: totalDuration
        )
        return [mainInstruction]
    }
    
    private static func getInstructionForCrossFadeDuration(mainTrack: AVMutableCompositionTrack, overlayTrack: AVMutableCompositionTrack, crossFadeDuration: CMTime) -> AVVideoCompositionInstruction {
        var configForLayerOverlayed = AVVideoCompositionLayerInstruction.Configuration(assetTrack: overlayTrack)
        configForLayerOverlayed.addOpacityRamp(
            AVVideoCompositionLayerInstruction.OpacityRamp(timeRange: CMTimeRange(start: .zero, duration: crossFadeDuration), start: 1.0, end: 0.0)
        )
        let layerOverlayed = AVVideoCompositionLayerInstruction(configuration: configForLayerOverlayed)
        let layerMain = AVVideoCompositionLayerInstruction(
            configuration: AVVideoCompositionLayerInstruction.Configuration(assetTrack: mainTrack)
        )
        
        let instruction = AVVideoCompositionInstruction(
            configuration: AVVideoCompositionInstruction.Configuration(
                layerInstructions: [layerOverlayed, layerMain],
                timeRange: .init(start: .zero, duration: crossFadeDuration)
            )
        )
        
        return instruction
    }
    
    private static func getInstructionForAfterCrossFade(mainTrack: AVMutableCompositionTrack, duration: CMTime, crossFadeDuration: CMTime = .zero) -> AVVideoCompositionInstruction {
        let remainingTimeRange = CMTimeRange(start: crossFadeDuration, duration: duration - crossFadeDuration)
        
        var configForLayerMain = AVVideoCompositionLayerInstruction.Configuration(assetTrack: mainTrack)
        configForLayerMain.setOpacity(1, at: crossFadeDuration)
        let layerMain = AVVideoCompositionLayerInstruction(configuration: configForLayerMain)
        
        let instruction = AVVideoCompositionInstruction(
            configuration: AVVideoCompositionInstruction.Configuration(
                layerInstructions: [layerMain],
                timeRange: remainingTimeRange
            )
        )
        
        return instruction
    }
}

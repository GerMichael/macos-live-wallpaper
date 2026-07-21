//
//  VideoPreview.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import AVKit
import SwiftUI

struct VideoPreviewView: NSViewRepresentable {
    let url: URL

    class Coordinator {
        var controller: LoopingVideoPlayer?
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.videoGravity = .resizeAspectFill
        
        // Create and retain the player in the coordinator
        let controller = LoopingVideoPlayer(url: url)
        context.coordinator.controller = controller

        view.player = controller.player
        controller.play()

        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
}

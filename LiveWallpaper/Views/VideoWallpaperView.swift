//
//  PlayerView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI
import AppKit
import AVFoundation

class VideoWallpaperView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        let playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = .resizeAspectFill // Fills the whole screen
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        self.layer = playerLayer
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
}

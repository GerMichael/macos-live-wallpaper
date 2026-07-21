//
//  VideoThumbnailView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnail: NSImage?

    var body: some View {
        GeometryReader { geo in
            if let image = thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .overlay(ProgressView().scaleEffect(0.5))
            }
        }
        // Using .task(id: url) ensures that if the view is reused in the grid,
        // it cancels the old thumbnail generation and starts the new one.
        .task(id: url) {
            await generateThumbnail()
        }
    }

    private func generateThumbnail() async {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        // Downsample the image heavily to save memory! We only need a tiny grid thumbnail.
        generator.maximumSize = CGSize(width: 300, height: 300)
        
        do {
            // Try to grab a frame 0.5 seconds in (so it's not just a black fade-in frame)
            let time = CMTime(seconds: 0.5, preferredTimescale: 600)
            let (cgImage, _) = try await generator.image(at: time)
            
            await MainActor.run {
                self.thumbnail = NSImage(cgImage: cgImage, size: .zero)
            }
        } catch {
            // If it fails (e.g., video is shorter than 0.5s), fallback to the very first frame
            if let (cgImage, _) = try? await generator.image(at: .zero) {
                await MainActor.run {
                    self.thumbnail = NSImage(cgImage: cgImage, size: .zero)
                }
            }
        }
    }
}

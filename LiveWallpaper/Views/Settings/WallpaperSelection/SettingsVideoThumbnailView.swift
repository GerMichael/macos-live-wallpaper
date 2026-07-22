//
//  SettingsVideoThumbnailView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI
import AVFoundation

struct SettingsVideoThumbnailView: View {
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
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        // Downsample the image heavily to save memory
        generator.maximumSize = CGSize(width: 300, height: 300)
        
        // Allow decoding the nearest keyframe (I-frame) directly.
        // This avoids decoding preceding frame sequences and prevents decoder saturation.
        generator.requestedTimeToleranceBefore = .positiveInfinity
        generator.requestedTimeToleranceAfter = .positiveInfinity
        
        do {
            let time = CMTime(seconds: 0.5, preferredTimescale: 600)
            let (cgImage, _) = try await generator.image(at: time)
            
            await MainActor.run {
                self.thumbnail = NSImage(cgImage: cgImage, size: .zero)
            }
        } catch {
            if let (cgImage, _) = try? await generator.image(at: .zero) {
                await MainActor.run {
                    self.thumbnail = NSImage(cgImage: cgImage, size: .zero)
                }
            }
        }
    }
}

#Preview {
    let url = Bundle.main.url(forResource: "example_video", withExtension: ".mp4")
    SettingsVideoThumbnailView(url: url!)
}

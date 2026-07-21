//
//  MovieGridItemView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI

struct MovieGridItemView: View {
    let movieURL: URL
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack {
            VideoThumbnailView(url: movieURL)
                .frame(height: 80)
                .cornerRadius(6)
                .clipped()
            
            Text(movieURL.lastPathComponent)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .truncationMode(.middle)
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

#Preview {
    MovieGridItemView(
        movieURL: Bundle.main.url(forResource: "example_video", withExtension: ".mp4")!,
        isSelected: false,
        onSelect: {}
    )
}

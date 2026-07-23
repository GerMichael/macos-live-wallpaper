//
//  MainMenu.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 23.07.26.
//

import SwiftUI

struct MainMenu: Scene {
    var onOpenSettings: (() -> Void)? = nil
    @Binding var selectedWallpaper: URL?
    let wallpapers: [URL]
    
    let columns = [GridItem(.adaptive(minimum: 120, maximum: 140), spacing: 12)]
    
    var body: some Scene {
        MenuBarExtra("Live Wallpaper", systemImage: "photo.tv") {
            VStack(alignment: .leading, spacing: 12) {
                Button("Settings...") {
                    onOpenSettings?()
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Divider()
                
                if !wallpapers.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(wallpapers, id: \.self) { movieURL in
                                SettingsWallpaperPreviewItemView(
                                    movieURL: movieURL,
                                    isSelected: selectedWallpaper == movieURL,
                                    onSelect: { selectedWallpaper = movieURL }
                                )
                                .frame(width: 130, height: 110)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(width: 300, height: 240)
                    
                    Divider()
                }
                
                Button("Quit Live Wallpaper") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(12)
            .frame(width: 320)
        }
        .menuBarExtraStyle(.window)
    }
    
    func onOpenSettings(_ action: @escaping () -> Void) -> MainMenu {
        var copy = self
        copy.onOpenSettings = action
        return copy
    }
}

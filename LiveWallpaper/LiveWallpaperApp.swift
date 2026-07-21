//
//  LiveWallpaperApp.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI

@main
struct LiveWallpaperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().windowResizeBehavior(.disabled)
        }.windowResizability(.contentSize)
    }
}

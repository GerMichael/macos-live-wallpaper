//
//  SettingsStore.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 24.07.26.
//

import Foundation

@Observable
final class SettingsStore {
    var current: Settings
    
    init(settings: Settings) {
        self.current = settings
    }
}

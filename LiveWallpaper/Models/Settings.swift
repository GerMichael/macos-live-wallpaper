//
//  Settings.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import Foundation

struct Settings: Equatable {
    var wallpaperDirectory: URL?
    var selectedWallpaper: URL?
    var autoFadeDurationInSec: Int?
    var shuffleIntervalInMin: Int?
}

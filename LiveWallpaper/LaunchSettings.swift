//
//  LaunchSettings.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import Combine
import SwiftUI
import ServiceManagement

@MainActor
class LaunchSettings: ObservableObject {
    @Published var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled {
        didSet {
            toggleLaunchAtLogin(enabled: launchAtLogin)
        }
    }
    
    private func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("Failed to toggle launch at login: \(error.localizedDescription)")
            // Revert the toggle in the UI if the system operation failed
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}


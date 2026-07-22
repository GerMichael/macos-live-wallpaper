//
//  AppConfigView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI


enum SettingsMenu: String, CaseIterable, Identifiable {
    case general = "General"
    case movieSelection = "Wallpapers"
    
    var id: Self { self }
}

struct SettingsView: View {
    @State private var selectedMenu: Optional<SettingsMenu> = .general
    @Binding var settings: Settings
    
    // Add the launch settings object
    @StateObject private var launchSettings = LaunchSettings()
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMenu) {
                ForEach(SettingsMenu.allCases) { menu in
                    Text(menu.rawValue).tag(menu)
                }
            }
        } detail: {
            NavigationStack {
                VStack(alignment: .leading, spacing: 20) {
                    if let selectedMenu {
                        switch selectedMenu {
                            case .general:
                                GeneralSettingsView(
                                    launchAtLogin: $launchSettings.launchAtLogin,
                                    autoFadeDurationInSec: $settings.autoFadeDurationInSec,
                                    shuffleIntervalInMin: $settings.shuffleIntervalInMin
                                )
                            case .movieSelection:
                                SettingsWallpaperSelectionView(
                                    selectedMovieDirectoryURL: $settings.wallpaperDirectory,
                                    selectedMovieURL: $settings.selectedWallpaper
                                )
                            }
                    }
                    
                    Spacer() // Pushes content to the top
                }
                .padding()
            }
        }
        .navigationTitle(selectedMenu?.rawValue ?? "Settings")
        .onChange(of: settings) { _, newSettings in
            SettingsProvider.storeSettings(settings: newSettings)
        }
    }
}

#Preview {
    @Previewable @State var settingsAllSelected = Settings(
        wallpaperDirectory: Bundle.main.resourceURL,
        selectedWallpaper: Bundle.main.url(forResource: "example_video", withExtension: ".mp4")
    )
    SettingsView(
        settings: $settingsAllSelected
    )
    
}

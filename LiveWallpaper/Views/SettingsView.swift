//
//  AppConfigView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI


enum SettingsMenu: String, CaseIterable, Identifiable {
    case general = "General"
    case movieSelection = "Movie Selection"
    
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
                                GeneralSettingsView(launchAtLogin: $launchSettings.launchAtLogin)
                            case .movieSelection:
                                MovieSelectionSettingsView(
                                    selectedMovieDirectoryURL: $settings.moviesDirectory,
                                    selectedMovieURL: $settings.selectedMovie
                                ).onChange(of: settings.moviesDirectory) { _, newValue in
                                    print("Selected URL: \(newValue?.absoluteString ?? "nil")")
                                    SettingsService.storeSettings(settings: settings)
                                }.onChange(of: settings.selectedMovie) { _, newValue in
                                    print("Selected URL: \(newValue?.absoluteString ?? "nil")")
                                    SettingsService.storeSettings(settings: settings)
                                }
                            }
                    }
                    
                    Spacer() // Pushes content to the top
                }
                .padding()
            }
        }
        .navigationTitle(selectedMenu?.rawValue ?? "Settings")
    }
}

#Preview {
    @Previewable @State var settings = Settings(
        moviesDirectory: URL(fileURLWithPath: "/dev/null"),
        selectedMovie: Bundle.main.url(forResource: "example_video", withExtension: ".mp4")
    )
    SettingsView(
        settings: $settings
    )
}

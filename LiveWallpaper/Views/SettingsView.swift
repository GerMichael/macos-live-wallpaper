//
//  AppConfigView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI


enum SettingsMenu: String, CaseIterable, Identifiable {
    case movieSelection = "Movie Selection"
    
    var id: Self { self }
}

struct SettingsView : View {
    @State private var selectedMenu: Optional<SettingsMenu> = .movieSelection
    @Binding var settings: Settings
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMenu) {
                ForEach(SettingsMenu.allCases) { menu in
                    Text(menu.rawValue).tag(menu)
                }
            }
        } detail: {
            VStack{
                if let selectedMenu {
                    switch selectedMenu {
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
            }.padding()
        }
    }
}

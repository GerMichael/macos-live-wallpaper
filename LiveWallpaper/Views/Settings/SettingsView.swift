//
//  AppConfigView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI


enum SettingsMenu: String, CaseIterable, Identifiable {
    case general = "General"
    case movieSelection = "Select Wallpaper"
    
    var id: Self { self }
}

struct SettingsView: View {
    @State private var selectedMenu: Optional<SettingsMenu> = .general
    @Environment(SettingsStore.self) var settingsStore
    
    var body: some View {
        @Bindable var settingsStore = settingsStore
        
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
                                GeneralSettingsView()
                            case .movieSelection:
                                SettingsWallpaperSelectionView()
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
    @Previewable @State var settingsAllSelected = Settings(
        wallpaperDirectory: Bundle.main.resourceURL,
        selectedWallpaper: Bundle.main.url(forResource: "example_video", withExtension: ".mp4")
    )
    SettingsView().environment(SettingsStore(settings: settingsAllSelected))
    
}

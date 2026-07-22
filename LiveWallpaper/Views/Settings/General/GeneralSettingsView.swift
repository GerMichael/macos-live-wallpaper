//
//  GeneralSettingsView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI

struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    
    var body: some View {
        Form {
            Section {
                VStack {
                    Toggle("Start Live Wallpaper at Login", isOn: $launchAtLogin)
                        .padding(.bottom, 10)
                }
            } header: {
                Text("Startup")
            }
        }.formStyle(.grouped)
    }
}

#Preview {
    @Previewable @StateObject var launchSettings = LaunchSettings()
    GeneralSettingsView(launchAtLogin : $launchSettings.launchAtLogin)
}

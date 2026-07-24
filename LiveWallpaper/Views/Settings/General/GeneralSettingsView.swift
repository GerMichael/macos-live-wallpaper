//
//  GeneralSettingsView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI

struct GeneralSettingsView: View {
    @Environment(SettingsStore.self) var settingsStore
    @StateObject private var launchSettings = LaunchSettings()
    
    private let maxCrossFade: Double = 5.0
    
    private let shuffleIntervalDefaults: [Int: String] = [
        0: "Disabled",
        1: "Every Minute",
        5: "Every 5 Minutes",
        30: "Every 30 Minutes",
        60: "Every Hour",
        24 * 60: "Daily",
    ]
    
    private var fadeDurationBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(settingsStore.current.autoFadeDurationInSec ?? 0) },
            set: { settingsStore.current.autoFadeDurationInSec = Int($0) }
        )
    }
    
    var body: some View {
        @Bindable var settingsStore = settingsStore
        Form {
            Section {
                VStack {
                    Toggle("Start Live Wallpaper at Login", isOn: $launchSettings.launchAtLogin)
                        .padding(.bottom, 10)
                }
            } header: {
                Text("Startup")
            }
            Section {
                VStack {
                    Slider(value: fadeDurationBinding, in: 0...maxCrossFade) {
                        Text("Cross Fade On Loop: " +
                             ((settingsStore.current.autoFadeDurationInSec ?? 0) > 0 ? "\(settingsStore.current.autoFadeDurationInSec!) Seconds" : "Off")
                        )
                    } minimumValueLabel: {
                        Text("Off")
                    } maximumValueLabel: {
                        Text(String(format: "%.0f Sec", maxCrossFade))
                    }
                    Divider()
                    Picker(selection: $settingsStore.current.shuffleIntervalInMin) {
                        ForEach(shuffleIntervalDefaults.keys.sorted(), id: \.self) { interval in
                            Text(shuffleIntervalDefaults[interval] ?? "").tag(interval)
                        }
                        if (settingsStore.current.shuffleIntervalInMin != nil && shuffleIntervalDefaults[settingsStore.current.shuffleIntervalInMin!] == nil) {
                            Text("Every \(settingsStore.current.shuffleIntervalInMin!) Minutes").tag(settingsStore.current.shuffleIntervalInMin)
                        }
                    } label: {
                        Text("Shuffle Interval")
                        Text("Disable or choose the interval when to pick a new random wallpaper")
                    }
                }
            } header: {
                Text("Wallpaper Settings")
            }
        }.formStyle(.grouped)
    }
}

#Preview {
    @Previewable @StateObject var launchSettings = LaunchSettings()
    @Previewable @State var autoFadeDurationInSec: Int? = 2
    @Previewable @State var shuffleIntervalInMin: Int? = 5
    
    GeneralSettingsView().environment(SettingsStore(settings: Settings()))
}

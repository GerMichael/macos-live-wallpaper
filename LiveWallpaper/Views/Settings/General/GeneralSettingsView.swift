//
//  GeneralSettingsView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI

struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var autoFadeDurationInSec: Int?
    @Binding var shuffleIntervalInMin: Int?

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
            get: { Double(autoFadeDurationInSec ?? 0) },
            set: { autoFadeDurationInSec = Int($0) }
        )
    }
    
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
            Section {
                VStack {
                    Slider(value: fadeDurationBinding, in: 0...maxCrossFade) {
                        Text("Cross Fade On Loop: " +
                             ((autoFadeDurationInSec ?? 0) > 0 ? "\(autoFadeDurationInSec!) Seconds" : "Off")
                        )
                    } minimumValueLabel: {
                        Text("Off")
                    } maximumValueLabel: {
                        Text(String(format: "%.0f Sec", maxCrossFade))
                    }
                    Divider()
                    Picker(selection: $shuffleIntervalInMin) {
                        ForEach(shuffleIntervalDefaults.keys.sorted(), id: \.self) { interval in
                            Text(shuffleIntervalDefaults[interval] ?? "").tag(interval)
                        }
                        if (shuffleIntervalInMin != nil && shuffleIntervalDefaults[shuffleIntervalInMin!] == nil) {
                            Text("Every \(shuffleIntervalInMin!) Minutes").tag(shuffleIntervalInMin)
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
    
    GeneralSettingsView(
        launchAtLogin: $launchSettings.launchAtLogin,
        autoFadeDurationInSec: $autoFadeDurationInSec,
        shuffleIntervalInMin: $shuffleIntervalInMin
    )
}

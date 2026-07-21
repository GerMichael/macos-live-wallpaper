//
//  ContentView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI


struct ActivityView: View {
    let selected: String
    
    var body: some View {
        Circle()
            .fill(.blue)
            .shadow(radius: 10)
            .overlay(
                Image(systemName: "figure.\(selected.lowercased())")
                    .font(.system(size: 144))
                    .foregroundColor(.white)
            )
    }
}

struct ContentView: View {
    let activities = ["Archery", "Baseball", "Basketball", "Bowling", "Boxing", "Cricket", "Curling", "Fencing", "Golf", "Hiking", "Lacrosse", "Rugby", "Squash"]

    @State var selected = "Baseball"
    @State var angle: Double = 0
    let rotationSpeedInS = 0.200
    
    var body: some View {
        VStack {
            Text("Why not try...")
                .font(.largeTitle.bold())
            
            ActivityView(selected: selected)
                .rotation3DEffect(
                    .degrees(angle),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            Text("\(selected)!")
                .font(.title)
            Button("Give me another one!", action: pickNewActivity)
                .buttonStyle(.glassProminent)
        }
        .padding()
    }
    
    private func pickNewActivity() {
        Task {
            for _ in 0...2 {
                withAnimation(.easeInOut(duration: rotationSpeedInS)) {
                    angle += 90
                }
                
                try? await Task.sleep(for: .seconds(rotationSpeedInS))
                
                selected = activities.randomElement()!
                
                withAnimation(.easeInOut(duration: rotationSpeedInS)) {
                    angle += 90
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

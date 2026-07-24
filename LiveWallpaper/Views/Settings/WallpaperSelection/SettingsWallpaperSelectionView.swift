import SwiftUI
import UniformTypeIdentifiers

import UniformTypeIdentifiers


struct SettingsWallpaperSelectionView: View {
    @Environment(SettingsStore.self) private var settingsStore
    
    @State private var movieFiles: [URL] = []
    @State private var currentlyAccessedFolder: URL?
    @State private var directoryMonitor = DirectoryMonitor()
    @Environment(WallpaperUrlProvider.self) private var wallpaperUrlProvider
    
    let columns = [GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 16)]
    
    var body: some View {
        @Bindable var settingsStore = settingsStore
        
        Form {
            Section {
                ToolsDirectorySelectorView(selectedDirectoryURL: $settingsStore.current.wallpaperDirectory)
            } header: {
                Text("Selected Movie Directory")
            }
            
            Section {
                if movieFiles.isEmpty {
                    VStack(alignment: .center, spacing: 0) {
                        Image(systemName: "exclamationmark.triangle")
                            .imageScale(.large)
                            .foregroundColor(Color(.systemGray))
                        Text(settingsStore.current.wallpaperDirectory == nil ? "Select a directory first." : "No movies found in this directory.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 10)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(movieFiles, id: \.self) { movieURL in
                            SettingsWallpaperPreviewItemView(
                                movieURL: movieURL,
                                isSelected: settingsStore.current.selectedWallpaper == movieURL,
                                onSelect: { settingsStore.current.selectedWallpaper = movieURL }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Select Movie")
            }
        }
        .formStyle(.grouped) // This applies the native macOS Settings style!
        .onAppear {
            if let selectedWallpaper = settingsStore.current.selectedWallpaper {
                wallpaperUrlProvider.startAccessingSecurityScopedResource(at: selectedWallpaper)
                setupDirectoryHandling(for: settingsStore.current.wallpaperDirectory)
            }
        }
        .onChange(of: settingsStore.current.wallpaperDirectory) { _, newURL in
            wallpaperUrlProvider.stopAccessingSecurityScopedResource()
            if let newURL {
                wallpaperUrlProvider.startAccessingSecurityScopedResource(at: newURL)
                setupDirectoryHandling(for: newURL)
            }
        }
        .onDisappear {
            directoryMonitor.stopMonitoring()
            wallpaperUrlProvider.stopAccessingSecurityScopedResource()
        }
    }
    
    // MARK: - Directory Handling
    
    private func setupDirectoryHandling(for url: URL?) {
        wallpaperUrlProvider.stopAccessingSecurityScopedResource()
        if let url {
            wallpaperUrlProvider.startAccessingSecurityScopedResource(at: url)
        }
        movieFiles = wallpaperUrlProvider.retrieveMediaURLs(from: url)
        
        if let url = url {
            directoryMonitor.startMonitoring(url: url) {
                // Reload movies when the folder contents change
                movieFiles = wallpaperUrlProvider.retrieveMediaURLs(from: url)
            }
        } else {
            directoryMonitor.stopMonitoring()
        }
    }
}

#Preview {
    @Previewable @State var isDirSelected = true
    @Previewable @State var isVideoSelected = true
    @Previewable @State var dummyDirectoryURL: URL? = Bundle.main.resourceURL
    @Previewable @State var dummyNilDirectoryURL: URL? = nil
    @Previewable @State var dummyVideoURL: URL? = Bundle.main.url(forResource: "example_video", withExtension: ".mp4")
    @Previewable @State var dummyNilVideoURL: URL? = nil
    VStack{
        HStack{
            Toggle("Directory Selected", isOn: $isDirSelected).toggleStyle(.switch)
            Toggle("Video Selected", isOn: $isVideoSelected).toggleStyle(.switch)
        }
        SettingsWallpaperSelectionView()
            .environment(SettingsStore(settings: Settings()))
    }
}

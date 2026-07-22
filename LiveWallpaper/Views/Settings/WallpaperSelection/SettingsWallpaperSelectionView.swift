import SwiftUI
import UniformTypeIdentifiers

import UniformTypeIdentifiers


struct SettingsWallpaperSelectionView: View {
    @Binding var selectedMovieDirectoryURL: URL?
    @Binding var selectedMovieURL: URL?
    
    @State private var movieFiles: [URL] = []
    @State private var currentlyAccessedFolder: URL?
    @State private var directoryMonitor = DirectoryMonitor()
    
    let columns = [GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 16)]
    
    var body: some View {
        Form {
            Section {
                ToolsDirectorySelectorView(selectedDirectoryURL: $selectedMovieDirectoryURL)
            } header: {
                Text("Selected Movie Directory")
            }
            
            Section {
                if movieFiles.isEmpty {
                    VStack(alignment: .center, spacing: 0) {
                        Image(systemName: "exclamationmark.triangle")
                            .imageScale(.large)
                            .foregroundColor(Color(.systemGray))
                        Text(selectedMovieDirectoryURL == nil ? "Select a directory first." : "No movies found in this directory.")
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
                                isSelected: selectedMovieURL == movieURL,
                                onSelect: { selectedMovieURL = movieURL }
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
            setupDirectoryHandling(for: selectedMovieDirectoryURL)
        }
        .onChange(of: selectedMovieDirectoryURL) { _, newURL in
            setupDirectoryHandling(for: newURL)
        }
        .onDisappear {
            directoryMonitor.stopMonitoring()
            currentlyAccessedFolder?.stopAccessingSecurityScopedResource()
        }
    }
    
    // MARK: - Directory Handling
    
    private func setupDirectoryHandling(for url: URL?) {
        loadMovies(from: url)
        
        if let url = url {
            directoryMonitor.startMonitoring(url: url) {
                // Reload movies when the folder contents change
                loadMovies(from: url)
            }
        } else {
            directoryMonitor.stopMonitoring()
        }
    }
    
    private func loadMovies(from url: URL?) {
        currentlyAccessedFolder?.stopAccessingSecurityScopedResource()
        movieFiles = []
        
        guard let url = url else { return }
        
        let hasAccess = url.startAccessingSecurityScopedResource()
        if hasAccess {
            currentlyAccessedFolder = url
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.contentTypeKey],
                options: .skipsHiddenFiles
            )
            
            self.movieFiles = fileURLs.filter { fileURL in
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.contentTypeKey]),
                      let contentType = resourceValues.contentType else {
                    return false
                }
                return contentType.conforms(to: .audiovisualContent)
            }
        } catch {
            print("Failed to read directory: \(error.localizedDescription)")
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
        SettingsWallpaperSelectionView(
            selectedMovieDirectoryURL: isDirSelected ? $dummyDirectoryURL : $dummyNilDirectoryURL,
            selectedMovieURL: isVideoSelected ? $dummyVideoURL : $dummyNilVideoURL,
        )
    }
}

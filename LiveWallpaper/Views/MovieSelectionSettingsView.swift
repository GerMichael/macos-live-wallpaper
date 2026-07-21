import SwiftUI
import UniformTypeIdentifiers

import UniformTypeIdentifiers

struct DirectorySelectorView: View {
    @Binding var selectedDirectoryURL: URL?
    @State private var showDocumentPicker = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(selectedDirectoryURL?.path ?? "No directory selected")
                    .foregroundColor(.secondary)
                Spacer()
                Button("Select Folder") {
                    showDocumentPicker = true
                }
            }
            
        }
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                selectedDirectoryURL = url
            }
        }
    }
}

struct MovieGridItemView: View {
    let movieURL: URL
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack {
            VideoPreviewView(url: movieURL)
                .frame(height: 80)
                .cornerRadius(6)
                .clipped()
            
            Text(movieURL.lastPathComponent)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .truncationMode(.middle)
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

struct MovieSelectionSettingsView: View {
    @Binding var selectedMovieDirectoryURL: URL?
    @Binding var selectedMovieURL: URL?
    
    @State private var movieFiles: [URL] = []
    // Currently accessed directory to release it later
    @State private var currentlyAccessedFolder: URL?
    
    let columns = [GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 16)]
    
    var body: some View {
        Form {
            Section("Selected Movie Directory") {
                DirectorySelectorView(selectedDirectoryURL: $selectedMovieDirectoryURL)
            }
            
            Section("Select Movie") {
                if movieFiles.isEmpty {
                    Text(selectedMovieDirectoryURL == nil ? "Select a directory first." : "No movies found in this directory.")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 10)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(movieFiles, id: \.self) { movieURL in
                            MovieGridItemView(
                                movieURL: movieURL,
                                isSelected: selectedMovieURL == movieURL,
                                onSelect: { selectedMovieURL = movieURL }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Movie Selection")
        .onAppear() {
            loadMovies(from: selectedMovieDirectoryURL)
        }
        .onChange(of: selectedMovieDirectoryURL) { _, newURL in
            loadMovies(from: newURL)
        }
        .onDisappear {
            // Close access
            currentlyAccessedFolder?.stopAccessingSecurityScopedResource()
        }
    }
    
    private func loadMovies(from url: URL?) {
        // Close access for old directory
        currentlyAccessedFolder?.stopAccessingSecurityScopedResource()
        movieFiles = []
        
        guard let url = url else { return }
        
        // Request access for new directory
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

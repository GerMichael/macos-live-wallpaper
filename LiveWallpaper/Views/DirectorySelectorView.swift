//
//  DirectorySelectorView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI
import UniformTypeIdentifiers

struct DirectorySelectorView: View {
    @Binding var selectedDirectoryURL: URL?
    @State private var showDocumentPicker = false
    
    var body: some View {
        HStack {
            if let url = selectedDirectoryURL {
                Label {
                    Text(url.path)
                        .lineLimit(1)
                        .truncationMode(.middle) // Keeps the start and end of the path visible
                } icon: {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue) // Gives it that classic macOS folder look
                }
                .foregroundColor(.secondary)
                .help(url.path) // Native macOS hover tooltip to show the full path
            } else {
                Text("No directory selected")
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 16)
            
            Button("Select Folder") {
                showDocumentPicker = true
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

#Preview {
    @Previewable @State var dummyURL: URL? = URL(fileURLWithPath: "/dev/null")
    DirectorySelectorView(
        selectedDirectoryURL: $dummyURL
    )
}

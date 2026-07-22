//
//  DirectorySelectorView.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import SwiftUI
import UniformTypeIdentifiers

let noDirectorySelectedText = "No directory selected"

struct ToolsDirectorySelectorView: View {
    @Binding var selectedDirectoryURL: URL?
    @State private var showDocumentPicker = false
    
    var body: some View {
        HStack {
            Label {
                Text(selectedDirectoryURL?.path ?? noDirectorySelectedText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } icon: {
                Image(systemName: "folder.fill")
                    .foregroundStyle(selectedDirectoryURL != nil ? .blue : .secondary)
            }
            .foregroundColor(.secondary)
            .help(selectedDirectoryURL?.path ?? noDirectorySelectedText)
            
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
    @Previewable @State var dummyURL: URL? = Bundle.main.resourceURL
    @Previewable @State var nilDummyURL: URL? = nil
    @Previewable @State var isSelected: Bool = true
    VStack {
        Toggle("Is selected", isOn: $isSelected).toggleStyle(.switch)
        Spacer()
        ToolsDirectorySelectorView(
            selectedDirectoryURL: isSelected ? $dummyURL : $nilDummyURL
        )
    }
    .padding()
    .frame(width: 300, height: 100)
}

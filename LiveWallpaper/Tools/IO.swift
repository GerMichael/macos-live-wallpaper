//
//  IO.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 22.07.26.
//

import Foundation
import UniformTypeIdentifiers

func getDirectoryItems(from url: URL, conformsToContentType: UTType) throws -> [URL] {
    let fileURLs = try FileManager.default.contentsOfDirectory(
        at: url,
        includingPropertiesForKeys: [.contentTypeKey],
        options: .skipsHiddenFiles
    )
    
    let files = fileURLs.filter { fileURL in
        guard let resourceValues = try? fileURL.resourceValues(forKeys: [.contentTypeKey]),
              let contentType = resourceValues.contentType else {
            return false
        }
        return contentType.conforms(to: conformsToContentType)
    }
    return files
}

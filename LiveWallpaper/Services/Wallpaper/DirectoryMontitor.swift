//
//  DirectoryMontitor.swift
//  LiveWallpaper
//
//  Created by Michael Gerischer on 21.07.26.
//

import Foundation

class DirectoryMonitor {
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1
    
    func startMonitoring(url: URL, onChange: @escaping () -> Void) {
        stopMonitoring()
        
        // Open the directory to get a file descriptor
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor != -1 else { return }
        
        // Create a dispatch source to monitor for write events (added, removed, renamed files)
        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.main
        )
        
        dispatchSource?.setEventHandler {
            onChange()
        }
        
        dispatchSource?.setCancelHandler { [fileDescriptor] in
            close(fileDescriptor)
        }
        
        dispatchSource?.resume()
    }
    
    func stopMonitoring() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }
}

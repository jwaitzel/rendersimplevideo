//
//  VideoTransferable.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/12/24.
//

import SwiftUI

#if targetEnvironment(simulator)
// simulator
let shoudOpenInPlace = false
#else
let shoudOpenInPlace = false
// real device
#endif

struct MP4Video: Transferable {
    
    var url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        
        FileRepresentation(contentType: .mpeg4Movie, shouldAttemptToOpenInPlace: shoudOpenInPlace) { video in
            return SentTransferredFile(video.url)
        } importing: { transferableFile in
            
            let fileName = transferableFile.file.lastPathComponent
            let copy: URL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            print("Temp filename \(copy) ")
            if FileManager.default.fileExists(atPath: copy.path) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: transferableFile.file, to: copy)
            return .init(url: copy)
        }
    }
}

//
//  RenderVideoEditorView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/8/24.
//

import SwiftUI
import AVKit

struct RenderVideoEditorView: View {
    
    private let player = AVPlayer(url: Bundle.main.url(forResource: "screen2", withExtension: "mp4")!)

    var body: some View {
        VStack {
            
            VideoPlayer(player: player)
                .scaledToFit()
//                .frame(height: 300)

            
            Button("Render") {
                createAndExportComposition { err in
                    print(err)
                }
            }
        }
        
    }
    
    func createAndExportComposition(completion: @escaping (Error?) -> Void) {
        // Create an AVMutableComposition
        let composition = AVMutableComposition()
        
        // Create video and audio tracks in our composition
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//              let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            completion(NSError(domain: "VideoComposer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create composition tracks"]))
            return
        }
        
        
        
        let videoURL = Bundle.main.url(forResource: "videouiux", withExtension: "mov")! //URL(fileURLWithPath: "/path/to/your/video.mov")
//        let audioURL = URL(fileURLWithPath: "/path/to/your/audio.m4a")
        let outputURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(for: .mpeg4Movie) //URL(fileURLWithPath: "/path/to/output/video.mp4")

        //Delete file if exists
        try? FileManager.default.removeItem(at: outputURL)
        
        // Load your video and audio assets
        let videoAsset = AVURLAsset(url: videoURL)
//        let audioAsset = AVURLAsset(url: audioURL)
        
        //let audioTrack = audioAsset.tracks(withMediaType: .audio).first
        
        // Get the first video and audio tracks from your assets
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(NSError(domain: "VideoComposer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get asset tracks"]))
            return
        }
        
        // Define the time range for the entire video
        let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
        
        do {
            // Add the video track to the composition
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            
//            // Add the audio track to the composition
//            try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        } catch {
            completion(error)
            return
        }
        
        // Set up an AVAssetExportSession to export the composition
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(NSError(domain: "VideoComposer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        // Perform the export
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("Completed \(outputURL)")
                completion(nil)
            case .failed:
                completion(exportSession.error)
            case .cancelled:
                completion(NSError(domain: "VideoComposer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Export cancelled"]))
            default:
                completion(NSError(domain: "VideoComposer", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown export error"]))
            }
        }
    }

}

#Preview {
    RenderVideoEditorView()
}

//
//  RenderVideoEditorView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/8/24.
//

import SwiftUI
import AVKit
import CoreImage

struct RenderVideoEditorView: View {
    
    @State private var player: AVPlayer? // = AVPlayer(url: Bundle.main.url(forResource: "screen2", withExtension: "mp4")!)

    @State private var videoComposer: VideoComposer = .init()
    
    var body: some View {
        VStack {
            
            if let player {
                VideoPlayer(player: player)
                    .scaledToFit()
            }
            
            
            Button("Render") {
                renderComposition()
            }
        }
        
    }
    
    func renderComposition() {
        
        let videoURL = Bundle.main.url(forResource: "screen2", withExtension: "mp4")!
        let outputURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(for: .mpeg4Movie)
//        let backVideoURL = URL.temporaryDirectory.appending(path: "outputimg19AF.mp4")
//        let backVideoURL = URL.temporaryDirectory.appending(path: "outputimg1DAA.mp4")
//        let backVideoURL = URL.temporaryDirectory.appending(path: "outputimgF166.mp4")
//        let videoAsset = AVURLAsset(url: videoURL)

//        let backgroundImageURL = Bundle.main.url(forResource: "backt", withExtension: "jpg")!
//        let imageRef = UIImage(contentsOfFile: backgroundImageURL.path())!.cgImage!
//        let outputBackVideoURL = FileManager.default.temporaryDirectory.appendingPathComponent("outputimg\(UUID().uuidString.prefix(4)).mp4")
        
        
        videoComposer.createAndExportComposition(videoURL: videoURL, outputURL: outputURL) { err in
            if let err {
                print("Error ", err)
            } else {
                print("Completed \(outputURL)")
                DispatchQueue.main.async {
                    self.player = AVPlayer(url: outputURL)
                }

            }
            
        }
//        try? videoComposer.createVideoFromImage(imageRef, duration: videoAsset.duration.seconds, outputURL: outputBackVideoURL) {
//            
//        }
    }
    
    func testCreateImageVideo() {
        
        let videoURL = Bundle.main.url(forResource: "screen2", withExtension: "mp4")!
        let videoAsset = AVURLAsset(url: videoURL)

        let backgroundImageURL = Bundle.main.url(forResource: "backt", withExtension: "jpg")!
        let imageRef = UIImage(contentsOfFile: backgroundImageURL.path())!.cgImage!
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("outputimg\(UUID().uuidString.prefix(4)).mp4")
        
        try? videoComposer.createVideoFromImage(imageRef, duration: videoAsset.duration.seconds, outputURL: outputURL) {
            print("Finished \(outputURL)")
        }
        
//        try? createVideoFromImage(imageRef, duration: videoAsset.duration.seconds, outputURL: outputURL, completion: {
//            print("finished making background video \(outputURL)")
//            
//            createAndExportComposition(backVideo: outputURL) { error in
//                print("error \(error)")
//            }
//            
//        })
        
    }
    
}


#Preview {
    RenderVideoEditorView()
}

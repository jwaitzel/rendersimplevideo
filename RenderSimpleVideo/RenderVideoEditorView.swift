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
//                createAndExportComposition { err in
//                    print(err)
//                }
                
                testCreateImageVideo()
            }
        }
        
    }
    
    func testCreateImageVideo() {
        
        let videoURL = Bundle.main.url(forResource: "screen2", withExtension: "mp4")!
        let videoAsset = AVURLAsset(url: videoURL)

        let backgroundImageURL = Bundle.main.url(forResource: "backt", withExtension: "jpg")!
        let imageRef = UIImage(contentsOfFile: backgroundImageURL.path())!.cgImage!
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("outputimg\(UUID().uuidString.prefix(4)).mp4")
        try? createVideoFromImage(imageRef, duration: videoAsset.duration.seconds, outputURL: outputURL, completion: {
            print("finished making background video \(outputURL)")
            
            createAndExportComposition(backVideo: outputURL) { error in
                print("error \(error)")
            }
            
        })
        
        
    }
    
    func createVideoFromImage(_ image: CGImage, duration: TimeInterval, outputURL: URL, completion: @escaping ()->()) throws {
        
//        let frameRate: Int32 = 30
        let size = CGSize(width: image.width, height: image.height)
        
        // Set up the AVAssetWriter
        let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)
        
        assetWriter.add(assetWriterInput)
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        // Create a CVPixelBuffer from the CGImage
        let pixelBuffer = try createPixelBuffer(from: image)
        
        // Calculate the number of frames
        let fps = 10
        let totalFrames = Int(duration * Double(fps))
        let frameTime = duration / Double(totalFrames)
        let timescale: Int32 = 600
        let frameDuration = CMTimeMake(value: Int64(timescale / Int32(fps)),
                                       timescale: timescale)
        var imageIndex = 0

        print("total frames \(totalFrames) \(frameTime) \(frameDuration.seconds)")
        
        // Write frames
        let queue = DispatchQueue(label: "com.videowriter.queue")
        assetWriterInput.requestMediaDataWhenReady(on: queue) {
            print("request more")
            if assetWriterInput.isReadyForMoreMediaData {
                let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(imageIndex))
                adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                print("adding frame \(imageIndex) \(frameTime) \(presentationTime)")
                imageIndex += 1
            }
            
            if imageIndex >= totalFrames {
                assetWriterInput.markAsFinished()
                assetWriter.finishWriting {
                    print("Video writing completed")
                    completion()
                }
            }
        }
    }
    
    func createPixelBuffer(from image: CGImage) throws -> CVPixelBuffer {
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         image.width,
                                         image.height,
                                         kCVPixelFormatType_32ARGB,
                                         attributes as CFDictionary,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw NSError(domain: "PixelBufferCreation", code: 1, userInfo: nil)
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: image.width,
                                height: image.height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
    
    func createAndExportComposition(backVideo: URL, completion: @escaping (Error?) -> Void) {
        // Create an AVMutableComposition
        let composition = AVMutableComposition()
        
        // Create video and audio tracks in our composition
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let backgroundTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
//              let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            completion(NSError(domain: "VideoComposer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create composition tracks"]))
            return
        }
        
        let videoURL = Bundle.main.url(forResource: "screen2", withExtension: "mp4")! //URL(fileURLWithPath: "/path/to/your/video.mov")
//        let audioURL = URL(fileURLWithPath: "/path/to/your/audio.m4a")
//        let backgroundImageURL = Bundle.main.url(forResource: "backt", withExtension: "jpg")!
//        let imageAsset = AVURLAsset(url: backgroundImageURL)
        let outputURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(for: .mpeg4Movie) //URL(fileURLWithPath: "/path/to/output/video.mp4")

        //Delete file if exists
        try? FileManager.default.removeItem(at: outputURL)
        
        // Load your video and audio assets
        let videoAsset = AVURLAsset(url: videoURL)
        let backAsset = AVURLAsset(url: backVideo)
//        let audioAsset = AVURLAsset(url: audioURL)
        
        //let audioTrack = audioAsset.tracks(withMediaType: .audio).first
        
        // Get the first video and audio tracks from your assets
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first
                ,
              let backVideoAsset = backAsset.tracks(withMediaType: .video).first 
        else {
            completion(NSError(domain: "VideoComposer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get asset tracks"]))
            return
        }
        
        // Define the time range for the entire video
        let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
        
        do {
            // Add the video track to the composition
//            compositionVideoTrack.preferredTransform = CGAffineTransform(rotationAngle: .pi * 0.15)
            
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
//            compositionVideoTrack.preferredTransform = CGAffineTransform(translationX: 0.5, y: -0.5)
//            let imageGenerator = AVAssetImageGenerator(asset: imageAsset)
//            imageGenerator.appliesPreferredTrackTransform = true
//            let imageRef = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
//            let imageRef = UIImage(contentsOfFile: backgroundImageURL.path())!.cgImage!
//            let imgVideoTrack = try AVAssetTrack.videoTrackWithImage(image: imageRef, duration: videoAsset.duration)
            // Set the background track to be positioned behind the main video
//            imgVideoTrack.preferredTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
//            backgroundTrack.preferredTransform = .init(rotationAngle: 0.15).concatenating(.init(scaleX: 1.4, y: 1.4))
            
            try backgroundTrack.insertTimeRange(timeRange, of: backVideoAsset, at: .zero)
                        
//            backgroundTrack.preferredTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            
//            // Add the audio track to the composition
//            try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        } catch {
            completion(error)
            return
        }
        
        // Create a video composition for layering
        let mutableVideoComposition = AVMutableVideoComposition(propertiesOf: composition)//
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        
//        instruction.backgroundColor = UIColor.red.cgColor
//        instruction.enablePostProcessing = true
        
        let renderSize: CGSize = CGSize(width: 720, height: 720)
        print("natural \(renderSize)")
//        videoComposition.renderSize = renderSize
//        videoComposition.renderScale = 0.5
//        composition.naturalSize = .init(width: 450, height: 450)
        
//        videoComposition.renderSize = CGSize(width: 720, height: 720)
        let scaleToFitBackgroundWidth = renderSize.width / backgroundTrack.naturalSize.width
        let scaleToFitBackgroundHeight = renderSize.height / backgroundTrack.naturalSize.height
        
        let backgroundLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: backgroundTrack)
        backgroundLayerInstruction.setTransform(.init(scaleX: scaleToFitBackgroundWidth, y: scaleToFitBackgroundHeight), at: .zero)
        
//        compositionVideoTrack.preferredTransform = .init(rotationAngle: 0.1)
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        videoLayerInstruction.setTransform(.init(scaleX: 0.1, y: 0.1), at: .zero)

//        let backgroundLayer = CALayer()
//        backgroundLayer.frame = CGRect(origin: .zero, size: renderSize)
//        backgroundLayer.contents = UIColor.brown.cgColor
//        let videoLayer = CALayer()
//        videoLayer.frame = CGRect(origin: .init(x: 0, y: 0), size: renderSize)
//        videoLayer.transform = CATransform3DMakeRotation(0.7, 0.0, 0.0, 1.0)
//        videoLayer.backgroundColor = UIColor.orange.cgColor
//        let outputLayer = CALayer()
//        outputLayer.frame = CGRect(origin: .zero, size: renderSize)
//        outputLayer.backgroundColor = UIColor.green.cgColor
//        outputLayer.addSublayer(backgroundLayer)
//        outputLayer.addSublayer(videoLayer)
        
        
//        videoLayerInstruction.setTransform(.init(scaleX: 0.2, y: 0.2).concatenating(.init(translationX: 10, y: -10)), at: .zero)
//        videoLayerInstruction.setTransform(.init(scaleX: 0.2, y: 0.2).concatenating(.init(translationX: 10, y: 10)), at: timeRange.duration)
//        compositionVideoTrack.preferredTransform = CGAffineTransform(scaleX: 0.5, y: 0.5)
//        videoLayerInstruction.setOpacity(0.5, at: .zero)
        //backgroundLayerInstruction,
//        videoLayerInstruction.setTransform(compositionVideoTrack.preferredTransform, at: .zero)
        instruction.layerInstructions = [videoLayerInstruction, backgroundLayerInstruction]
        mutableVideoComposition.instructions = [instruction]
        
//        mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
        
//        composition.naturalSize = renderSize
        mutableVideoComposition.renderSize = renderSize
        
        // Set up an AVAssetExportSession to export the composition
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(NSError(domain: "VideoComposer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"]))
            return
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = mutableVideoComposition
        
//        exportSession.shouldOptimizeForNetworkUse = true
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

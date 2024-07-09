//
//  RenderVideoEditorView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/8/24.
//

import SwiftUI
import AVKit


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
//                testCreateImageVideo()
//                createAndExportComposition { err in
//                    print(err)
//                }
                
//                testCreateImageVideo()
            }
        }
        
    }
    
    func renderComposition() {
        
        let videoURL = Bundle.main.url(forResource: "screen2", withExtension: "mp4")!
        let outputURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(for: .mpeg4Movie)
//        let backVideoURL = URL.temporaryDirectory.appending(path: "outputimg19AF.mp4")
//        let backVideoURL = URL.temporaryDirectory.appending(path: "outputimg1DAA.mp4")
        let backVideoURL = URL.temporaryDirectory.appending(path: "outputimgF166.mp4")
        let videoAsset = AVURLAsset(url: videoURL)

//        let backgroundImageURL = Bundle.main.url(forResource: "backt", withExtension: "jpg")!
//        let imageRef = UIImage(contentsOfFile: backgroundImageURL.path())!.cgImage!
//        let outputBackVideoURL = FileManager.default.temporaryDirectory.appendingPathComponent("outputimg\(UUID().uuidString.prefix(4)).mp4")
        
        
        videoComposer.createAndExportComposition(videoURL: videoURL, backVideoURL: backVideoURL, outputURL: outputURL) { err in
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


enum RenderError: Error {
    case failedCompositionTrack
    case failedFetchAssetTrack
    case failedCreateExportSession
    case exportCancelled
    case unknownError
}

class VideoComposer {
    
    func createAndExportComposition(videoURL: URL, backVideoURL: URL, outputURL: URL, completion: @escaping (Error?) -> Void) {
        // Create an AVMutableComposition
        let composition = AVMutableComposition()
        
        // Create video and audio tracks in our composition
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let backgroundTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(RenderError.failedCompositionTrack)
            return
        }
        

        //Delete file if exists
//        try? FileManager.default.removeItem(at: outputURL)
        
        // Load your video and audio assets
        let videoAsset = AVURLAsset(url: videoURL)
        let backAsset = AVURLAsset(url: backVideoURL)
        
        // Get the first video and audio tracks from your assets
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first,
              let backVideoAsset = backAsset.tracks(withMediaType: .video).first else {
            completion(RenderError.failedFetchAssetTrack)
            return
        }
        
        // Define the time range for the entire video
        let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
        
        do {
            // Add the video track to the composition
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            try backgroundTrack.insertTimeRange(timeRange, of: backVideoAsset, at: .zero)
        } catch {
            completion(error)
            return
        }
        

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        
        let sqRenderSize: CGFloat = 1024
        let renderSize: CGSize = CGSize(width: sqRenderSize, height: sqRenderSize)

        let scaleToFitBackgroundWidth = renderSize.width / backgroundTrack.naturalSize.width
        let scaleToFitBackgroundHeight = renderSize.height / backgroundTrack.naturalSize.height

        /// Background Transform
        let backgroundLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: backgroundTrack)
        backgroundLayerInstruction.setTransform(.init(scaleX: scaleToFitBackgroundWidth, y: scaleToFitBackgroundHeight), at: .zero)
//        backgroundLayerInstruction.trackID = overlayTrackID
        
        /// Video transform
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        let videoTrackSize = compositionVideoTrack.naturalSize
        
        let videoScaleToFit = renderSize.height / videoTrackSize.height
        let newVideoSize = CGSize(width: videoTrackSize.width * videoScaleToFit, height: videoTrackSize.height * videoScaleToFit)
        let translationX = renderSize.width / 2.0 - newVideoSize.width / 2.0
        print("Video track size \(videoTrackSize) videoScaleToFit \(videoScaleToFit) newVideoSize \(newVideoSize)")
        let translateToCenterTransform = CGAffineTransform(translationX: translationX, y: 0.0)
        let multVideoTransform = CGAffineTransform(scaleX: videoScaleToFit, y: videoScaleToFit).concatenating(translateToCenterTransform)
        
        videoLayerInstruction.setTransform(multVideoTransform, at: .zero)
        
        //// WORK FOR SIMULATOR
//        let layerImgURL = Bundle.main.url(forResource: "iPhone 14 Pro - Space Black - Portrait", withExtension: "png")!
//        guard let watermarkImage: CIImage =  CIImage(image: UIImage(contentsOfFile: layerImgURL.path)!) else { print("error"); return }
//
//        let filter = CIFilter(name: "CISourceAtopCompositing")!
////        filter.setDefaults()
//        filter.setValue(watermarkImage.clampedToExtent(), forKey: kCIInputImageKey)
//        let mutableVideoComposition = AVMutableVideoComposition(asset: composition) { filteringRequest in
////            print("request \(filteringRequest.compositionTime.seconds)")
//            let source = filteringRequest.sourceImage.transformed(by: multVideoTransform).cropped(to: filteringRequest.sourceImage.extent)
//            filter.setValue(source, forKey: "inputBackgroundImage")
//            // Provide the filter output to the composition
//            filteringRequest.finish(with: filter.outputImage!, context: nil)
//        }
        
        // Create a video composition for layering
        let mutableVideoComposition = AVMutableVideoComposition(propertiesOf: composition)
        
//        let backgroundLayer = CALayer()
//        backgroundLayer.isOpaque = true
//        backgroundLayer.frame = CGRect(origin: .zero, size: renderSize)
//        
//        let videoLayer = CALayer()
//        videoLayer.frame = CGRect(origin: .zero, size: renderSize)
//        videoLayer.isOpaque = true
//        let overlayLayer = CALayer()
//        overlayLayer.frame = CGRect(origin: .zero, size: renderSize)
//        overlayLayer.isOpaque = true
        
//        let layerImgURL = Bundle.main.url(forResource: "iPhone 14 Pro - Space Black - Portrait", withExtension: "png")!
//        let layerImgURL = Bundle.main.url(forResource: "iPhoneOverlay", withExtension: "jpg")!
//        let iphoneLayerImg = UIImage(contentsOfFile: layerImgURL.path)!.cgImage!
//        overlayLayer.contents = iphoneLayerImg
//        overlayLayer.contentsGravity = .resizeAspect
//        
//        let outputLayer = CALayer()
//        outputLayer.frame = CGRect(origin: .zero, size: renderSize)
//        outputLayer.isOpaque = true
//        outputLayer.addSublayer(backgroundLayer)
//        outputLayer.addSublayer(videoLayer)
//        outputLayer.addSublayer(overlayLayer)
        
        

//        mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
        //AVVideoCompositionCoreAnimationTool(additionalLayer: outputLayer, asTrackID: overlayTrackID)
        //

        instruction.layerInstructions = [videoLayerInstruction, backgroundLayerInstruction]
        mutableVideoComposition.instructions = [instruction]
        mutableVideoComposition.renderSize = renderSize
        
        // Set up an AVAssetExportSession to export the composition
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality) else {
            completion(RenderError.failedCreateExportSession)
            return
        }

//        exportSession.timeRange = timeRange
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = mutableVideoComposition
        
        // Perform the export
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("Completed \(outputURL)")
                completion(nil)
            case .failed:
                completion(exportSession.error)
            case .cancelled:
                completion(RenderError.exportCancelled)
            default:
                completion(RenderError.unknownError)
            }
        }
    }
    
    func createVideoFromImage(_ image: CGImage, duration: TimeInterval, outputURL: URL, completion: @escaping ()->()) throws {
        
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
        let fps = 30
        let totalFrames = Int(duration * Double(fps))
        let timescale: Int32 = 600
        let frameDuration = CMTimeMake(value: Int64(timescale / Int32(fps)), timescale: timescale)
        var imageIndex = 0

        print("total frames \(totalFrames) \(frameDuration.seconds)")
        
        // Write frames
        let queue = DispatchQueue(label: "com.videowriter.queue")
        assetWriterInput.requestMediaDataWhenReady(on: queue) {
            print("request more")
            if assetWriterInput.isReadyForMoreMediaData {
                let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(imageIndex))
                adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                print("adding frame \(imageIndex) \(presentationTime)")
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
    
    
}

#Preview {
    RenderVideoEditorView()
}

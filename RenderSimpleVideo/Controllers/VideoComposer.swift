//
//  VideoComposer.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/11/24.
//

import SwiftUI
import AVKit

enum RenderError: Error {
    case failedCompositionTrack
    case failedFetchAssetTrack
    case failedCreateExportSession
    case exportCancelled
    case unknownError
}

class VideoComposer {
    
    func createAndExportComposition(videoURL: URL, outputURL: URL, completion: @escaping (Error?) -> Void) {
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
//        let backAsset = AVURLAsset(url: backVideoURL)
        
        // Get the first video and audio tracks from your assets
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(RenderError.failedFetchAssetTrack)
            return
        }
        
        // Define the time range for the entire video
        let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
        
        do {
            // Add the video track to the composition
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
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
//        let backgroundLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: backgroundTrack)
//        backgroundLayerInstruction.setTransform(.init(scaleX: scaleToFitBackgroundWidth, y: scaleToFitBackgroundHeight), at: .zero)
//        backgroundLayerInstruction.trackID = overlayTrackID
        
        /// Video transform
//        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        let videoTrackSize = compositionVideoTrack.naturalSize
        
        let videoScaleToFit = renderSize.height / videoTrackSize.height
        let scaleParameter = 0.9
        let videoAddScale = videoScaleToFit * scaleParameter
        let newVideoSize = CGSize(width: videoTrackSize.width * videoAddScale, height: videoTrackSize.height * videoAddScale)
        let translationX = renderSize.width / 2.0 - newVideoSize.width / 2.0
        let translationY = renderSize.height / 2.0 - newVideoSize.height / 2.0
        print("Video track size \(videoTrackSize) videoScaleToFit \(videoScaleToFit) videoAddScale \(videoAddScale) newVideoSize \(newVideoSize)")
        
        let translateToCenterTransform = CGAffineTransform(translationX: translationX, y: translationY)
        let multVideoTransform = CGAffineTransform(scaleX: videoAddScale, y: videoAddScale).concatenating(translateToCenterTransform)
        
//        videoLayerInstruction.setTransform(multVideoTransform, at: .zero)
                
        //MARK: CI Filter composition
        let backColor = CIColor(color: UIColor.red)
        let backColorGenerator = CIFilter(name: "CIConstantColorGenerator", parameters: [kCIInputColorKey: backColor])!
        
        let compositeColor = CIFilter(name: "CIBlendWithMask")!
        compositeColor.setValue(backColorGenerator.outputImage, forKey: kCIInputBackgroundImageKey)
        
        let iphoneOverlayImgURL = Bundle.main.url(forResource: "iPhone 14 Pro - Space Black - Portrait", withExtension: "png")!
        let iphoneOverlayImg = UIImage(contentsOfFile: iphoneOverlayImgURL.path)!
        guard let iphoneOverlay: CIImage =  CIImage(image: iphoneOverlayImg) else { print("error"); return }

        let overlayResizeFit = renderSize.height / iphoneOverlay.extent.height
        let overlayScaleParameter = 0.94
        let ovlerlayAddedScale = overlayResizeFit * overlayScaleParameter
        let iphoneOverlayResize = CGSize(width: iphoneOverlay.extent.width * ovlerlayAddedScale, height: iphoneOverlay.extent.height * ovlerlayAddedScale)
        let iphoneOverlayTransformSize = CGAffineTransform(scaleX: ovlerlayAddedScale, y: ovlerlayAddedScale)
        let iphoneOverlayTranslationX = renderSize.width / 2.0 - iphoneOverlayResize.width / 2.0
        let iphoneOverlayTranslationY = renderSize.height / 2.0 - iphoneOverlayResize.height / 2.0
        let iphoneOverlayTranslation = CGAffineTransform(translationX: iphoneOverlayTranslationX, y: iphoneOverlayTranslationY)
        let iphoneOverlayTransform = iphoneOverlayTransformSize.concatenating(iphoneOverlayTranslation)
        
        print("New resize for overlay \(iphoneOverlayResize)")
        
//        let maskFilterOnVideo = CIFilter(name: "CISourceInCompositing")!
        let roundedRectangleGenerator = CIFilter(name: "CIRoundedRectangleGenerator")!
        let videoTransformedRect = CGRectApplyAffineTransform(CGRect(origin: .zero, size: newVideoSize), translateToCenterTransform)
        roundedRectangleGenerator.setValue(videoTransformedRect, forKey: kCIInputExtentKey)
        roundedRectangleGenerator.setValue(CIColor(color: .white), forKey: kCIInputColorKey)
        roundedRectangleGenerator.setValue(55, forKey: kCIInputRadiusKey)
        compositeColor.setValue(roundedRectangleGenerator.outputImage, forKey: kCIInputMaskImageKey)
        
        let iphoneOverlayComposite = CIFilter(name: "CISourceOverCompositing")!
        iphoneOverlayComposite.setValue(iphoneOverlay.transformed(by: iphoneOverlayTransform), forKey: kCIInputImageKey)
        
        let mutableVideoComposition = AVMutableVideoComposition(asset: composition) { filteringRequest in
            
            let source = filteringRequest.sourceImage.transformed(by: multVideoTransform).cropped(to: filteringRequest.sourceImage.extent)
            compositeColor.setValue(source, forKey: kCIInputImageKey)
            iphoneOverlayComposite.setValue(compositeColor.outputImage, forKey: kCIInputBackgroundImageKey)
            
            // Provide the filter output to the composition
            filteringRequest.finish(with: iphoneOverlayComposite.outputImage!, context: nil)
        }
        
        mutableVideoComposition.renderSize = renderSize
        
        // Set up an AVAssetExportSession to export the composition
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality) else {
            completion(RenderError.failedCreateExportSession)
            return
        }

        exportSession.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 3, preferredTimescale: 600))
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


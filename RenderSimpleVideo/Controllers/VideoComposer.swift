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
    
    func compositeBackground(videoSize: CGSize, sourceFrame: CIImage, renderOptions: RenderOptions) -> CIFilter? {
        
        let renderSize = renderOptions.renderSize
        let videoTrackSize = videoSize

        /// Back Color generator
        let backColor = CIColor(color: UIColor(renderOptions.backColor))
        let backColorGenerator = CIFilter(name: "CIConstantColorGenerator", parameters: [kCIInputColorKey: backColor])!
        
        /// Video transform
        let videoScaleToFit = renderSize.height / videoTrackSize.height
        let scaleParameter = renderOptions.scaleVideo / 100.0
        let videoAddScale = videoScaleToFit * scaleParameter
        let newVideoSize = CGSize(width: videoTrackSize.width * videoAddScale, height: videoTrackSize.height * videoAddScale)
        let translationX = renderSize.width / 2.0 - newVideoSize.width / 2.0 + renderOptions.offsetX
        let translationY = renderSize.height / 2.0 - newVideoSize.height / 2.0 + renderOptions.offsetY

        let translateToCenterTransform = CGAffineTransform(translationX: translationX, y: translationY)
        let multVideoTransform = CGAffineTransform(scaleX: videoAddScale, y: videoAddScale).concatenating(translateToCenterTransform)

        /// Mask Composite with background and masked screen
        let compositeColor = CIFilter(name: "CIBlendWithMask")! //CIBlendWithMask //CISourceOverCompositing
        compositeColor.setValue(backColorGenerator.outputImage, forKey: kCIInputBackgroundImageKey)

        print("Video track size \(videoTrackSize) videoScaleToFit \(videoScaleToFit) videoAddScale \(videoAddScale) newVideoSize \(newVideoSize)")

        /// Oveerlay Image
        let iphoneOverlayImgURL = Bundle.main.url(forResource: "iPhone 14 Pro - Space Black - Portrait", withExtension: "png")!
        let iphoneOverlayImg = UIImage(contentsOfFile: iphoneOverlayImgURL.path)!
        guard let iphoneOverlay: CIImage =  CIImage(image: iphoneOverlayImg) else { print("error ci overlay"); return nil }

        let overlayResizeFit = renderSize.height / iphoneOverlay.extent.height
        let overlayScaleParameter = (renderOptions.scaleVideo * 1.06) / 100.0
        let ovlerlayAddedScale = overlayResizeFit * overlayScaleParameter
        let iphoneOverlayResize = CGSize(width: iphoneOverlay.extent.width * ovlerlayAddedScale, height: iphoneOverlay.extent.height * ovlerlayAddedScale)
        let iphoneOverlayTransformSize = CGAffineTransform(scaleX: ovlerlayAddedScale, y: ovlerlayAddedScale)
        let iphoneOverlayTranslationX = renderSize.width / 2.0 - iphoneOverlayResize.width / 2.0 + renderOptions.offsetX
        let iphoneOverlayTranslationY = renderSize.height / 2.0 - iphoneOverlayResize.height / 2.0 + renderOptions.offsetY
        let iphoneOverlayTranslation = CGAffineTransform(translationX: iphoneOverlayTranslationX, y: iphoneOverlayTranslationY)
        let iphoneOverlayTransform = iphoneOverlayTransformSize.concatenating(iphoneOverlayTranslation)

        /// Mask Rounded Rectangle Genrator
        let adjustCorners = 55.0 * overlayScaleParameter
        let roundedRectangleGenerator = CIFilter(name: "CIRoundedRectangleGenerator")!
        let videoTransformedRect = CGRectApplyAffineTransform(CGRect(origin: .zero, size: videoTrackSize), multVideoTransform)
        roundedRectangleGenerator.setValue(videoTransformedRect, forKey: kCIInputExtentKey)
        roundedRectangleGenerator.setValue(CIColor(color: .white), forKey: kCIInputColorKey)
        roundedRectangleGenerator.setValue(adjustCorners, forKey: kCIInputRadiusKey)
        compositeColor.setValue(roundedRectangleGenerator.outputImage, forKey: kCIInputMaskImageKey)
        
        /// Composite
        let iphoneOverlayComposite = CIFilter(name: "CISourceOverCompositing")!
        iphoneOverlayComposite.setValue(iphoneOverlay.transformed(by: iphoneOverlayTransform), forKey: kCIInputImageKey)

        let source = sourceFrame.transformed(by: multVideoTransform)
        compositeColor.setValue(source, forKey: kCIInputImageKey)

        iphoneOverlayComposite.setValue(compositeColor.outputImage, forKey: kCIInputBackgroundImageKey)
        
        return iphoneOverlayComposite
    }
    
    func createImagePreview(_ screenImage: UIImage, renderOptions: RenderOptions) -> UIImage? {
        
        let renderSize = renderOptions.renderSize
        let videoTrackSize = screenImage.size
        let sourceCI = CIImage(image: screenImage)!

        guard let iphoneOverlayComposite = compositeBackground(videoSize: videoTrackSize, sourceFrame: sourceCI, renderOptions: renderOptions) else {
            print("Failed composite"); return nil
        }
        
        let outputCI = iphoneOverlayComposite.outputImage! //compositeColor.outputImage! // //

        let context = CIContext()
        let cgOutputImage = context.createCGImage(outputCI, from: .init(origin: .zero, size: renderSize))!
        
        return UIImage(cgImage: cgOutputImage)

    }
    
    func createAndExportComposition(videoURL: URL, outputURL: URL, renderOptions: RenderOptions, progress:@escaping (CGFloat)->(), completion: @escaping (Error?) -> Void) {
        // Create an AVMutableComposition
        let composition = AVMutableComposition()
        let startRenderTime = Date()
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
        
        let videoTrackSize = compositionVideoTrack.naturalSize
        
        let mutableVideoComposition = AVMutableVideoComposition(asset: composition) { filteringRequest in
            
            guard let iphoneOverlayComposite = self.compositeBackground(videoSize: videoTrackSize, sourceFrame: filteringRequest.sourceImage, renderOptions: renderOptions) else {
                print("Failed composite"); return
            }
            progress(filteringRequest.compositionTime.seconds / timeRange.duration.seconds)
            
            // Provide the filter output to the composition
            filteringRequest.finish(with: iphoneOverlayComposite.outputImage!, context: nil)
        }
        
        mutableVideoComposition.renderSize = renderOptions.renderSize
        
        // Set up an AVAssetExportSession to export the composition
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality) else {
            completion(RenderError.failedCreateExportSession)
            return
        }

//        exportSession.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 3, preferredTimescale: 600))
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = mutableVideoComposition
        
        // Perform the export
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                let endTiem = Date().timeIntervalSince(startRenderTime)
                print("Completed \(outputURL) in time \(endTiem)")
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


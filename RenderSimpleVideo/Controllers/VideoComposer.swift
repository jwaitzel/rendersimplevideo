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
    case failedCreateComposite
    case exportCancelled
    case unknownError
}

class VideoComposer {
    
    func compositeFilter(renderOptions: RenderOptions, videoFrameSize: CGSize) -> (CIFilter, CIFilter, CGAffineTransform)? {
        
        let renderSize = renderOptions.renderSize

        /// Back Color generator
        let backColor = CIColor(color: UIColor(renderOptions.backColor))
        let backColorGenerator = CIFilter(name: "CIConstantColorGenerator", parameters: [kCIInputColorKey: backColor])!

        /// Video transform
        let videoScaleToFit = renderSize.height / videoFrameSize.height
        let scaleParameter = renderOptions.scaleVideo / 100.0
        let videoAddScale = videoScaleToFit * scaleParameter
        let newVideoSize = CGSize(width: videoFrameSize.width * videoAddScale, height: videoFrameSize.height * videoAddScale)
        let translationX = renderSize.width / 2.0 - newVideoSize.width / 2.0 + renderOptions.offsetX
        let translationY = renderSize.height / 2.0 - newVideoSize.height / 2.0 + renderOptions.offsetY
        let translateToCenterTransform = CGAffineTransform(translationX: translationX, y: translationY)
        let multVideoTransform = CGAffineTransform(scaleX: videoAddScale, y: videoAddScale).concatenating(translateToCenterTransform)
        
        /// Mask Composite with background and masked screen
        let compositeBackColor = CIFilter(name: "CIBlendWithMask")! //CIBlendWithMask //CISourceOverCompositing
        compositeBackColor.setValue(backColorGenerator.outputImage, forKey: kCIInputBackgroundImageKey)

        print("Video track size \(videoFrameSize) videoScaleToFit \(videoScaleToFit) videoAddScale \(videoAddScale) newVideoSize \(newVideoSize)")
        
        /// Overlay Image
        let iphoneOverlayImgURL = Bundle.main.url(forResource: "iPhone 14 Pro - Space Black - Portrait", withExtension: "png")!
        let iphoneOverlayImg = UIImage(contentsOfFile: iphoneOverlayImgURL.path)!
        guard let iphoneOverlay: CIImage =  CIImage(image: iphoneOverlayImg) else { print("error ci overlay"); return nil }

        /// Overlay Transform
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
        let videoTransformedRect = CGRectApplyAffineTransform(CGRect(origin: .zero, size: videoFrameSize), multVideoTransform)
        roundedRectangleGenerator.setValue(videoTransformedRect, forKey: kCIInputExtentKey)
        roundedRectangleGenerator.setValue(CIColor(color: .white), forKey: kCIInputColorKey)
        roundedRectangleGenerator.setValue(adjustCorners, forKey: kCIInputRadiusKey)
        compositeBackColor.setValue(roundedRectangleGenerator.outputImage, forKey: kCIInputMaskImageKey)
        
        /// Composite background with video
        let iphoneOverlayComposite = CIFilter(name: "CISourceOverCompositing")!
        iphoneOverlayComposite.setValue(iphoneOverlay.transformed(by: iphoneOverlayTransform), forKey: kCIInputImageKey)


        
        return (compositeBackColor, iphoneOverlayComposite, multVideoTransform)
    }
    
    func compositeBackground(videoSize: CGSize, sourceVideoImage: CIImage, renderOptions: RenderOptions) -> CIImage? {
        
//        let renderSize = renderOptions.renderSize
        let videoTrackSize = sourceVideoImage.extent.size
        
        guard let (compositeBackFilter, iphoneOverlayFilter, videoTransform) = self.compositeFilter(renderOptions: renderOptions, videoFrameSize: videoTrackSize) else { return nil }

        let sourceCI = sourceVideoImage.transformed(by: videoTransform)
        compositeBackFilter.setValue(sourceCI, forKey: kCIInputImageKey)

        iphoneOverlayFilter.setValue(compositeBackFilter.outputImage, forKey: kCIInputBackgroundImageKey)

        
        return iphoneOverlayFilter.outputImage!
    }
    
    func createImagePreview(_ screenImage: UIImage, renderOptions: RenderOptions) -> UIImage? {
        
        let renderSize = renderOptions.renderSize
        let videoTrackSize = screenImage.size
        let sourceCI = CIImage(image: screenImage)!
        print("Video track size \(videoTrackSize)")

        guard let iphoneOverlayCompositeImg = compositeBackground(videoSize: videoTrackSize, sourceVideoImage: sourceCI, renderOptions: renderOptions) else {
            print("Failed composite"); return nil
        }
        
        let outputCI = iphoneOverlayCompositeImg //compositeColor.outputImage! // //

        let context = CIContext()
        let cgOutputImage = context.createCGImage(outputCI, from: .init(origin: .zero, size: renderSize))!
        
        return UIImage(cgImage: cgOutputImage)

    }
    
    func createAndExportComposition(videoURL: URL, outputURL: URL, renderOptions: RenderOptions, progress:@escaping (CGFloat)->(), completion: @escaping (Error?) -> Void) {
        // Create an AVMutableComposition
        let composition = AVMutableComposition()
        let startRenderTime = Date()
        // Create video and audio tracks in our composition
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(RenderError.failedCompositionTrack)
            return
        }

        //Delete file if exists
//        try? FileManager.default.removeItem(at: outputURL)
        
        // Load your video and audio assets
        let videoAsset = AVURLAsset(url: videoURL)
        
        // Get the first video and audio tracks from your assets
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(RenderError.failedFetchAssetTrack)
            return
        }
        
        var compositionAudioTrack: AVMutableCompositionTrack?
        let audioTrack = videoAsset.tracks(withMediaType: .audio).first
        if audioTrack != nil {
            compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        }
        
        // Define the time range for the entire video
        let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
//        let timeSpeedMultiplier = 4.0
//        let multipliedTimeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: videoAsset.duration.seconds / timeSpeedMultiplier, preferredTimescale: timeRange.duration.timescale) )
        
        do {
            // Add the video track to the composition
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
            //CMTime(seconds: videoAsset.duration.seconds / timeSpeedMultiplier, preferredTimescale: timeRange.duration.timescale)
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            compositionVideoTrack.scaleTimeRange(timeRange, toDuration: videoAsset.duration)
            if let audioTrack, let compositionAudioTrack {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
                compositionAudioTrack.scaleTimeRange(timeRange, toDuration: videoAsset.duration)
            }
        } catch {
            completion(error)
            return
        }

        var videoTrackSize = compositionVideoTrack.naturalSize
        let videoPreferredTransform = videoTrack.preferredTransform
        var isVideoAssetPortrait: Bool = false
        if(videoPreferredTransform.a == 0 && videoPreferredTransform.b == 1.0 && videoPreferredTransform.c == -1.0 && videoPreferredTransform.d == 0)  { isVideoAssetPortrait = true}
        if(videoPreferredTransform.a == 0 && videoPreferredTransform.b == -1.0 && videoPreferredTransform.c == 1.0 && videoPreferredTransform.d == 0)  { isVideoAssetPortrait = true}

        if isVideoAssetPortrait {
            videoTrackSize = CGSize(width: videoTrackSize.height, height: videoTrackSize.width)
        }
        
        guard let (compositeBackFilter, iphoneOverlayFilter, videoTransform) = self.compositeFilter(renderOptions: renderOptions, videoFrameSize: videoTrackSize) else {
            completion(RenderError.failedCreateComposite)
            return
        }
        



        print("Video natural size \(videoTrackSize) videoTransform \(videoTransform) videoPrefferedTransform \(videoPreferredTransform)")
        let mutableVideoComposition = AVMutableVideoComposition(asset: composition) { filteringRequest in
            
            let sourceImg = filteringRequest.sourceImage
            let sourceImgTransf = sourceImg.transformed(by: videoTransform)
            compositeBackFilter.setValue(sourceImgTransf, forKey: kCIInputImageKey)
            
            iphoneOverlayFilter.setValue(compositeBackFilter.outputImage, forKey: kCIInputBackgroundImageKey)
            
            print("sourceImg \(sourceImg.extent)")
//            guard let iphoneOverlayComposite = self.compositeBackground(videoSize: videoTrackSize, sourceVideoImage: sourceImgTransf, renderOptions: renderOptions) else {
//                print("Failed composite"); return
//            }
            progress(filteringRequest.compositionTime.seconds / timeRange.duration.seconds)
            
            // Provide the filter output to the composition
            filteringRequest.finish(with: iphoneOverlayFilter.outputImage!, context: nil)
        }
        
        mutableVideoComposition.renderSize = renderOptions.renderSize
        
        // Set up an AVAssetExportSession to export the composition
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality) else {
            completion(RenderError.failedCreateExportSession)
            return
        }

        exportSession.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 3, preferredTimescale: 600)) //multipliedTimeRange //
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
    
}


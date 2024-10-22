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

enum RenderSelectionElement {
    case phone
    case layer
}


class VideoComposer {
    
    var isRendering: Bool = false
    
    /// (input filter, output filter, text filter)
    func compositeFilter(renderOptions: RenderOptions, videoFrameSize: CGSize) -> (CIFilter, CIFilter, CIFilter?, CIFilter?, CGAffineTransform)? {
        
        let renderSize = renderOptions.renderSize

        /// Back Color generator
        let backColor = CIColor(color: UIColor(renderOptions.backColor))
        let backColorGenerator = CIFilter(name: "CIConstantColorGenerator", parameters: [kCIInputColorKey: backColor])!

        /// Video transform
//        print("Native size \(videoFrameSize)")
        var videoScaleToFit = renderSize.height / videoFrameSize.height
        if renderOptions.selectedFormat == .landscape {
            videoScaleToFit = renderSize.width / videoFrameSize.width
//            if videoFrameSize.height > videoFrameSize.width {
//                videoScaleToFit = renderSize.height / videoFrameSize.height
//            }
        }
        
        let scaleParameter = renderOptions.scaleVideo / 100.0
        let videoAddScale = videoScaleToFit * scaleParameter
        let newVideoSize = CGSize(width: videoFrameSize.width * videoAddScale, height: videoFrameSize.height * videoAddScale)
        let translationX = renderSize.width / 2.0 - newVideoSize.width / 2.0 + renderOptions.offsetX
        let translationY = renderSize.height / 2.0 - newVideoSize.height / 2.0 + renderOptions.offsetY
        let translateToCenterTransform = CGAffineTransform(translationX: translationX, y: translationY)
        let multVideoTransform = CGAffineTransform(scaleX: videoAddScale, y: videoAddScale).concatenating(translateToCenterTransform)
        
        /// Mask Composite with background and masked screen
        let compositeBackColor = CIFilter(name: "CIBlendWithMask")! //CIBlendWithMask //CISourceOverCompositing
        
//        print("Video track size \(videoFrameSize) videoScaleToFit \(videoScaleToFit) videoAddScale \(videoAddScale) newVideoSize \(newVideoSize)")
        
        /// Overlay Image
        guard let iphoneOverlayImg = renderOptions.selectediPhoneOverlay else { print("no overlay"); return nil }
        guard let iphoneOverlay: CIImage =  CIImage(image: iphoneOverlayImg) else { print("error ci overlay"); return nil }

        /// Overlay Transform
        let overlayResizeFit = renderSize.height / iphoneOverlay.extent.height
        let overlayScaleParameter = (renderOptions.scaleVideo * 1.09) / 100.0 //renderOptions.scaleMask / 100
        
//        print("overlays scale \(overlayScaleParameter)")
        let ovlerlayAddedScale = overlayResizeFit * overlayScaleParameter
        let iphoneOverlayResize = CGSize(width: iphoneOverlay.extent.width * ovlerlayAddedScale, height: iphoneOverlay.extent.height * ovlerlayAddedScale)
        
        let iphoneOverlayTransformSize = CGAffineTransform(scaleX: ovlerlayAddedScale, y: ovlerlayAddedScale)
        let iphoneOverlayTranslationX = renderSize.width / 2.0 - iphoneOverlayResize.width / 2.0 + renderOptions.offsetX
        let iphoneOverlayTranslationY = renderSize.height / 2.0 - iphoneOverlayResize.height / 2.0 + renderOptions.offsetY
        
        let befRot = CGAffineTransform(translationX: -iphoneOverlayResize.width / 2.0, y: -iphoneOverlayResize.height / 2.0)
        let aftRot = CGAffineTransform(translationX: iphoneOverlayResize.width / 2.0, y: iphoneOverlayResize.height / 2.0)

        
        let selAnglePhone = renderOptions.selectedFormat == .landscape ? (.pi / 2.0) : 0.0
        let rotationTranf = CGAffineTransformMakeRotation(selAnglePhone)
        
        let allRot = befRot.concatenating(rotationTranf).concatenating(aftRot)
        
        let iphoneOverlayTranslation = CGAffineTransform(translationX: iphoneOverlayTranslationX, y: iphoneOverlayTranslationY)
        let iphoneOverlayTransform = iphoneOverlayTransformSize.concatenating(allRot).concatenating(iphoneOverlayTranslation)
        
        /// Add rotation for scale???

        /// Mask Rounded Rectangle Genrator
        let adjustCorners = 55.0 * overlayScaleParameter
        let roundedRectangleGenerator = CIFilter(name: "CIRoundedRectangleGenerator")!
        let videoTransformedRect = CGRectApplyAffineTransform(CGRect(origin: .zero, size: videoFrameSize), multVideoTransform)
        roundedRectangleGenerator.setValue(videoTransformedRect, forKey: kCIInputExtentKey)
        roundedRectangleGenerator.setValue(CIColor(color: .white), forKey: kCIInputColorKey)
        roundedRectangleGenerator.setValue(adjustCorners, forKey: kCIInputRadiusKey)
        compositeBackColor.setValue(roundedRectangleGenerator.outputImage, forKey: kCIInputMaskImageKey)
        
        ///Shadow for video
        let shadowRoundedRectGenerator = CIFilter(name: "CIRoundedRectangleGenerator")!
        let shadowRescaleX = ovlerlayAddedScale * 0.91
        let shadowRescaleY = ovlerlayAddedScale * 0.94
        let shadowResize = CGSize(width: iphoneOverlay.extent.width * shadowRescaleX, height: iphoneOverlay.extent.height * shadowRescaleY)
        let shadowTranformScale = CGAffineTransform(scaleX: shadowRescaleX, y: shadowRescaleY)
        let shadowTranslationX = renderSize.width / 2.0 - shadowResize.width / 2.0 + renderOptions.shadowOffset.x + renderOptions.offsetX
        let shadowTranslationY = renderSize.height / 2.0 - shadowResize.height / 2.0 + renderOptions.shadowOffset.y + renderOptions.offsetY
        let shadowTranslationTransform = CGAffineTransform(translationX: shadowTranslationX, y: shadowTranslationY)
        
        let shadowRotationTranf = befRot.concatenating(rotationTranf).concatenating(aftRot)
        let shadowAllTransform = shadowTranformScale.concatenating(shadowRotationTranf).concatenating(shadowTranslationTransform)

//        let shadowTranslation = CGAffineTransform(translationX: renderOptions.shadowOffset.x, y: renderOptions.shadowOffset.y)
        let shadowRect = CGRectApplyAffineTransform(iphoneOverlay.extent, shadowAllTransform)
        shadowRoundedRectGenerator.setValue(shadowRect, forKey: kCIInputExtentKey)
        let shadowOpacityScaled = renderOptions.shadowOpacity / 100
        shadowRoundedRectGenerator.setValue(CIColor(color: .black.withAlphaComponent(shadowOpacityScaled)), forKey: kCIInputColorKey)
        shadowRoundedRectGenerator.setValue(adjustCorners * 1.45, forKey: kCIInputRadiusKey)
        
        let shadowBlurFilter = CIFilter(name: "CIGaussianBlur")!
        shadowBlurFilter.setValue(shadowRoundedRectGenerator.outputImage, forKey: kCIInputImageKey)
        shadowBlurFilter.setValue(renderOptions.shadowRadius , forKey: kCIInputRadiusKey)
        
        var outImageRelative: CIImage? = backColorGenerator.outputImage
        
        /// Text layers behind
        for i in 0..<renderOptions.textLayers.count {
            let txtLayerInfo = renderOptions.textLayers[i]
            if txtLayerInfo.zPosition == .infront { continue }
            
            guard let (newLayerComposite, _, _) = textCompositeFilter(renderOptions,
                                                                      txtLayerInfo: txtLayerInfo
            ) else { print("error text filt"); continue; }
            
            newLayerComposite.setValue(outImageRelative!, forKey: kCIInputBackgroundImageKey)
            outImageRelative = newLayerComposite.outputImage
//            print("Composite \(outImageRelative?.extent)")
        }

        /// Back Solid & Shadow & Text
        let backAndShadowComposite = CIFilter(name: "CISourceOverCompositing")! //CIBlendWithMask //CISourceOverCompositing
        backAndShadowComposite.setValue(outImageRelative, forKey: kCIInputBackgroundImageKey)
        backAndShadowComposite.setValue(shadowBlurFilter.outputImage, forKey: kCIInputImageKey)

        compositeBackColor.setValue(backAndShadowComposite.outputImage, forKey: kCIInputBackgroundImageKey)

        /// Composite background with video
        let iphoneOverlayComposite = CIFilter(name: "CISourceOverCompositing")!
        iphoneOverlayComposite.setValue(iphoneOverlay.transformed(by: iphoneOverlayTransform), forKey: kCIInputImageKey)


        //iphoneOverlayComposite
        return (compositeBackColor, iphoneOverlayComposite, nil, nil, multVideoTransform)
    }
    
    
    func fontDict(_ renderOptions: RenderOptions, _ txtLayerInfo: RenderTextLayer) -> [NSAttributedString.Key: Any] {
        
        let layerPos = txtLayerInfo.coordinates
    //    color: UIColor(txtLayerInfo.textColor),
        let fontSize = txtLayerInfo.textFontSize
        let fontWeight = txtLayerInfo.textFontWeight
        let textRotation = txtLayerInfo.textRotation
    //        let fontSize: CGFloat = renderOptions.overlayTextFontSize
    //        let text = renderOptions.overlayText
            let color = UIColor(txtLayerInfo.textColor)
            let fontKern = txtLayerInfo.textKerning
            let tracking = txtLayerInfo.textTrackingStyle
    //        let fontWeight = renderOptions.overlayTextFontWeight
            let paraphStyle = NSMutableParagraphStyle()
            let txtShadowFx = NSShadow()
            txtShadowFx.shadowColor = UIColor(txtLayerInfo.shadowColor).withAlphaComponent(txtLayerInfo.shadowOpacity)
            txtShadowFx.shadowBlurRadius = txtLayerInfo.shadowRadius
            txtShadowFx.shadowOffset = CGSize(width: txtLayerInfo.shadowOffset.x, height: txtLayerInfo.shadowOffset.y)
    //        txtShadowFx.fullscree  = true
            paraphStyle.lineSpacing = txtLayerInfo.textLineSpacing
            
    //        let imgAttach = UIImage(systemName: "xmark")!
    //        let itemAttach = NSTextAttachment(image: imgAttach)
            
            let strkWidth: CGFloat = (txtLayerInfo.textStrokeWidth / 100)
            let strokeColor: UIColor = UIColor(txtLayerInfo.textStrokeColor)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: fontWeight),
                .foregroundColor: color,
    //            .tracking : tracking,
                .kern : fontKern,
                .paragraphStyle : paraphStyle,
                .ligature : 2,
                .strokeWidth: strkWidth, //,
                .strokeColor: strokeColor,
                .strikethroughColor : strokeColor,
                .strikethroughStyle : txtLayerInfo.textStrikeStyle?.rawValue ?? .none, // txtLayerInfo.textStrikeStyle?.rawValue ?? 0,
                .underlineColor: strokeColor,
                .underlineStyle : txtLayerInfo.textUnderlineStyle?.rawValue ?? .none,
                .shadow : txtShadowFx,
                .baselineOffset: tracking,
    //            .attachment : itemAttach
    //            .textEffect : txtLayerInfo.textTrackingEffect?.rawValue ?? []
            ]
            

        return attributes
    }
    
    func textCompositeFilter(_ renderOptions: RenderOptions, txtLayerInfo: RenderTextLayer) -> (CIFilter, CGRect, CGPoint)? {
        
        let layerPos = txtLayerInfo.coordinates
        let text = txtLayerInfo.textString
        let textRotation = txtLayerInfo.textRotation

        let attributes = fontDict(renderOptions, txtLayerInfo)
        //, layerPos: CGPoint, color: UIColor, fontSize: CGFloat, fontWeight: UIFont.Weight, textRotation: CGFloat
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Create a CIImage from the attributed string
        let textGenerator = CIFilter(name: "CIAttributedTextImageGenerator")
        textGenerator?.setValue(attributedString, forKey: "inputText")
        textGenerator?.setValue(3, forKey: "inputScaleFactor")
        
        guard let textImage = textGenerator?.outputImage else { print("error text"); return nil }
//        print("extent text \(textImage.extent)")
        let textComposite = CIFilter(name: "CISourceOverCompositing")! //CIBlendWithMask //CISourceOverCompositing

        let translateCenterX = renderOptions.renderSize.width / 2 - textImage.extent.width / 2.0
        let translateCenterY = renderOptions.renderSize.height / 2 - textImage.extent.height / 2.0
        let posRelToAbs = CGPoint(x: layerPos.x * renderOptions.renderSize.width * 1.0, y: (1.0 - layerPos.y) * renderOptions.renderSize.height * 1.0)
//        print("Layer pos \(layerPos.x) \(layerPos.y) posRelToAbs \(posRelToAbs)")

        let translateText = CGAffineTransform(translationX: posRelToAbs.x, y: posRelToAbs.y )
        let textCenterBeforeRot = CGAffineTransform(translationX: -textImage.extent.width/2.0, y: -textImage.extent.height/2.0)
        let textAutoPositiveCenter = CGAffineTransform(translationX: textImage.extent.width/2.0, y: textImage.extent.height/2.0)
        let rotationTransform = textCenterBeforeRot.concatenating(CGAffineTransform(rotationAngle: textRotation * .pi / 180).concatenating(textAutoPositiveCenter))
        
        let allTransform = rotationTransform.concatenating(translateText).concatenating(textCenterBeforeRot) //translateText.conca.concatenating(textCenterBeforeRot) //
        // Set as Input
        textComposite.setValue(textImage.transformed(by: allTransform), forKey: kCIInputImageKey)

        return (textComposite,  CGRect(origin: .init(x: posRelToAbs.x, y: posRelToAbs.y), size: textImage.extent.size), posRelToAbs)
    }
    
    
    func createImagePreview(_ screenImage: UIImage, renderOptions: RenderOptions, selected: RenderSelectionElement? = nil, renderCustomCodeByKey:  [String: Data]) -> UIImage? {
        
        let renderSize = renderOptions.renderSize
        let videoTrackSize = screenImage.size
        let sourceVideoImage = CIImage(image: screenImage)!
//        print("Video track size \(videoTrackSize)")
        guard let (compositeBackFilter, iphoneOverlayFilter, _, _, videoTransform) = self.compositeFilter(renderOptions: renderOptions, videoFrameSize: videoTrackSize) else { return nil }
        
        let sourceCI = sourceVideoImage.transformed(by: videoTransform)
        compositeBackFilter.setValue(sourceCI, forKey: kCIInputImageKey)
        iphoneOverlayFilter.setValue(compositeBackFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        
        let lastFilter: CIFilter? = iphoneOverlayFilter
        var outImageRelative = lastFilter?.outputImage
        var selExtent: CGRect?
        var offS: CGPoint?
        
//        let renderCustomCodeByKey: [String: Data] = [:]
        
        let allKeys: [String] = Array(renderCustomCodeByKey.keys)
        
        print("Called preview ")
        
        /// After device layers
        for i in 0..<renderOptions.textLayers.count {
            
            let isSelIdx: Bool = AppState.shared.selIdx == i
            
//            print("Is sel \(isSelIdx)")
            let txtLayerInfo = renderOptions.textLayers[i]
            
            if txtLayerInfo.zPosition == .behind {
                print("Step continue but select if selected")
                if isSelIdx {
                    guard let (_, ext, off) = textCompositeFilter(renderOptions, txtLayerInfo: txtLayerInfo ) else { print("error text filt"); continue; }
                    print("Sel idx \(AppState.shared.selIdx) size \(ext.size) coord \(txtLayerInfo.coordinates) selIdx \(isSelIdx)")
                    selExtent = CGRect(origin: .init(x: txtLayerInfo.coordinates.x, y: txtLayerInfo.coordinates.y), size: ext.size)
                    offS = off
                    AppState.shared.selTextExt = selExtent
                }
                
                continue
            }
            
            //Replace custom codes with images
            let textStr = txtLayerInfo.textString
            let containsInCode = allKeys.contains(textStr)
            
            /// Replace with image pre-order and custom images
            if textStr == "/pa" || textStr == "/pab" || textStr == "/app" || textStr == "/apb" || containsInCode {
                
                let combineImg = CIFilter(name: "CISourceOverCompositing")! //CIBlendWithMask //CISourceOverCompositing
                var appPreImgURL = Bundle.main.url(forResource: "pre4", withExtension: "png")!
                if textStr == "/pab" {
                    appPreImgURL = Bundle.main.url(forResource: "preb", withExtension: "png")!
                }
                else if textStr == "/app" {
                    appPreImgURL = Bundle.main.url(forResource: "appdwnld", withExtension: "png")!
                }
                else if textStr == "/apb" {
                    appPreImgURL = Bundle.main.url(forResource: "appb", withExtension: "png")!
                }
                
                let appPreImg: UIImage = containsInCode ? UIImage(data: renderCustomCodeByKey[textStr]!)! : UIImage(contentsOfFile: appPreImgURL.path)!
                
                let preCIImg: CIImage =  CIImage(image: appPreImg)!
                
                let layerPos = txtLayerInfo.coordinates
                let posRelToAbs = CGPoint(x: layerPos.x * renderOptions.renderSize.width * 1.0, y: (1.0 - layerPos.y) * renderOptions.renderSize.height * 1.0)

                var scaledImgToFit = 0.3
                if containsInCode {
                    scaledImgToFit = txtLayerInfo.transformScale / 100.0
                }

                let textCenterBeforeRot = CGAffineTransform(translationX: -(preCIImg.extent.width*scaledImgToFit)/2.0, y: -(preCIImg.extent.height*scaledImgToFit)/2.0)
                
                let transfSize = CGSize(width: preCIImg.extent.width * scaledImgToFit, height: preCIImg.extent.height * scaledImgToFit)
                let allTranslation = textCenterBeforeRot.concatenating(.init(translationX: posRelToAbs.x, y: posRelToAbs.y))

                let allTransf = CGAffineTransform(scaleX: scaledImgToFit, y: scaledImgToFit).concatenating(allTranslation)
                combineImg.setValue(preCIImg.transformed(by: allTransf), forKey: kCIInputImageKey )
                combineImg.setValue(outImageRelative, forKey: kCIInputBackgroundImageKey)

                outImageRelative = combineImg.outputImage
                
                if selected == .layer {
                    if isSelIdx {
                        selExtent = CGRect(origin: .init(x: layerPos.x, y: layerPos.y), size: transfSize)
                        print("Sel sel \(posRelToAbs)")
                        offS = posRelToAbs
                        AppState.shared.selTextExt = selExtent
                    }
                }
                
            } else {
                
                /// Text composite
                guard let (newLayerComposite, ext, off) = textCompositeFilter(renderOptions,
                                                                              txtLayerInfo: txtLayerInfo
                ) else { print("error text filt"); continue; }
                
                newLayerComposite.setValue(outImageRelative, forKey: kCIInputBackgroundImageKey)
                
                outImageRelative = newLayerComposite.outputImage
                
                if selected == .layer {
                    if isSelIdx {
//                        print("Sel size \(ext.size) coord \(txtLayerInfo.coordinates)")
                        selExtent = CGRect(origin: .init(x: txtLayerInfo.coordinates.x, y: txtLayerInfo.coordinates.y), size: ext.size)
                        offS = off
                        AppState.shared.selTextExt = selExtent
                        print("off set from after layer \(off) \(AppState.shared.selIdx) i \(i) isSelIdx \(isSelIdx)")
                    }
                }
                
            }
            

        }
        
        if selected == .phone {
            selExtent = sourceCI.extent
        }
        
//        print("selExtent \(selExtent)")
        
        var outputCImg: CIImage? = outImageRelative
        
//        let selForVal = true
        
        if selected != nil {
            
            let addRectForSelComposite = CIFilter(name: "CISourceOverCompositing")!
            
            var roundedGenFilterName = "CIRoundedRectangleGenerator"
            if #available(iOS 17, *) {
                roundedGenFilterName = "CIRoundedRectangleStrokeGenerator"
            }
            
            if let roundedRectangleGenerator = CIFilter(name: roundedGenFilterName) {
                
                let insetVal: CGFloat = -30.0
                var alphaForSelected = 0.25
                if #available(iOS 17, *) {
                    alphaForSelected = 1.0
                }

                let centeredInsetRect = selExtent?.insetBy(dx: selected == .phone ? insetVal : 0.0, dy: selected == .phone ? insetVal : 0)
                roundedRectangleGenerator.setValue(centeredInsetRect ?? .zero, forKey: kCIInputExtentKey)
                roundedRectangleGenerator.setValue(CIColor(color:selected == .phone ? .orange.withAlphaComponent(alphaForSelected) : .clear), forKey: kCIInputColorKey)
                roundedRectangleGenerator.setValue(8.0, forKey: kCIInputRadiusKey)
                if #available(iOS 17, *) {
                    roundedRectangleGenerator.setValue(4.0, forKey: kCIInputWidthKey)
                }
                
                /// Back
                addRectForSelComposite.setValue(outImageRelative, forKey: kCIInputBackgroundImageKey  )
                
                let scaleVal = 1.0
                print("translate \(offS) for idx \(AppState.shared.selIdx)")
                let transfoOut: CGAffineTransform = .init(translationX: (offS?.x ?? 0) - ((selExtent?.width ?? 0.0) * scaleVal) / 2.0,
                                                         y: (offS?.y ?? 0) - ((selExtent?.height ?? 0.0) * scaleVal) / 2.0 )
                
                let transTo = selected == .phone ? .identity : selected == .layer ? transfoOut : .identity //.concatenating(transfoOut)
                
                /// Sel frame
                addRectForSelComposite.setValue(
                    roundedRectangleGenerator.outputImage?.transformed(by: transTo), //?.transformed(by: transTo),
                    forKey: kCIInputImageKey )
            }

            outputCImg = addRectForSelComposite.outputImage

        }
        

        
        guard let outputCI = outputCImg else { print("error last filter"); return nil }

        let context = CIContext()
        let cgOutputImage = context.createCGImage(outputCI, from: .init(origin: .zero, size: renderSize))!
        
        return UIImage(cgImage: cgOutputImage)

    }
    
    func createCompositionOnlyForPreview(videoURL: URL, outputURL: URL, renderOptions: RenderOptions, renderCustomCodeByKey: [String: Data], progress:@escaping (CGFloat)->(), completion: @escaping (AVPlayerItem?, Error?) -> Void) {
        let startRenderTime = Date()
        
//        print("Did set with keys \(renderCustomCodeByKey)")
        compositionSet(videoURL: videoURL, outputURL: outputURL, renderOptions: renderOptions, renderCustomCodeByKey: renderCustomCodeByKey, progress: progress) { compoPair, errorOrNil in
            guard let (composition, videoComposition, timeRange) = compoPair else {
                completion(nil, RenderError.failedCreateComposite)
                return
            }

//            let snapshot = composition.copy() as! AVMutableComposition
            let playerItem = AVPlayerItem(asset: composition)
            playerItem.videoComposition = videoComposition
            completion(playerItem, nil)
        }
    }
    
    func createAndExportComposition(videoURL: URL, outputURL: URL, renderOptions: RenderOptions, renderCustomCodeByKey: [String: Data], progress:@escaping (CGFloat)->(), completion: @escaping (Error?) -> Void) {
        
        let startRenderTime = Date()
        self.isRendering = true
        
        compositionSet(videoURL: videoURL, outputURL: outputURL, renderOptions: renderOptions, renderCustomCodeByKey: renderCustomCodeByKey, progress: progress) { compoPair, errorOrNil in
            
            guard let (composition, videoComposition, timeRange) = compoPair else {
                completion(RenderError.failedCreateComposite)
                return
            }
//            guard let composition else {
//                completion(RenderError.failedCreateComposite)
//                return
//            }
            // Set up an AVAssetExportSession to export the composition
            //AVAssetExportPresetMediumQuality
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                completion(RenderError.failedCreateExportSession)
                return
            }

            exportSession.timeRange = timeRange // multipliedTimeRange //CMTimeRange(start: .zero, duration: CMTime(seconds: 3, preferredTimescale: 600)) //multipliedTimeRange //
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.videoComposition = videoComposition
            
    //        let snap = composition.copy()
    //        let newPlayerItem = AVPlayerItem(asset: snap as! AVMutableComposition)
            
            // Perform the export
            exportSession.exportAsynchronously {
                
                self.isRendering = false
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
    
    func compositionSet(videoURL: URL, outputURL: URL, renderOptions: RenderOptions, renderCustomCodeByKey:  [String: Data], progress:@escaping (CGFloat)->(), completion: @escaping ((AVMutableComposition, AVMutableVideoComposition, CMTimeRange)?, Error?) -> Void) -> Void {
        
        
        // Create an AVMutableComposition
        let composition = AVMutableComposition()
        
        // Create video and audio tracks in our composition
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil, RenderError.failedCompositionTrack)
            return
        }

        //Delete file if exists
//        try? FileManager.default.removeItem(at: outputURL)
        
        // Load your video and audio assets
        let videoAsset = AVURLAsset(url: videoURL)
        
        // Get the first video and audio tracks from your assets
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            completion(nil, RenderError.failedFetchAssetTrack)
            return
        }
        
        var compositionAudioTrack: AVMutableCompositionTrack?
        let audioTrack = videoAsset.tracks(withMediaType: .audio).first
        if audioTrack != nil {
            compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        }
        
        // Define the time range for the entire video
        let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
        let timeSpeedDivider = renderOptions.videoSpeed / 100 /// 4.0
        let multipliedTimeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: videoAsset.duration.seconds / timeSpeedDivider, preferredTimescale: timeRange.duration.timescale) )
        
        do {
            // Add the video track to the composition
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
            //CMTime(seconds: videoAsset.duration.seconds / timeSpeedMultiplier, preferredTimescale: timeRange.duration.timescale)
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            compositionVideoTrack.scaleTimeRange(timeRange, toDuration: multipliedTimeRange.duration)
            if let audioTrack, let compositionAudioTrack {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
                compositionAudioTrack.scaleTimeRange(timeRange, toDuration: multipliedTimeRange.duration)
            }
        } catch {
            completion(nil, error)
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
        
        guard let (compositeBackFilter, iphoneOverlayFilter, textFilter, lastTextF, videoTransform) = self.compositeFilter(renderOptions: renderOptions, videoFrameSize: videoTrackSize) else {
            completion(nil, RenderError.failedCreateComposite)
            return
        }
        
        let allKeys: [String] = Array(renderCustomCodeByKey.keys)
        print("render with keys \(allKeys)")
        
//        print("Video natural size \(videoTrackSize) videoTransform \(videoTransform) videoPrefferedTransform \(videoPreferredTransform)")
        let mutableVideoComposition = AVMutableVideoComposition(asset: composition) { filteringRequest in
            
            let sourceImg = filteringRequest.sourceImage
            let sourceImgTransf = sourceImg.transformed(by: videoTransform)
            compositeBackFilter.setValue(sourceImgTransf, forKey: kCIInputImageKey)
            
            iphoneOverlayFilter.setValue(compositeBackFilter.outputImage, forKey: kCIInputBackgroundImageKey)
            
            var lastFilter: CIFilter? = iphoneOverlayFilter
            
            /// Overlay layers
            var outImageRelative = lastFilter?.outputImage
            
            //Replace custom codes with images
            for i in 0..<renderOptions.textLayers.count {
                
                let txtLayerInfo = renderOptions.textLayers[i]
                let textStr = txtLayerInfo.textString
                let containsInCode = allKeys.contains(textStr)
//                print("contains in code\(containsInCode)")

                if txtLayerInfo.zPosition == .behind { continue }
                
                if textStr == "/pa" || textStr == "/pab" || textStr == "/app" || textStr == "/apb" || containsInCode {
                    
                    let combineImg = CIFilter(name: "CISourceOverCompositing")! //CIBlendWithMask //CISourceOverCompositing
                    var appPreImgURL = Bundle.main.url(forResource: "pre4", withExtension: "png")!
                    if textStr == "/pab" {
                        appPreImgURL = Bundle.main.url(forResource: "preb", withExtension: "png")!
                    }
                    else if textStr == "/app" {
                        appPreImgURL = Bundle.main.url(forResource: "appdwnld", withExtension: "png")!
                    }
                    else if textStr == "/apb" {
                        appPreImgURL = Bundle.main.url(forResource: "appb", withExtension: "png")!
                    }
                    
                    let appPreImg: UIImage = containsInCode ? UIImage(data: renderCustomCodeByKey[textStr]!)! : UIImage(contentsOfFile: appPreImgURL.path)!

//                    let appPreImg = UIImage(contentsOfFile: appPreImgURL.path)!
                    let preCIImg: CIImage =  CIImage(image: appPreImg)!
                    
                    let layerPos = txtLayerInfo.coordinates
                    let posRelToAbs = CGPoint(x: layerPos.x * renderOptions.renderSize.width * 1.0, y: (1.0 - layerPos.y) * renderOptions.renderSize.height * 1.0)

                    var scaledImgToFit = 0.3
                    if containsInCode {
                        scaledImgToFit = txtLayerInfo.transformScale / 100.0
                    }
                    let textCenterBeforeRot = CGAffineTransform(translationX: -(preCIImg.extent.width*scaledImgToFit)/2.0, y: -(preCIImg.extent.height*scaledImgToFit)/2.0)
                    
                    let transfSize = CGSize(width: preCIImg.extent.width * scaledImgToFit, height: preCIImg.extent.height * scaledImgToFit)
                    let allTranslation = textCenterBeforeRot.concatenating(.init(translationX: posRelToAbs.x, y: posRelToAbs.y))

                    let allTransf = CGAffineTransform(scaleX: scaledImgToFit, y: scaledImgToFit).concatenating(allTranslation)
                    combineImg.setValue(preCIImg.transformed(by: allTransf), forKey: kCIInputImageKey )
                    combineImg.setValue(outImageRelative, forKey: kCIInputBackgroundImageKey)

                    outImageRelative = combineImg.outputImage
                    
                } else {
                    guard let (newLayerComposite, _, _) = self.textCompositeFilter(renderOptions,
                                                                                   txtLayerInfo: txtLayerInfo
                    ) else { print("error text filt"); continue; }
                    
                    newLayerComposite.setValue(outImageRelative, forKey: kCIInputBackgroundImageKey)
                    outImageRelative = newLayerComposite.outputImage
                }
            }

//            print("sourceImg \(sourceImg.extent)")
            progress(filteringRequest.compositionTime.seconds / multipliedTimeRange.duration.seconds)
            
            // Provide the filter output to the composition
            filteringRequest.finish(with: outImageRelative ?? sourceImg, context: nil)
        }
        
        mutableVideoComposition.renderSize = renderOptions.renderSize

        completion((composition, mutableVideoComposition, multipliedTimeRange),  nil)
    }
    
}


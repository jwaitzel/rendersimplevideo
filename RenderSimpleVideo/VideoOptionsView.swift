//
//  VideoOptionsView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/10/24.
//

import SwiftUI

struct VideoOptionsView: View {
    
    let uiImg = UIImage(contentsOfFile: Bundle.main.url(forResource: "screencap1", withExtension: "jpg")!.path)!

    @State private var screenFiltered: UIImage?
    
    /// Video Properties
    @State private var backColor: Color = .green
    
    @State private var offsetX: CGFloat = 0.0
    @State private var offsetY: CGFloat = 0.0
    
    @State private var scaleVideo: CGFloat = 100.0
    
    @State private var timer: Timer?
    
//    var totalOff: CGFloat {
//        offsetX //+ dragOffsetX
//    }
    
    var body: some View {
        VStack {
            HStack {
//                Image(uiImage: uiImg)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 200)
//                    .border(.black)
                
                if let appImg = self.screenFiltered {
                    Image(uiImage: appImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300)
                        .border(.black)
                }
            }
            
            
//            Button("Apply") {
//                applyFilters()
//            }
//            .buttonStyle(.borderedProminent)
            
            Group {
                ColorPicker(selection: $backColor, label: {
                    Text("Back Color")
                        .frame(width: 120, alignment: .trailing)
                })
                                    
                BlenderStyleInput(value: $offsetX, title: "Position X")
                
                BlenderStyleInput(value: $offsetY, title: "Y")
                
                BlenderStyleInput(value: $scaleVideo, title: "Scale Video")
            }
//            .border(.green)
            .padding(.horizontal, 16)
            
        }
        .onAppear {
            print("onAppear")
//            UISlider.appearance().thumbTintColor = UIColor.orange
            UISlider.appearance().maximumTrackTintColor = UIColor.systemGray5
            UISlider.appearance().minimumTrackTintColor = UIColor.systemGray5
            
            applyFilters()
            
//            timer = Timer.scheduledTimer(withTimeInterval: 1 / 10, repeats: true, block: { _ in
//                applyFilters()
//            })
        }
        .onChange(of: (offsetX + offsetY + scaleVideo)) { _ in
            applyFilters()
        }
        .onChange(of: backColor) { _ in
            applyFilters()
        }

    }
    
    func applyFilters() {
        
        let sqRenderSize: CGFloat = 1024
        let renderSize: CGSize = CGSize(width: sqRenderSize, height: sqRenderSize)

        let videoTrackSize = uiImg.size
        
        let videoScaleToFit = renderSize.height / videoTrackSize.height
        let scaleParameter = scaleVideo / 100.0
        let videoAddScale = videoScaleToFit * scaleParameter
        let newVideoSize = CGSize(width: videoTrackSize.width * videoAddScale, height: videoTrackSize.height * videoAddScale)
        let translationX = renderSize.width / 2.0 - newVideoSize.width / 2.0 + self.offsetX
        let translationY = renderSize.height / 2.0 - newVideoSize.height / 2.0 + self.offsetY
        print("Video track size \(videoTrackSize) videoScaleToFit \(videoScaleToFit) videoAddScale \(videoAddScale) newVideoSize \(newVideoSize)")
        
        let translateToCenterTransform = CGAffineTransform(translationX: translationX, y: translationY)
        let multVideoTransform = CGAffineTransform(scaleX: videoAddScale, y: videoAddScale).concatenating(translateToCenterTransform)


        let backColor = CIColor(color: UIColor(backColor))
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
        let iphoneOverlayTranslationX = renderSize.width / 2.0 - iphoneOverlayResize.width / 2.0 + self.offsetX
        let iphoneOverlayTranslationY = renderSize.height / 2.0 - iphoneOverlayResize.height / 2.0 + self.offsetY
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

        let sourceCI = CIImage(image: uiImg)!
        let source = sourceCI.transformed(by: multVideoTransform).cropped(to: sourceCI.extent)
        compositeColor.setValue(source, forKey: kCIInputImageKey)
        iphoneOverlayComposite.setValue(compositeColor.outputImage, forKey: kCIInputBackgroundImageKey)
        
        let outputCI = iphoneOverlayComposite.outputImage!

        let context = CIContext()
        let cgOutputImage = context.createCGImage(outputCI, from: .init(origin: .zero, size: renderSize))!

        
        self.screenFiltered = UIImage(cgImage: cgOutputImage)
        
    }
}

#Preview {
    VideoOptionsView()
}

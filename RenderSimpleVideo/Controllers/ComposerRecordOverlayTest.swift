//
//  ComposerRecordOverlayTest.swift
//  RenderSimpleVideo
//
//  Created by javi www on 10/10/24.
//

import SwiftUI

var overlayContentFrame: CGSize = .init(width: 440, height: 300)//.init(width: 440, height: 300)
var containerFrame: CGSize = .init(width: 393, height: 852)

class LoopManager: ObservableObject {
    
    @Published var timePassed: CGFloat = 0.0
    var startDate: Date = .now
    
    @Published var composedImage: UIImage?

    var colorTime: CGFloat = 0
    var colorForTime: UIColor = .red
    var lastFrameDate: Date = .now
    
    
    private var meterDisplayLink: CADisplayLink?

    fileprivate func installDisplayLink() {
        meterDisplayLink = CADisplayLink(target: self, selector: #selector(updateMeter))
        meterDisplayLink?.preferredFramesPerSecond = 15
        meterDisplayLink?.add(to: .current, forMode: .common)
    }
    
    fileprivate func uninstallDisplayLink() {
        if let displayLink = meterDisplayLink {
            displayLink.remove(from: .current, forMode: .common)
            displayLink.invalidate()
            meterDisplayLink = nil
        }
    }
    
    @objc
    private func updateMeter() {
        let diff = Date().timeIntervalSince(startDate)
        self.timePassed = diff
        
        let frameDiff = Date().timeIntervalSince(lastFrameDate)
        self.colorTime += frameDiff
        colorForTime = self.newColorForTimeUpdated()
        lastFrameDate = .now
//        if diff.truncatingRemainder(dividingBy: 1) == 0 {
//            
//        }
        self.composeShadowImage()
    }
    
    func newColorForTimeUpdated() -> UIColor {
        
        let timeF = self.colorTime / 1.0
        var col = UIColor.blue.interpolateRGBColorTo(UIColor.orange, fraction: timeF)
        if colorTime > 1 {
            let valHalf = (colorTime - 1.0) / 1.0
            col = UIColor.orange.interpolateRGBColorTo(UIColor.blue, fraction: valHalf)
        }
        if colorTime > 2 {
            colorTime = 0
        }
        return col ?? .yellow
    }
    
    func composeShadowImage() {
        
        let backColor = CIColor(color: UIColor.orange.withAlphaComponent(0))
        let backColorGenerator = CIFilter(name: "CIConstantColorGenerator", parameters: [kCIInputColorKey: backColor])!
        
        let scaleToSeeBetterr: CGFloat = 1.0
        let capsuleFrameRect = CGRect(x: containerFrame.width * 0.1, y: containerFrame.height-10, width: 10, height: 10.0)
//        let adjustCorners = 105.0
        
        let shadowRoundedRectGenerator = CIFilter(name: "CIRoundedRectangleGenerator")!
        shadowRoundedRectGenerator.setValue(capsuleFrameRect, forKey: kCIInputExtentKey)
        shadowRoundedRectGenerator.setValue(CIColor(color: colorForTime.withAlphaComponent(1.0)), forKey: kCIInputColorKey)
        shadowRoundedRectGenerator.setValue(capsuleFrameRect.height/2.0, forKey: kCIInputRadiusKey)
        
//        let blurFilter = CIFilter(name: "CIGaussianBlur")!
//        blurFilter.setValue(shadowRoundedRectGenerator.outputImage, forKey: kCIInputImageKey)
//        blurFilter.setValue(0, forKey: kCIInputRadiusKey)
//
        let compositeBackColor = CIFilter(name: "CISourceOverCompositing")! //CIBlendWithMask //CISourceOverCompositing
        compositeBackColor.setValue(backColorGenerator.outputImage, forKey: kCIInputBackgroundImageKey)
        compositeBackColor.setValue(shadowRoundedRectGenerator.outputImage, forKey: kCIInputImageKey)
        
        let fontSize: CGFloat = 34 * scaleToSeeBetterr
        let minutes = Int(timePassed / 60)
        let timePassString = String(format: "%i:%.2f", minutes, timePassed)
        let text = "4:20"
        let color = UIColor.white.withAlphaComponent(1.0)
        let mutParStyle = NSMutableParagraphStyle()
//        mutParStyle.alignment = .right
//        mutParStyle.baseWritingDirection = .leftToRight
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: color,
            .paragraphStyle : mutParStyle
        ]
        var attributedString = NSMutableAttributedString(string: timePassString, attributes: attributes)
        let boundingFittingText = attributedString.boundingRect(with: CGSize(width: 9999, height: 999), context: nil)
        print("Rect sie \(boundingFittingText)")
        // Create a CIImage from the attributed string
        let textGenerator = CIFilter(name: "CIAttributedTextImageGenerator")
        textGenerator?.setValue(attributedString, forKey: "inputText")
        textGenerator?.setValue(1.0, forKey: "inputScaleFactor")
        
        guard let textImage = textGenerator?.outputImage else { return }
//        print("extent text \(textImage.extent)")
        let textComposite = CIFilter(name: "CISourceOverCompositing")! //CIBlendWithMask //CISourceOverCompositing
        textComposite.setValue(compositeBackColor.outputImage, forKey: kCIInputBackgroundImageKey)
        
        let translateText = CGAffineTransform(translationX: (overlayContentFrame.width / 2.0) - (boundingFittingText.width / 2.0) , y: (overlayContentFrame.height / 2.0) - (boundingFittingText.height / 2.0))
        textComposite.setValue(textImage.transformed(by: translateText), forKey: kCIInputImageKey)
        
        let outputCI = textComposite.outputImage!

        let renderSize = containerFrame
        let context = CIContext()
        let cgOutputImage = context.createCGImage(outputCI, from: .init(origin: .zero, size: renderSize))!
        
        self.composedImage = UIImage(cgImage: cgOutputImage)

    }

}



struct ComposerRecordOverlayTest: View {
    
    @ObservedObject var loopManager: LoopManager = .init()

    var body: some View {
        
        ZStack {
            if let composedImage = loopManager.composedImage {
                Image(uiImage: composedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: containerFrame.width, height: containerFrame.height)
                    .ignoresSafeArea()
//                    .scaleEffect(2)
            }
            
//            Button {
//                loopManager.composeShadowImage()
//            } label: {
//                Text("Compose")
//            }
//            .buttonStyle(.borderedProminent)
//            .offset(y: 100)
        }
        .ignoresSafeArea()
        .border(.red)
        .onAppear {
            let _ = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { _ in
                loopManager.composeShadowImage()
            }
            
            let screenSize = UIScreen.main.bounds.size
            print("Screen size \(screenSize)")
//            loopManager.installDisplayLink()
        }
        .onDisappear {
//            loopManager.uninstallDisplayLink()
        }
        
    }
    
    

}

extension UIColor {
    func interpolateRGBColorTo(_ end: UIColor, fraction: CGFloat) -> UIColor? {
        let f = min(max(0, fraction), 1)

        guard let c1 = self.cgColor.components, let c2 = end.cgColor.components else { return nil }

        let r: CGFloat = CGFloat(c1[0] + (c2[0] - c1[0]) * f)
        let g: CGFloat = CGFloat(c1[1] + (c2[1] - c1[1]) * f)
        let b: CGFloat = CGFloat(c1[2] + (c2[2] - c1[2]) * f)
        let a: CGFloat = CGFloat(c1[3] + (c2[3] - c1[3]) * f)

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}


#Preview {
    ComposerRecordOverlayTest()
}

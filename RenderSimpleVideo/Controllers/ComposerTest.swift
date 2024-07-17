//
//  ComposerTest.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/17/24.
//

import SwiftUI

struct ComposerTest: View {
    
    @State private var composedImage: UIImage?
    var body: some View {
        
        VStack {
            if let composedImage {
                Image(uiImage: composedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
            }
            
            Button {
                self.composeShadowImage()
            } label: {
                Text("Compose")
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.composeShadowImage()
            }
        }
        
    }
    
    func composeShadowImage() {
        
        let backColor = CIColor(color: UIColor.red)
        let backColorGenerator = CIFilter(name: "CIConstantColorGenerator", parameters: [kCIInputColorKey: backColor])!

        
        let shadowRoundedRectFrame = CGRect(x: 300, y: 90, width: 400, height: 800)
        let adjustCorners = 105.0
        
        let shadowRoundedRectGenerator = CIFilter(name: "CIRoundedRectangleGenerator")!
        shadowRoundedRectGenerator.setValue(shadowRoundedRectFrame, forKey: kCIInputExtentKey)
        shadowRoundedRectGenerator.setValue(CIColor(color: .black.withAlphaComponent(1.0)), forKey: kCIInputColorKey)
        shadowRoundedRectGenerator.setValue(adjustCorners, forKey: kCIInputRadiusKey)
        
        let blurFilter = CIFilter(name: "CIGaussianBlur")!
        blurFilter.setValue(shadowRoundedRectGenerator.outputImage, forKey: kCIInputImageKey)
        blurFilter.setValue(80, forKey: kCIInputRadiusKey)

        let compositeBackColor = CIFilter(name: "CISourceOverCompositing")! //CIBlendWithMask //CISourceOverCompositing
        compositeBackColor.setValue(backColorGenerator.outputImage, forKey: kCIInputBackgroundImageKey)
        compositeBackColor.setValue(blurFilter.outputImage, forKey: kCIInputImageKey)
        
        let outputCI = compositeBackColor.outputImage!

        let renderSize = CGSize(width: 1024, height: 1024)
        let context = CIContext()
        let cgOutputImage = context.createCGImage(outputCI, from: .init(origin: .zero, size: renderSize))!
        
        self.composedImage = UIImage(cgImage: cgOutputImage)

    }
}

#Preview {
    ComposerTest()
}

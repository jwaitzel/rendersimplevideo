//
//  VideoOptionsView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/10/24.
//

import SwiftUI

struct VideoOptionsView: View {
    
    let videoComposer = VideoComposer()
    
    var screenImage: UIImage
        
    @EnvironmentObject var renderOptions: RenderOptions
    
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            if let appImg = self.renderOptions.selectedFiltered {
                Image(uiImage: appImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 4.0, x: 0, y: 3)
                    .padding(.bottom, 24)
            }
            
            Group {
                ColorPicker(selection: $renderOptions.backColor, label: {
                    Text("Back Color")
                        .frame(width: 120, alignment: .trailing)
                })
                .onTapGesture {}
                                    
                BlenderStyleInput(value: $renderOptions.offsetX, title: "Position X")
                
                BlenderStyleInput(value: $renderOptions.offsetY, title: "Y")
                
                BlenderStyleInput(value: $renderOptions.scaleVideo, title: "Scale Video", unitStr: "%", unitScale: 0.1)
                
                
//                BlenderStyleInput(value: $offsetMask.x, title: "Mask X", unitStr: "px", unitScale: 1)
//
//                BlenderStyleInput(value: $offsetMask.y, title: "Y", unitStr: "px", unitScale: 1)
//
//                BlenderStyleInput(value: $renderOptions.scaleMask, title: "Scale iPhone", unitStr: "%", unitScale: 0.1)
//
//                BlenderStyleInput(value: $maskCorners, title: "Mask Corners", unitStr: "px")

                HStack {
                    Text("iPhone Color")
                        .frame(width: 120, alignment: .trailing)
                    
                    Picker("", selection: $renderOptions.selectediPhoneColor) {
                        ForEach(0..<iPhoneColorOptions.allCases.count, id: \.self) { idx in
                            let iPhoneColor = iPhoneColorOptions.allCases[idx]
                            Text(iPhoneColor.rawValue)
                                .tag(iPhoneColor)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: renderOptions.selectediPhoneColor) { newVal in
                        renderOptions.selectediPhoneOverlay = newVal.image()
                        self.applyFilters()
                    }
                }
                

                    

            }
            .padding(.horizontal, 16)
            
        }
        .onAppear {
            print("onAppear")
            applyFilters()
        }
        .onChange(of: (renderOptions.offsetX + renderOptions.offsetY + renderOptions.scaleVideo + renderOptions.maskCorners + renderOptions.scaleMask)) { _ in
            applyFilters()
        }
        .onChange(of: renderOptions.backColor) { _ in
            applyFilters()
        }

    }
    
    func applyFilters() {
        if let filteredImg = videoComposer.createImagePreview(self.screenImage, renderOptions: self.renderOptions) {
//            self.screenFiltered = filteredImg
            self.renderOptions.selectedFiltered = filteredImg
        }
    }
}

#Preview {
    struct PreviewData: View {
        let img = UIImage(contentsOfFile: Bundle.main.url(forResource: "screencap1", withExtension: "jpg")!.path)!
        let renderOptions = RenderOptions()
        var body: some View {
            VideoOptionsView(screenImage: img)
                .environmentObject(renderOptions)
        }
    }
    
    return PreviewData()
}

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
        
    enum OptionsGroup: String, CaseIterable {
        case Video
        case Text
        case Shadow
    }
    
    @AppStorage("optionsGroup") var optionsGroup: OptionsGroup = .Video
    
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
            
            
            Picker("", selection: $optionsGroup) {
                ForEach(0..<OptionsGroup.allCases.count, id: \.self) { idx in
                    let iPhoneColor = OptionsGroup.allCases[idx]
                    Text(iPhoneColor.rawValue)
                        .tag(iPhoneColor)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            
            VStack(spacing: 16) {
                
                switch self.optionsGroup {
//                case .Background:
//                    BackgroundOptionsView()
                case .Video:
                    VideoOptionsView()
                case .Shadow:
                    ShadowOptionsView()
                case .Text:
                    TextOptionsView()
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .border(.clear)
            
        }
        .onAppear {
            print("onAppear")
            applyFilters()
        }
        .onChange(of: (renderOptions.offsetX + renderOptions.offsetY + renderOptions.scaleVideo + renderOptions.maskCorners + renderOptions.scaleMask + renderOptions.shadowOffset.x + renderOptions.shadowOffset.y + renderOptions.shadowRadius + renderOptions.shadowOpacity + renderOptions.overlayTextOffset.x + renderOptions.overlayTextOffset.y + renderOptions.overlayTextFontSize)) { _ in
            applyFilters()
        }
//        .onChange(of: renderOptions, perform: { value in
//            applyFilters()
//        })
        .onChange(of: renderOptions.backColor) { _ in
            applyFilters()
        }
        .onChange(of: renderOptions.overlayTextColor) { _ in
            applyFilters()
        }
        .onChange(of: renderOptions.overlayText, perform: { _ in
            applyFilters()
        })
        .onChange(of: renderOptions.overlayTextZPosition, perform: { _ in
            applyFilters()
        })

    }
    
    @ViewBuilder
    func BackgroundOptionsView() -> some View {
        
        
        HStack {
            Text("Gradient")
                .frame(width: 120, alignment: .trailing)
            
            ColorPicker(selection: $renderOptions.backColor, label: {
                EmptyView()
            })
//            .border(Color.black)
            
            ColorPicker(selection: $renderOptions.backColor, label: {
                EmptyView()
            })
//            .border(Color.black)
        }
        .background {
            Rectangle()
                .foregroundStyle(.clear)
                .onTapGesture {}
        }

        HStack { 
            Text("Image")
                .frame(width: 120, alignment: .trailing)

            Button {
                
            } label : {
                Text("Select")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        
        
    }
    
    @ViewBuilder
    func VideoOptionsView() -> some View {
        
        BlenderStyleInput(value: $renderOptions.offsetX, title: "Position X")
        
        BlenderStyleInput(value: $renderOptions.offsetY, title: "Y")
        
        BlenderStyleInput(value: $renderOptions.scaleVideo, title: "Scale Video", unitStr: "%", unitScale: 0.1, minValue: 0)
                        
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
        
        BlenderStyleInput(value: $renderOptions.videoSpeed, title: "Video Speed", unitStr: "%", unitScale: 0.1, minValue: 100)

        
        ColorPicker(selection: $renderOptions.backColor, label: {
            Text("Solid Color")
                .frame(width: 120, alignment: .trailing)
        })
        .background {
            Rectangle()
                .foregroundStyle(.clear)
                .onTapGesture {}
        }

    }
    
    @ViewBuilder
    func ShadowOptionsView() -> some View {
        
        BlenderStyleInput(value: $renderOptions.shadowOffset.x, title: "Shadow X", unitStr: "px")
        
        BlenderStyleInput(value: $renderOptions.shadowOffset.y, title: "Y", unitStr: "px")
        
        BlenderStyleInput(value: $renderOptions.shadowRadius, title: "Blur", unitStr: "px", minValue: 0)
        
        BlenderStyleInput(value: $renderOptions.shadowOpacity, title: "Opacity", unitStr: "%", unitScale: 0.1, minValue: 0)

    }

    
    @ViewBuilder
    func TextOptionsView() -> some View {
        
        TextField("Enter Text", text: $renderOptions.overlayText)
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundStyle(Color(uiColor: .systemGray5).opacity(0.9))
            }
            .padding(.bottom, 4)
        
        BlenderStyleInput(value: $renderOptions.overlayTextOffset.x, title: "Text X", unitStr: "px")
        
        BlenderStyleInput(value: $renderOptions.overlayTextOffset.y, title: "Y", unitStr: "px")
        
        BlenderStyleInput(value: $renderOptions.overlayTextFontSize, title: "Font Size", unitStr: "px", minValue: 0)
        
//        BlenderStyleInput(value: $renderOptions.overlayTextScale, title: "Scale", unitStr: "%", unitScale: 0.1, minValue: 0)
        
        BlenderStyleInput(value: $renderOptions.overlayTextRotation, title: "Rotation", unitStr: "º")

        HStack {
            Text("Z Position")
                .frame(width: 120, alignment: .trailing)

            Picker("", selection: $renderOptions.overlayTextZPosition) {
                ForEach(0..<TextZPosition.allCases.count, id: \.self) { idx in
                    let iPhoneColor = TextZPosition.allCases[idx]
                    Text(iPhoneColor.rawValue)
                        .tag(iPhoneColor)
                }
            }
            .pickerStyle(.segmented)

        }
        
        ColorPicker(selection: $renderOptions.overlayTextColor, label: {
            Text("Color")
                .frame(width: 120, alignment: .trailing)
        })
        .background {
            Rectangle()
                .foregroundStyle(.clear)
                .onTapGesture {}
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

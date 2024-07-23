//
//  RenderLiveWithOptionsView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/23/24.
//

import SwiftUI
import AVKit
import PhotosUI

struct RenderLiveWithOptionsView: View {
    
    @State private var showOptions: Bool = true
    
    enum OptionsGroup: String, CaseIterable {
        case Video
        case Text
        case Shadow
    }
    
    @State var optionsGroup: OptionsGroup = .Video
    @AppStorage("optionsGroup") var optionsGroupSaved: OptionsGroup = .Video

    @State private var player: AVPlayer?
    
    @State private var showImagePicker: Bool = false
    @StateObject var renderOptions: RenderOptions = .init()
    @State private var selectedItems: [PhotosPickerItem] = []
    
    private var videoComposer: VideoComposer = .init()
    
    @State private var frameZeroImage: UIImage?
    
    var body: some View {
        
        ZStack {
            
            let playerContainerSize: CGFloat = 396
            
            GeometryReader {
                let sSize: CGSize = $0.size
//                let _ = print("size \(sSize)")
                let centerY: CGFloat = (sSize.height - playerContainerSize) / 2.0
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .foregroundStyle(.gray.opacity(0.2))
                            .frame(width: playerContainerSize, height: playerContainerSize)
                            .overlay {
                                if let player {
                                    VideoPlayerView(player: player)
                                        .scaledToFit()
                                }
                            }
                            .onAppear {
//                                let mp4URL = Bundle.main.url(forResource: "end-result-old1", withExtension: "mp4")!
                                self.player = AVPlayer()
                            }
                            .ignoresSafeArea()
                        

                        VStack {
                            OptionsEditorView()
                                .opacity(showOptions ? 1 : 0)
                        }
                        .padding(.top, 32)
                        
                    }
                    .offset(y: showOptions ? 0 : centerY)

                }
                .ignoresSafeArea()
                .frame(height: sSize.height)

            }

            barButtons
            
            topSettingsButtonMenu
            
        }
        .onAppear {
            optionsGroup = optionsGroupSaved
        }
        .onAppear {
            if renderOptions.selectedVideoURL == nil {
                self.setDefaultData()
//                self.reloadPreviewPlayer()
            }
        }
        .onChange(of: renderOptions.backColor, perform: { _ in
            self.reloadPreviewPlayer()
        })
    }
    
    func reloadPreviewPlayer() {
        
        guard let baseVideoURL = renderOptions.selectedVideoURL else { print("missing base video"); return }
        
        let outputURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(for: .mpeg4Movie)
        
        videoComposer.createCompositionOnlyForPreview(videoURL: baseVideoURL, outputURL: outputURL, renderOptions: self.renderOptions) { progressVal in
            
        } completion: { playerItem, errorOrNil in
            
            guard let playerItem = playerItem else {
                return
            }
            
            self.player?.replaceCurrentItem(with: playerItem)
            
            let defaultThumb = self.renderOptions.selectedVideoThumbnail!
            let filteredImg = videoComposer.createImagePreview(defaultThumb, renderOptions: renderOptions)

            self.frameZeroImage = filteredImg
            
        }
    }
    
    var topSettingsButtonMenu: some View {
        VStack {
            Menu {
                Button {

                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                
                Button {

                } label: {
                    Label("Request Feature", systemImage: "star.bubble")
                }
                
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .padding(13)
                    .background {
                        Circle()
                            .foregroundStyle(.ultraThinMaterial)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            }
            .foregroundStyle(Color.primary.opacity(0.6))

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    @State var valueOffX: CGFloat = 0.0 //= 0.0
    @State var startValueOffX: CGFloat = 0.0
    
    @State var valueOffY: CGFloat = 0.0 //= 0.0
    @State var startValueOffY: CGFloat = 0.0

    var minValue: CGFloat?
    var maxValue: CGFloat?


    @ViewBuilder
    func VideoLayersOptionsView() -> some View {
        VStack(spacing: 10.0) {
            
            Text("Move And Scale")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
            
            RoundedRectangle(cornerRadius: 1.0, style: .continuous)
                .foregroundStyle(.gray.opacity(0.2))
                .frame(height: 240)
                .padding(.horizontal, 0)
                .overlay {
                    if let frameZeroImage {
                        Image(uiImage: frameZeroImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .padding(.bottom, 16)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ val in
                            let preValue = val.translation.width * (1024 / 240.0 ) + startValueOffX
                            let preValueY = -1.0 * val.translation.height * (1024 / 240.0 ) + startValueOffY

                            valueOffX = applyMinMax(preValue)
                            valueOffY = applyMinMax(preValueY)
                            print("x value \(valueOffX)")
                        })
                        .onEnded({ _ in
                            startValueOffX = valueOffX
                            startValueOffY = valueOffY
                        })
                )
                .onChange(of: (valueOffX + valueOffY) , perform: { value in
                    
                    self.renderOptions.offsetX = valueOffX
                    self.renderOptions.offsetY = valueOffY
                    reloadPreviewPlayer()
                })
            
            BlenderStyleInput(value: $renderOptions.scaleVideo, title: "Scale", unitStr: "%", unitScale: 0.1, minValue: 0)

            
            Text("Background Color")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
            
            RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                .foregroundStyle(.clear)
                .frame(height: 40)
                .padding(.bottom, 16)
                .padding(.horizontal, 12)
                .overlay {
                    ColorPicker(selection: $renderOptions.backColor, label: {
                        EmptyView()
                    })
                    .padding(.trailing, 16)
                }

            FormatLayerOptionButtons()

            RenderDimensionsOptionButtons()
            
            DeviceLayerOptionButtons()
            
            DeviceColorLayerOptionButtons()

        }
        .onChange(of: renderOptions.scaleVideo, perform: { _ in
            reloadPreviewPlayer()
        })
        .padding(.bottom, 120.0)
        .padding(.top, 16)
    }
    
    func applyMinMax(_ value: CGFloat) -> CGFloat {
        var preValue = value
        if let minValue {
            preValue = max(minValue, preValue)
        }
        if let maxValue {
            preValue = min(maxValue, preValue)
        }
        return preValue
    }
    
    @ViewBuilder
    func RenderDimensionsOptionButtons() -> some View {
        Text("Render Size")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
        
        RoundedRectangle(cornerRadius: 8.0, style: .continuous)
            .foregroundStyle(.clear)
            .frame(height: 120)
            .padding(.horizontal, 12)
            .overlay {
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        
                        ButtonRoundedRectForSize(.init(width: 1024, height: 1024), true) {
                            
                        }
                        
                        ButtonRoundedRectForSize(.init(width: 886, height: 1920), false) {
                            
                        }
                        
                        ButtonRoundedRectForSize(.init(width: 1920, height: 886), false) {
                            
                        }

                        
                        ButtonRoundedRectForSize(.init(width: 1290, height: 2796), false) {
                            
                        }
                        
                        ButtonRoundedRectForSize(.init(width: 2796, height: 1290), false) {
                            
                        }
                        
                        
                        ButtonRoundedRectForSize(.init(width: 1242 , height: 2688), false) {
                            
                        }
                        
                        ButtonRoundedRectForSize(.init(width: 2688 , height: 1242), false) {
                            
                        }
                        
                    }
                    .padding(.horizontal, 12)
                }
                
                
            }
            .padding(.bottom, 32)
    }
    
    @ViewBuilder
    func ButtonRoundedRectForSize(_ size: CGSize, _ isSel: Bool, _ action: @escaping ()->()) -> some View {
        Button {
            action()
        } label: {
            VStack {
                
                let aspH = (size.height / size.width) * 0.78
                let aspW = (size.width / size.height) * 0.78
                let portrait = size.height > size.width
                let isSquare = size.height == size.width
                let iconSquareSide: CGFloat = 40
                let heightC: CGFloat = iconSquareSide * aspH
                let iconSize: CGSize = portrait ? CGSize(width: iconSquareSide, height: heightC) : isSquare ? CGSize(width: iconSquareSide, height: iconSquareSide) :  CGSize(width: iconSquareSide * aspW, height: iconSquareSide)
                
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .stroke(.white, lineWidth: 1.0)
                    .frame(width: iconSize.width, height: iconSize.height)
//                    .border(.green)
                    .frame(width: 80, height: 80)
//                    .border(.orange)
                
                let titleStr = String(format: "%i x %i", Int(size.width), Int(size.height))
                Text(titleStr)
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .frame(width: 110, height: 110)
            
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(.gray.opacity(isSel ? 0.2 : 0.15))
            }
        }
        .foregroundColor(isSel ? .primary : .secondary)

    }

    
    @ViewBuilder
    func DeviceLayerOptionButtons() -> some View {
        Text("Device")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
        
        RoundedRectangle(cornerRadius: 8.0, style: .continuous)
            .foregroundStyle(.clear)
            .frame(height: 80)
            .padding(.horizontal, 12)
            .overlay {
                VStack {
                
                    HStack {
                        
                        ButtonFormatDevices("iphone", "15", true) {
                            
                        }
                        
                        ButtonFormatDevices("iphone.gen2", "13", false) {
                            
                        }
                        
                    }
                    
                }
                
            }
    }
    
    @ViewBuilder
    func DeviceColorLayerOptionButtons() -> some View {
        Text("Color")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
        
        RoundedRectangle(cornerRadius: 8.0, style: .continuous)
            .foregroundStyle(.clear)
            .frame(height: 80)
            .padding(.horizontal, 12)
            .overlay {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        
                        ButtonFormatDevices("iphone", "Black", true) {
                            
                        }
                        
                        ButtonFormatDevices("iphone", "Blue", false) {
                            
                        }
                        
                        ButtonFormatDevices("iphone", "Natural", false) {
                            
                        }
                        
                        ButtonFormatDevices("iphone", "White", false) {
                            
                        }
                        
                    }
                    .padding(.horizontal, 12)
                }
            }
    }
    
    @ViewBuilder
    func FormatLayerOptionButtons() -> some View {
        Text("Format")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
        
        RoundedRectangle(cornerRadius: 8.0, style: .continuous)
            .foregroundStyle(.clear)
            .frame(height: 80)
            .padding(.horizontal, 12)
            .overlay {
                HStack {
                    
                    ButtonFormatDevices("iphone", "Portrait", true) {
                        
                    }
                    
                    ButtonFormatDevices("iphone.landscape", "Landscape", false) {
                        
                    }
                    
                }
                
            }
            .padding(.bottom, 32)
    }
    
    @ViewBuilder
    func ButtonFormatDevices(_ icon: String, _ title: String, _ isSel: Bool, action: @escaping ()->()) -> some View {
        Button {
            action()
        } label: {
            VStack {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .fontWeight(.ultraLight)
                    .frame(width: 40, height: 40)
                
                Text(title)
                    .font(.caption2)
            }
            .frame(width: 80, height: 80)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(.gray.opacity(isSel ? 0.2 : 0.15))
            }
        }
        .foregroundColor(isSel ? .primary : .secondary)

    }
    
    
    @ViewBuilder
    func OptionsEditorView() -> some View {
        VStack {
            Picker("", selection: $optionsGroup) {
                ForEach(0..<OptionsGroup.allCases.count, id: \.self) { idx in
                    let iPhoneColor = OptionsGroup.allCases[idx]
                    Text(iPhoneColor.rawValue)
                        .tag(iPhoneColor)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .onChange(of: optionsGroup) { new in
                optionsGroupSaved = new
            }

            switch self.optionsGroup {
            case .Video:
                VideoLayersOptionsView()
                    .padding(.top, 16)
            case .Text:
                EmptyView()
            case .Shadow:
                EmptyView()
            default:
                EmptyView()
            }
//            if optionsGroup == .Video {
//                
//            }
        }
    }
    
    var barButtons: some View {
        HStack {
            
            Button{
                showImagePicker = true
            } label: {
                OptionLabel("iphone.badge.play", "Media")
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.secondary)
            .photosPicker(isPresented: $showImagePicker, selection: $selectedItems, maxSelectionCount: 1, selectionBehavior: .default, matching: .screenRecordings) //.all(of: [, .screenRecordings] //.videos
            /// Load when selected items change
            .onChange(of: selectedItems) { newSelectedItems in
                processSelectedVideo(newSelectedItems)
            }

            
            Button{
                withAnimation(.easeInOut(duration: 0.23)) {
                    showOptions.toggle()
                }
            } label: {
                OptionLabel("slider.horizontal.3", "Options")
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(showOptions ? .white : .secondary)
                        
            Button {
                
            } label: {
                OptionLabel("square.and.arrow.down", "Save")
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.secondary)
        }
        .background {
            Rectangle()
                .foregroundStyle(.ultraThinMaterial) ////red
                .ignoresSafeArea()
                .frame(height: 100)
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

    }
    
    /// Select from Photos
    func processSelectedVideo(_ newSelectedItems: [PhotosPickerItem]) {
        
        Task {
            
            guard let firsItem = newSelectedItems.first else { return }

            guard let type = firsItem.supportedContentTypes.first else {
                print("There is no supported type")
                return
            }

            var itemVideoURL: URL?
            if type.conforms(to: UTType.mpeg4Movie) {
                if let video = try await firsItem.loadTransferable(type: MP4Video.self) {
                    print("Loaded video \(video.url)")
                    itemVideoURL = video.url
                } else {
                    print("error mp4")
                }
            } else if type.conforms(to: UTType.quickTimeMovie) {
                if let video = try await firsItem.loadTransferable(type: QuickTimeVideo.self) {
                    itemVideoURL = video.url
                } else {
                    print("error mov")
                }
            } else {
               print("no video")
           }
           
            if let itemVideoURL {
                let videoAsset = AVURLAsset(url: itemVideoURL)
                let videoTrack = videoAsset.tracks(withMediaType: .video).first!
                let thumbSize: CGSize = .init(width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                let asset = AVAsset(url: itemVideoURL)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = thumbSize

                let cgImage = try await generator.image(at: .zero).image
                guard let colorCorrectedImage = cgImage.copy(colorSpace: CGColorSpaceCreateDeviceRGB()) else { return }
                let thumbnail = UIImage(cgImage: colorCorrectedImage)
                await MainActor.run {
                    self.renderOptions.selectedVideoThumbnail = thumbnail
                    self.renderOptions.selectedVideoURL = itemVideoURL
                    self.renderOptions.videoDuration = videoAsset.duration.seconds
                    let filteredImg = videoComposer.createImagePreview(thumbnail, renderOptions: renderOptions)
                    self.renderOptions.selectedFiltered = filteredImg
                    self.frameZeroImage = filteredImg
                    self.reloadPreviewPlayer()
                    print("set thumbnail \(thumbnail)")
                }
            }
           
        }
        
    }
    
    @ViewBuilder
    func OptionLabel(_ icon: String, _ title: String) -> some View {
        let iconSize: CGFloat = 32.0
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .offset(y: -2)
                .frame(width: iconSize, height: iconSize)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)


    }
    
    func setDefaultData() {
        //uiux-short
        //uiux-black-sound //uiux-black-sound
        self.renderOptions.selectedVideoURL = Bundle.main.url(forResource: "uiux-short", withExtension: "mp4")
        let defaultThumb = UIImage(contentsOfFile: Bundle.main.url(forResource: "screencap1", withExtension: "jpg")!.path)!
        
        let asset = AVURLAsset(url: self.renderOptions.selectedVideoURL!)
        self.renderOptions.videoDuration = asset.duration.seconds
        self.renderOptions.selectedVideoThumbnail = defaultThumb
        let filteredImg = videoComposer.createImagePreview(defaultThumb, renderOptions: renderOptions)
        self.renderOptions.selectedFiltered = filteredImg
        self.frameZeroImage = filteredImg
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    var player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = true
       playerViewController.videoGravity = .resizeAspectFill
        
        player.play()
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
}


#Preview {
    RenderLiveWithOptionsView()
        .preferredColorScheme(.dark)
}

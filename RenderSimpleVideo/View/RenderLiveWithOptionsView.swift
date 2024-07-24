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
    
    enum MockupStyle: CaseIterable {
        case simple
        case scene3d
        case fromVideo
    }
    
    @State private var mockupStyleSelected: MockupStyle = .simple
    @State private var idxBottomSelected: Int = 0
    
    @State var optionsGroup: OptionsGroup = .Video
    @AppStorage("optionsGroup") var optionsGroupSaved: OptionsGroup = .Video

    @State private var player: AVPlayer?
    
    @State private var showImagePicker: Bool = false
    @StateObject var renderOptions: RenderOptions = .init()
    @State private var selectedItems: [PhotosPickerItem] = []
    
    private var videoComposer: VideoComposer = .init()
    
    @State private var frameZeroImage: UIImage?
    
    @Environment(\.containerNavPath) var navPath
    
    enum RenderState {
        case none
        case rendering
        case finish
    }
    
    @State private var renderState: RenderState = .none
    @State private var renderProgress: CGFloat = 0.0
    
    @State private var renderVideoURL: URL?
    
    @State private var showRenderResultView: Bool = false
    
    @ObservedObject var storeKit: StoreKitManager = .shared
    
    @State private var timerForStopPlayer: Timer?
    @State private var frameRenderImg: UIImage?
    @State private var playerStopMotionIdx: Int = 0
    @State private var totalStopMotionFrames: Int = 2
    
    @State private var isPlaying: Bool = false
    
    @State private var showButtonCenterPlay: Bool = false

    var body: some View {
        
        ZStack {
            
            let playerContainerSize: CGFloat = showOptions ? 120 : 396
            GeometryReader {
                let sSize: CGSize = $0.size
//                let _ = print("size \(sSize)")
                let centerY: CGFloat = (sSize.height - playerContainerSize) / 2.0
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .foregroundStyle(.gray.opacity(0.2))
                            .frame(width: playerContainerSize, height: playerContainerSize)
//                            .overlay {
//                                if let player {
//                                    VideoPlayerView(player: player)
//                                        .scaledToFit()
////                                        .padding(.bottom, 84)
//                                }
//                            }
                            .overlay {
//                                TabView {
//                                    if let rndImg = frameRenderImg {
//                                        Image(uiImage: rndImg)
//                                            .resizable()
//                                            .scaledToFit()
//    //                                        .frame(width: 140, height: 140)
//                                            .contentShape(.rect)
//                                        
//                                    }
//                                    
//                                    
//                                }
//                                .tabViewStyle(.page(indexDisplayMode: .always))
//                                .indexViewStyle(.page(backgroundDisplayMode: .always))

                                if let player {
                                    VideoPlayerView(player: player)
                                        .scaledToFit()
                                }
                                
                            }
//                            .overlay {
//                                if showButtonCenterPlay {
//                                    ZStack {
//                                        if isPlaying {
//                                            Image(systemName: "play.fill")
//                                                .font(.system(size: 40))
//                                                .shadow(color: .black.opacity(0.4), radius: 10, x: 0.0, y: 0.0)
//                                        } else {
//                                            Image(systemName: "pause.fill")
//                                                .font(.system(size: 40))
//                                                .shadow(color: .black.opacity(0.4), radius: 10, x: 0.0, y: 0.0)
//                                        }
//                                        
//                                    }
//                                }
//                                
//                            }
//                            .contentShape(.rect)
//                            .onTapGesture {
//                                if isPlaying {
//                                    /// Stop
//                                    self.isPlaying = false
//                                    self.timerForStopPlayer?.invalidate()
//                                } else {
//                                    self.isPlaying = true
//                                    self.timerForStopPlayer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
//                                        self.playerStopMotionIdx += 1
//                                        self.requestNewTimeThumbForIdx()
//                                    })
//                                }
//                                
//                                withAnimation(.linear(duration: 0.2)) {
//                                    showButtonCenterPlay = true
//                                }
//                                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 2.0) {
//                                    withAnimation(.linear(duration: 0.2)) {
//                                        showButtonCenterPlay = false
//                                    }
//                                }
//                                
//                            }
                        
                            .onAppear {
//                                let mp4URL = Bundle.main.url(forResource: "end-result-old1", withExtension: "mp4")!
                                self.player = AVPlayer()
                            }
                            .ignoresSafeArea()
                            .padding(.top, 64)

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
                self.reloadPreviewPlayerWithTimer()
                
//                self.setupStopMotionPlayer()
//                self.isPlaying = true
//                self.reloadPreviewPlayer()
            }
        }
        .onChange(of: renderOptions.backColor, perform: { _ in
            self.reloadPreviewPlayer()
        })
        .sheet(isPresented: $showRenderResultView, content: {
            if let renderVideoURL {
                ResultRenderView(videoURL: renderVideoURL)
            }
        })

    }
    
    func setupStopMotionPlayer() {
        self.timerForStopPlayer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            self.playerStopMotionIdx += 1
            self.requestNewTimeThumbForIdx()
//            print("Timer counter \(timer.timeInterval) self.playerStopMotionIdx \(self.playerStopMotionIdx)")
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
            
            reloadOnlyThumbnail()
        }
    }
    
    @State private var timerForReloadPlayer: Timer?
    
    func reloadOnlyThumbnail() {
        
        timerForReloadPlayer?.invalidate()
        
        let defaultThumb = self.renderOptions.selectedVideoThumbnail!
        let selectFrame = defaultThumb
        let filteredImg = videoComposer.createImagePreview(defaultThumb, renderOptions: renderOptions)

        self.frameZeroImage = filteredImg

        print("recreate thumbnail")
//        timerForReloadPlayer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
//            self.reloadPreviewPlayer()
//        })
    }
    
    @ViewBuilder
    func RenderStatusOverlay() -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .foregroundStyle(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(.primary.opacity(0.2), lineWidth: 0.8)
            }
            .frame(width: 30, height: 30)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .overlay {
                if renderState == .rendering {

                    ProgressView(value: self.renderProgress, total: 1.0)
                        .padding(.horizontal, 1)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal, 1)
                        .tint(.green.opacity(0.9))

                } else if renderState == .finish {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 20))
                        .fontWeight(.light)
                        .foregroundStyle(.green)
                }
            }
            .offset(y: -5)
    }

    
    func makeVideoWithComposition() {
        
        guard let baseVideoURL = renderOptions.selectedVideoURL else { print("missing base video"); return }
        let outputURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(for: .mpeg4Movie)
        DispatchQueue.main.async {
            self.renderState = .rendering
            self.renderProgress = 0.0
        }
        
        videoComposer.createAndExportComposition(videoURL: baseVideoURL, outputURL: outputURL, renderOptions: self.renderOptions, progress: { perc in
            DispatchQueue.main.async {
                self.renderProgress = perc
            }
        }) { err in
            if let err {
                print("Error ", err)
                DispatchQueue.main.async {
                    self.renderState = .none
                }
            } else {
                print("Completed \(outputURL)")
                DispatchQueue.main.async {
                    self.renderVideoURL = outputURL
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.showRenderResultView = true
                        self.renderState = .finish
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut) {
                                self.renderState = .none
                            }
                        }
                    }
                }

            }
        }
    }

    
    @State private var showRequestFeatureForm: Bool = false
    var topSettingsButtonMenu: some View {
        VStack {
            Menu {
                Button {
                    navPath.wrappedValue.append(Routes.settings)
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                
                Button {
                    showRequestFeatureForm = true
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
        .sheet(isPresented: $showRequestFeatureForm, content: {
            SendRequestFormView()
        })

    }
    
    @State var valueOffX: CGFloat = 0.0 //= 0.0
    @State var startValueOffX: CGFloat = 0.0
    
    @State var valueOffY: CGFloat = 0.0 //= 0.0
    @State var startValueOffY: CGFloat = 0.0

    var minValue: CGFloat?
    var maxValue: CGFloat?

    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0

    @Namespace var animation

    @ViewBuilder
    func VideoLayersOptionsView() -> some View {
        VStack(spacing: 10.0) {
            
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

            
            Text("Move And Scale")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
            
            RoundedRectangle(cornerRadius: 1.0, style: .continuous)
                .foregroundStyle(.gray.opacity(0.2))
                .frame(height: 300)
                .padding(.horizontal, 0)
                .overlay {
                    if let frameZeroImage {
                        Image(uiImage: frameZeroImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .padding(.bottom, 16)
                .gesture(
                    DragGesture(minimumDistance: 0.0)
                        .onChanged({ val in
                            let preValue = val.translation.width * (1024 / 300 ) + startValueOffX
                            let preValueY = -1.0 * val.translation.height * (1024 / 300 ) + startValueOffY

                            valueOffX = applyMinMax(preValue)
                            valueOffY = applyMinMax(preValueY)
//                            print("x value \(valueOffX)")
                        })
                        .onEnded({ _ in
                            startValueOffX = valueOffX
                            startValueOffY = valueOffY
                        })
                )
                .onChange(of: (valueOffX + valueOffY) , perform: { value in
                    
                    self.renderOptions.offsetX = valueOffX
                    self.renderOptions.offsetY = valueOffY
                    reloadOnlyThumbnail()
                    reloadPreviewPlayerWithTimer()
                })
                .gesture(
                    MagnificationGesture(minimumScaleDelta: 0.05)
                        .onChanged { value in
                            self.currentZoom = value.magnitude - 1.0
                        }
                        .onEnded { value in
                            totalZoom += currentZoom
                            currentZoom = 0
                        }
                )
                .onChange(of: currentZoom, perform: { value in
//                    print("new val \(value)")
                    self.renderOptions.scaleVideo += ((value) * (1024 / 300 ) * 0.5)
                    reloadPreviewPlayerWithTimer()
                })

            
            BlenderStyleInput(value: $renderOptions.scaleVideo, title: "Scale", unitStr: "%", unitScale: 0.1, minValue: 0)
                .padding(.bottom, 32)

            
            BlenderStyleInput(value: $renderOptions.videoSpeed, title: "Video Speed", unitStr: "%", unitScale: 0.1, minValue: 100)
            
            let durWSpeed = (renderOptions.videoDuration ?? 60.0) / (renderOptions.videoSpeed / 100)
            let durFloatStr = String(format: "Duration %.1fs", durWSpeed)
            Text(durFloatStr)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 220, alignment: .trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.bottom, 32)


            FormatLayerOptionButtons()

            RenderDimensionsOptionButtons()
            
            DeviceLayerOptionButtons()
            
            DeviceColorLayerOptionButtons()

        }
        .onChange(of: renderOptions.scaleVideo, perform: { _ in
            reloadOnlyThumbnail()
            self.reloadPreviewPlayerWithTimer()
        })
        .padding(.bottom, 120.0)
        .padding(.top, 16)
    }
    
    func reloadPreviewPlayerWithTimer() {
        
        self.timerForReloadPlayer?.invalidate()
        self.timerForReloadPlayer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            self.reloadPreviewPlayer()
        }
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
                        
                        let sqSizeOpt1: CGSize = .init(width: 1024, height: 1024)
                        let selSize = renderOptions.renderSize
                        ButtonRoundedRectForSize(sqSizeOpt1, selSize.equalTo(sqSizeOpt1)) {
                            self.renderOptions.renderSize = sqSizeOpt1
                        }
                        
                        let sqSizeOpt2: CGSize = .init(width: 886, height: 1920)
                        ButtonRoundedRectForSize(sqSizeOpt2, selSize.equalTo(sqSizeOpt2)) {
                            self.renderOptions.renderSize = sqSizeOpt2

                        }
                        
                        let sqSizeOpt3: CGSize = .init(width: 1920, height: 886)
                        ButtonRoundedRectForSize(sqSizeOpt3, selSize.equalTo(sqSizeOpt3)) {
                            self.renderOptions.renderSize = sqSizeOpt3

                        }

                        let sqSizeOpt4: CGSize = .init(width: 1290, height: 2796)
                        ButtonRoundedRectForSize(sqSizeOpt4, selSize.equalTo(sqSizeOpt4)) {
                            self.renderOptions.renderSize = sqSizeOpt4
                        }
                        
                        let sqSizeOpt5: CGSize = .init(width: 2796, height: 1290)
                        ButtonRoundedRectForSize(sqSizeOpt5, selSize.equalTo(sqSizeOpt5)) {
                            self.renderOptions.renderSize = sqSizeOpt5

                        }
                        
                        let sqSizeOpt6: CGSize = .init(width: 1242 , height: 2688)

                        ButtonRoundedRectForSize(sqSizeOpt6, selSize.equalTo(sqSizeOpt6)) {
                            self.renderOptions.renderSize = sqSizeOpt6

                        }
                        let sqSizeOpt7: CGSize = .init(width: 2688 , height: 1242)

                        ButtonRoundedRectForSize(sqSizeOpt7, selSize.equalTo(sqSizeOpt7)) {
                            self.renderOptions.renderSize = sqSizeOpt7
                        }
                        
                    }
                    .onChange(of: self.renderOptions.renderSize, perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .padding(.horizontal, 12)
                }
                
                
            }
            .padding(.bottom, 32)
    }
    
    @ViewBuilder
    func OptionsEditorView() -> some View {
        VStack {
            
            Text("Mockup")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

            HStack(spacing: 0.0) {
                let stylesTitles: [String] = ["Simple", "Scene 3D", "From Video"]
                let styleIcons: [String] = ["iphone", "rotate.3d.circle", "video.circle"]
                
                ForEach(0..<MockupStyle.allCases.count, id: \.self) { idx in
                    
                    let valSel = MockupStyle.allCases[idx]
                    let isSel = mockupStyleSelected == valSel
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                            idxBottomSelected = idx
                        }
                        withAnimation(.linear(duration: 0.23)) {
                            mockupStyleSelected = valSel
                        }
                        
                    } label: {
                        let tt = stylesTitles[idx]
                        let stI = styleIcons[idx]
                        VStack(spacing: 4) {
                            Image(systemName: stI)
                                .font(.largeTitle)
                                .fontWeight(.ultraLight)
                            
                            Text(tt)
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .overlay(alignment: .bottom) {
                            if idxBottomSelected == idx {
                                Rectangle()
                                    .foregroundStyle(.primary.opacity(0.8))
                                    .frame(height: 1)
                                    .offset(y: 12)
                                    .padding(.horizontal, 0)
                                    .matchedGeometryEffect(id: "styleSel", in: animation)
                            }
                        }
                        
                    }
                    .foregroundStyle(isSel ? Color.primary : Color.primary.opacity(0.2))
                    .frame(maxWidth: .infinity)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .foregroundStyle(.secondary.opacity(0.4))
                    .frame(height: 1)
                    .offset(y: 12)
                    .padding(.horizontal, 12)
            }
            .padding(.bottom, 32)
            
            switch self.mockupStyleSelected {
            case .simple:
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
                    TextLayerOptions()
                case .Shadow:
                    EmptyView()
                default:
                    EmptyView()
                }

            default:
                EmptyView()
            }
        }
    }
    
    @State private var startAddTextCoordinate: CGPoint = .zero
    
    @ViewBuilder
    func TextLayerOptions() -> some View {
        
        VStack(spacing: 16) {
            Text("Tap to add text")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 32)
            
            let renderAspect = renderOptions.renderSize.width / renderOptions.renderSize.height
            let minSquareHeight: CGFloat = 300
            let maxWidth = minSquareHeight * renderAspect
            RoundedRectangle(cornerRadius: 1.0, style: .continuous)
                .foregroundStyle(.gray.opacity(0.2))
                .frame(height: minSquareHeight)
                .padding(.horizontal, 0)
                .overlay {
                    if let frameZeroImage {
                        Image(uiImage: frameZeroImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .padding(.bottom, 16)
                .gesture(
                    DragGesture(minimumDistance: 0.0)
                        .onChanged({ val in
                            print("Val \(val)")
                            startAddTextCoordinate = val.startLocation
    //                        let preValue = val.translation.width * (1024 / 300 ) + startValueOffX
    //                        let preValueY = -1.0 * val.translation.height * (1024 / 300 ) + startValueOffY
    //
    //                        valueOffX = applyMinMax(preValue)
    //                        valueOffY = applyMinMax(preValueY)
    //                            print("x value \(valueOffX)")
                        })
                        .onEnded({ val in
                            /// New Text layer
                            var newLayerText = RenderTextLayer()
                            let xCords = val.location.x / maxWidth
                            let yCords = val.location.y / minSquareHeight
                            let coordinatesForRender = CGPoint(x: xCords, y: yCords)
                            newLayerText.coordinates = coordinatesForRender
                            newLayerText.textString = String(format: "hey %i", Int(val.location.x))
                            newLayerText.zPosition = .infront
                            
                            self.renderOptions.textLayers.append(newLayerText)
                            self.reloadPreviewPlayer()
                            
                            print("drag add sticker end \(coordinatesForRender)")

    //                        startValueOffX = valueOffX
    //                        startValueOffY = valueOffY
                        })
                )
                .onChange(of: (valueOffX + valueOffY) , perform: { value in
                    
    //                self.renderOptions.offsetX = valueOffX
    //                self.renderOptions.offsetY = valueOffY
    //                reloadOnlyThumbnail()
    //                reloadPreviewPlayerWithTimer()
                })
                .gesture(
                    MagnificationGesture(minimumScaleDelta: 0.05)
                        .onChanged { value in
    //                        self.currentZoom = value.magnitude - 1.0
                        }
                        .onEnded { value in
    //                        totalZoom += currentZoom
    //                        currentZoom = 0
                        }
                )
                .onChange(of: currentZoom, perform: { value in
    //                    print("new val \(value)")
    //                self.renderOptions.scaleVideo += ((value) * (1024 / 300 ) * 0.5)
    //                reloadPreviewPlayerWithTimer()
                })
                .padding(.bottom, 24.0)
            
            Text("Layers")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 32)

            ///Layers
            VStack(spacing: 4) {
                ForEach(0..<self.renderOptions.textLayers.count, id: \.self) { idx in
                    let layerText = renderOptions.textLayers[idx]
                    Text(layerText.textString)
                }
            }
            
            Rectangle()
                .foregroundStyle(.clear)
                .frame(height: 400)
        }
        
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
                    .stroke(Color.primary, lineWidth: 1.0)
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
                        
                        ButtonFormatDevices("iphone", "15", renderOptions.selectedDevice == .fifthn) {
                            renderOptions.selectedDevice = .fifthn
                        }
                        
                        ButtonFormatDevices("iphone.gen2", "13", renderOptions.selectedDevice == .thirtn) {
                            renderOptions.selectedDevice = .thirtn
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
                    
                    ButtonFormatDevices("iphone", "Portrait", renderOptions.selectedFormat == .portrait) {
                        renderOptions.selectedFormat = .portrait
                    }
                    
                    ButtonFormatDevices("iphone.landscape", "Landscape", renderOptions.selectedFormat == .landscape) {
                        renderOptions.selectedFormat = .landscape
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
            .foregroundStyle(showOptions ? .primary : .secondary)
                 
            
            if renderState != .none {
                RenderStatusOverlay()
                    .overlay{
                        Text("Rendering")
                            .frame(width: 60)
                            .font(.system(size: 11))
                            .offset(y: 20)
                    }
//                    .frame(width: 36, height: 36)
                    .frame(maxWidth: .infinity)
            } else {
                Button {
                    makeVideoWithComposition()
                } label: {
                    OptionLabel("square.and.arrow.down", "Save")
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.secondary)
            }
            
        }
        .offset(y: 6)
        .background {
            Rectangle()
                .foregroundStyle(.ultraThinMaterial) ////red
                .ignoresSafeArea()
                .frame(height: 60)
                
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

                let imgPrevTime: CMTime = .zero
                let cgImage = try await generator.image(at: imgPrevTime).image
                guard let colorCorrectedImage = cgImage.copy(colorSpace: CGColorSpaceCreateDeviceRGB()) else { return }
                let thumbnail = UIImage(cgImage: colorCorrectedImage)
                await MainActor.run {
                    
                    self.renderOptions.selectedVideoThumbnail = thumbnail
                    self.renderOptions.selectedVideoURL = itemVideoURL
                    self.renderOptions.videoDuration = videoAsset.duration.seconds
                    let filteredImg = videoComposer.createImagePreview(thumbnail, renderOptions: renderOptions)
                    self.renderOptions.selectedFiltered = filteredImg
                    self.frameZeroImage = filteredImg
                    self.reloadPreviewPlayerWithTimer()
                    print("set thumbnail \(thumbnail)")
                }
            }
           
        }
        
    }
    
    func requestNewTimeThumbForIdx() {
        
        let videoDurFrame = (self.renderOptions.videoDuration ?? 0) / CGFloat(totalStopMotionFrames)
        let groupIdx =  self.playerStopMotionIdx % totalStopMotionFrames
        let newRenderTime = CMTime(seconds: videoDurFrame * CGFloat(groupIdx), preferredTimescale: 600)
        
//        print("self.renderOptions.videoDuration \(self.renderOptions.videoDuration) videoDurFrame \(videoDurFrame) req time \(newRenderTime.seconds) \(groupIdx)")
        let itemVideoURL = self.renderOptions.selectedVideoURL!
        let videoAsset = AVURLAsset(url: itemVideoURL)
        let videoTrack = videoAsset.tracks(withMediaType: .video).first!
        let thumbSize: CGSize = .init(width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
        
        let asset = AVAsset(url: itemVideoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = thumbSize

        let imgPrevTime: CMTime = newRenderTime
        Task {
            let cgImage = try await generator.image(at: imgPrevTime).image
            frameRenderImg = UIImage(cgImage: cgImage)
            
            if let actRender = frameRenderImg {
                let filteredImg = videoComposer.createImagePreview(actRender, renderOptions: renderOptions)
                frameRenderImg = filteredImg
            }
            

        }
        
    }
    
    @ViewBuilder
    func OptionLabel(_ icon: String, _ title: String) -> some View {
        let iconSize: CGFloat = 32.0
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 24))
//                .offset(y: -2)
                .frame(width: iconSize, height: iconSize)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)


    }
    
    func setDefaultData() {
        //uiux-short
        //uiux-black-sound //uiux-black-sound
        self.renderOptions.selectedVideoURL = Bundle.main.url(forResource: "ui2-show", withExtension: "mov")
        
        /// Let find image generator
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
       playerViewController.videoGravity = .resizeAspect
        
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

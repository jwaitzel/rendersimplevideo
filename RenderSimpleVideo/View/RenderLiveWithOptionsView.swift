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
//        case scene3d
//        case fromVideo
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

    @State private var selectedEditingTextIdx: Int?
    
    /// Dragging values For Move
    @State var valueOffX: CGFloat = 0.0 //= 0.0
    @State var startValueOffX: CGFloat = 0.0
    
    @State var valueOffY: CGFloat = 0.0 //= 0.0
    @State var startValueOffY: CGFloat = 0.0

    var minValue: CGFloat?
    var maxValue: CGFloat?

    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0

    @Namespace var animation
    
    @State private var startAddTextCoordinate: CGPoint = .zero
    
    @State private var currentTxtLayer: RenderTextLayer?
    
    @State private var didCreateNew: Bool = false
    
    @State private var isDraggingIcon: Bool = false
    
    @State private var onDragInitialLayerPos: CGPoint = .zero
    
    @State private var onDragTextLayerPos: CGPoint = .zero
    @State private var onDragTextLayerStartPos: CGPoint = .zero
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                
                let playerContainerSize: CGFloat = showOptions ? 120 : 396
                GeometryReader {
                    let sSize: CGSize = $0.size
    //                let _ = print("size \(sSize)")
                    let centerY: CGFloat = (sSize.height - playerContainerSize) / 2.0
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            
                            HStack {
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
                                
                                Rectangle() //spacer
                                    .foregroundStyle(.clear)
                                
                            }
                            
                            
                                .onAppear {
    //                                let mp4URL = Bundle.main.url(forResource: "end-result-old1", withExtension: "mp4")!
                                    self.player = AVPlayer()
                                }
                                .ignoresSafeArea()
                                .padding(.top, 64)

                            VStack {
                                
//                                VideoInfo()
//                                    .opacity(showOptions ? 1 : 0)
                                
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
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    if didCreateNew {
                        Button {

                            let lastIdx = self.renderOptions.textLayers.count-1
                            didCreateNew = false
                            self.renderOptions.textLayers.remove(at: lastIdx)
                            self.reloadPreviewPlayer()
                            
                            self.currentTxtLayer = nil
                            self.selectedEditingTextIdx = nil
                            self.focusedField = .none
                            AppState.shared.selIdx = nil
                            
                            //.append(newLayerText)
                        } label: {
                            Text("Cancel")
                        }
                        .foregroundColor(.primary.opacity(0.9))
                        .opacity(self.didCreateNew ? 1.0 : 0.0)
                    }
                    
                    
                    Spacer()
                    
                    Button {
                        self.endEditingTextF()
                    } label: {
                        Text("Done")
                    }
                    .foregroundColor(.primary.opacity(0.9))
                    .opacity(self.currentEditing.isEmpty ? 0 : 1)
                }
                
            }
        }
        .overlay {
            if selectedEditingTextIdx != nil {
                CenterTextField()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .font(.largeTitle)
                    .padding(.vertical, 16)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 16)
//                    .background {
//                        Rectangle()
//                            .foregroundStyle(.ultraThinMaterial)
//                    }
//                    .overlay(alignment: .bottomTrailing) {
//                        Button {
//                            self.endEditingTextF()
//                            
//                        } label: {
//                            Text("Done")
//                        }
//                        .foregroundColor(.primary.opacity(0.8))
//                        .padding(.bottom, 4)
//                        .padding(.trailing, 4)
//                    }

            }
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
    
    
    @State private var selectedToolbarItem: Int?
    @ViewBuilder
    func BlenderStyleToolbar() -> some View {
        let toolBarOptionsItemsTitles = ["arrow.up.and.down.and.arrow.left.and.right",
                                         "arrow.up.backward.and.arrow.down.forward"
        ]
        VStack(spacing: 0.0) {
            
            
            ForEach(0..<toolBarOptionsItemsTitles.count, id: \.self) { idx in
                var isSel = idx == selectedToolbarItem
                Button {

                    if isSel {
                        selectedToolbarItem = nil
                        self.reloadOnlyThumbnail()
                        return
                    }
                    selectedToolbarItem = idx
                    self.reloadOnlyThumbnail()
                } label: {
                    Image(systemName: toolBarOptionsItemsTitles[idx])
                }
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background {
                    Rectangle()
                        .foregroundStyle(Color.black.opacity(0.2))
                        .overlay {
                            if isSel {
                                Color.accentColor.opacity(0.5)
                            }
                        }
                }
                

            }
//            Button {
//                
//            } label: {
//                Image(systemName: "arrow.up.backward.and.arrow.down.forward")
//                    
//            }
//            .foregroundStyle(.primary)
//            .frame(width: 44, height: 44)
//            .background {
//                Rectangle()
//                    .foregroundStyle(.black.opacity(0.2))
//            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .padding(.trailing, 8)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    func VideoInfo() -> some View {
        
        VStack {
            HStack {
                Text("Tuesday • 23 Jul 2024 • 21:59")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    
                } label: {
                    Text("Adjust")
                        
                }
                .foregroundStyle(.primary.opacity(0.8))
                .opacity(0)
            }
            .padding(.horizontal, 12)
            
            Text("REPPlay_Final17123128")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
            /// Screen record info box
            VStack(spacing: 0.0) {
                HStack {
                    Text("Screen Recording")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("mov")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .foregroundStyle(.gray.opacity(0.4))
                                .ignoresSafeArea()
                        }
                        .ignoresSafeArea()
                    
                    Image(systemName: "record.circle")
                    
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .foregroundStyle(.secondary.opacity(0.3))
                }

                ///Size info
                VStack(spacing: 4) {
                    Text("No information")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("888x1920 • 15 MB")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                }
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .padding(.bottom, 16)
                .foregroundStyle(.primary.opacity(0.6))
                
                Divider()
                
                HStack {
                    Text("59,99 FPS")
                        .frame(maxWidth: .infinity )
                    
                    Divider()
                    
                    Text("00:07")
                        .frame(maxWidth: .infinity )
                }
                .foregroundStyle(.primary.opacity(0.6))
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                

            }
            .background {
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .foregroundStyle(.secondary.opacity(0.2))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 8)
            
        }
        .padding(.bottom, 24)
        

    }
    
    func endEditingTextF() {
        
        UIApplication.shared.endEditing()
        //Change text
        if let edIdx = selectedEditingTextIdx {
            self.renderOptions.textLayers[edIdx].textString = currentEditing
            selectedEditingTextIdx = nil
            self.currentEditing = ""
            self.reloadPreviewPlayer()
        }
        
    }
    
    func setupStopMotionPlayer() {
        self.timerForStopPlayer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            self.playerStopMotionIdx += 1
            self.requestNewTimeThumbForIdx()
//            print("Timer counter \(timer.timeInterval) self.playerStopMotionIdx \(self.playerStopMotionIdx)")
        })
    }
    
    @ViewBuilder
    func ShadowOptionsView() -> some View {
        VStack {
            
            let renderAspect = renderOptions.renderSize.width / renderOptions.renderSize.height
            let minSquareHeight: CGFloat = UIScreen.main.bounds.width
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
                .overlay {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .stroke(Color.primary.opacity(0.8), lineWidth: 1)
                }
                .padding(.bottom, 16)

            
            BlenderStyleInput(value: $renderOptions.shadowOffset.x, title: "Shadow X", unitStr: "px")
            
            BlenderStyleInput(value: $renderOptions.shadowOffset.y, title: "Y", unitStr: "px")
            
            BlenderStyleInput(value: $renderOptions.shadowRadius, title: "Blur", unitStr: "px", minValue: 0)
            
            BlenderStyleInput(value: $renderOptions.shadowOpacity, title: "Opacity", unitStr: "%", unitScale: 0.1, minValue: 0)
        }
        .onChange(of: (renderOptions.shadowOffset.x +
                       renderOptions.shadowOffset.y +
                       renderOptions.shadowRadius +
                       renderOptions.shadowOpacity), perform: { value in
            self.reloadPreviewPlayer()
        })
        .padding(.top, 16)
        .padding(.bottom, 120)
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
    
    /// Reload the thumbnail for some icons / tools
    func reloadOnlyThumbnail() {
        
        timerForReloadPlayer?.invalidate()
        
        guard let defaultThumb = self.renderOptions.selectedVideoThumbnail else { print("no thmb"); return }
        let selectFrame = defaultThumb
        
        //selectedEditingTextIdx
        let filteredImg = videoComposer.createImagePreview(defaultThumb, renderOptions: renderOptions, selected: optionsGroup == .Video ? selectedToolbarItem == nil ? nil : RenderSelectionElement.phone : (optionsGroup == .Text && AppState.shared.selIdx != nil) ? RenderSelectionElement.layer : nil )

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
                
            
            let sqSize = UIScreen.main.bounds.width - 8.0
            RoundedRectangle(cornerRadius: 1.0, style: .continuous)
                .foregroundStyle(.gray.opacity(0.2))
                .frame(height: sqSize)
                .padding(.horizontal, 0)
                .overlay {
                    if let frameZeroImage {
                        Image(uiImage: frameZeroImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .overlay {
                    if selectedToolbarItem == nil {
                        Rectangle()
                            .foregroundStyle(.black.opacity(0.2))
                    }
                }
//                .overlay {
//                    RoundedRectangle(cornerRadius: 0, style: .continuous)
//                        .stroke(Color.primary.opacity(0.8), lineWidth: 1)
//                }
//                .overlay {
//                    /// Cover until touch
//                    Rectangle()
//                        .foregroundStyle(.black.opacity(0.1))
//                }
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0.0, y: 0.0)
                .padding(.horizontal, 4)
                .padding(.bottom, 16)
                .gesture(
                    DragGesture(minimumDistance: 0.0)
                        .onChanged({ val in
                            let preValue = val.translation.width * (renderOptions.renderSize.width / sqSize ) + startValueOffX
                            let preValueY = -1.0 * val.translation.height * (renderOptions.renderSize.height / sqSize ) + startValueOffY

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
                    self.renderOptions.scaleVideo += ((value) * (renderOptions.renderSize.width / sqSize ) * 0.5)
                    reloadPreviewPlayerWithTimer()
                })
                .allowsHitTesting(selectedToolbarItem != nil)
                .overlay(alignment: .topTrailing, content: {
                    BlenderStyleToolbar()
                })


            /// Handler empty View
            Image(systemName:"line.3.horizontal")
                .foregroundColor(.primary.opacity(0.2))
                .font(.largeTitle)
                .opacity(0.0)
                .frame(width: 10, height: 10)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            
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
            
            Text("Custom Record Indicator Overlay")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 16)
                .padding(.bottom, 32)

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
                        let selSize = renderOptions.renderSize // Selected option
                        ButtonRoundedRectForSize(sqSizeOpt1, selSize.equalTo(sqSizeOpt1)) {
                            self.renderOptions.renderSize = sqSizeOpt1
                        }
                        
                        let sqSizeOpt11: CGSize = .init(width: 1920, height: 1920)
                        ButtonRoundedRectForSize(sqSizeOpt11, selSize.equalTo(sqSizeOpt11)) {
                            self.renderOptions.renderSize = sqSizeOpt11

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
//
//            Text("Mockup")
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundStyle(.primary)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.horizontal, 12)
//                .padding(.bottom, 12)
//
//            HStack(spacing: 0.0) {
//                let stylesTitles: [String] = ["Simple", "Scene 3D", "From Video"]
//                let styleIcons: [String] = ["iphone", "rotate.3d.circle", "video.circle"]
//
//                ForEach(0..<MockupStyle.allCases.count, id: \.self) { idx in
//
//                    let valSel = MockupStyle.allCases[idx]
//                    let isSel = mockupStyleSelected == valSel
//                    Button {
//                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
//                            idxBottomSelected = idx
//                        }
//                        withAnimation(.linear(duration: 0.23)) {
//                            mockupStyleSelected = valSel
//                        }
//
//                    } label: {
//                        let tt = stylesTitles[idx]
//                        let stI = styleIcons[idx]
//                        VStack(spacing: 4) {
//                            Image(systemName: stI)
//                                .font(.largeTitle)
//                                .fontWeight(.ultraLight)
//
//                            Text(tt)
//                                .font(.caption2)
//                                .fontWeight(.semibold)
//                        }
//                        .overlay(alignment: .bottom) {
//                            if idxBottomSelected == idx {
//                                Rectangle()
//                                    .foregroundStyle(.primary.opacity(0.8))
//                                    .frame(height: 1)
//                                    .offset(y: 12)
//                                    .padding(.horizontal, 0)
//                                    .matchedGeometryEffect(id: "styleSel", in: animation)
//                            }
//                        }
//
//                    }
//                    .foregroundStyle(isSel ? Color.primary : Color.primary.opacity(0.2))
//                    .frame(maxWidth: .infinity)
//                }
//            }
//            .overlay(alignment: .bottom) {
//                Rectangle()
//                    .foregroundStyle(.secondary.opacity(0.4))
//                    .frame(height: 1)
//                    .offset(y: 12)
//                    .padding(.horizontal, 12)
//            }
//            .padding(.bottom, 32)
            
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
                    self.reloadOnlyThumbnail()
                }

                switch self.optionsGroup {
                case .Video:
                    VideoLayersOptionsView()
                        .padding(.top, 16)
                case .Text:
                    TextLayerOptions()
                case .Shadow:
                    ShadowOptionsView()
                default:
                    EmptyView()
                }

            default:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    func TextLayerOptions() -> some View {
        
        VStack(spacing: 16) {
            
            Text("Tap to add text")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(currentTxtLayer == nil ? Color.primary : Color.clear)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 32)
                
            
            let renderAspect = renderOptions.renderSize.width / renderOptions.renderSize.height
            let minSquareHeight: CGFloat = UIScreen.main.bounds.width
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
                .overlay {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .stroke(Color.primary.opacity(0.8), lineWidth: 1)
                }
                .overlay(alignment: .bottom) {
                    if currentTxtLayer != nil {
                        Button {
                            currentTxtLayer = nil
                            AppState.shared.selIdx = nil
                            self.reloadPreviewPlayer()
                        } label: {
                            Text("Done")
                        }
                        .foregroundStyle(.primary.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .offset(y: 24)
                        .padding(.trailing, 8)
                        .opacity(selectedEditingTextIdx == nil ? 1.0 : 0.0)
                    }
                    
                }
                .padding(.bottom, 16)
                .gesture(
                    DragGesture(minimumDistance: 0.0)
                        .onChanged({ val in
                            
                            if !isDraggingIcon {
                                isDraggingIcon = true
                                self.createDraggingIconTextOverlay()
                            }
                            
                            startAddTextCoordinate = val.startLocation
                            
                            //absolute
                            let preValueX = val.translation.width + onDragTextLayerStartPos.x
                            let preValueY = val.translation.height + onDragTextLayerStartPos.y

                            onDragTextLayerPos = CGPointMake(preValueX, preValueY)
                            print("Val \(val.translation) preValueX \(preValueX) preValueY \(preValueY)")

    //                        let preValue = val.translation.width * (1024 / 300 ) + startValueOffX
    //                        let preValueY = -1.0 * val.translation.height * (1024 / 300 ) + startValueOffY
    //
    //                        valueOffX = applyMinMax(preValue)
    //                        valueOffY = applyMinMax(preValueY)
    //                            print("x value \(valueOffX)")
                        })
                        .onEnded({ val in
                            
                            let preValueX = val.translation.width + onDragTextLayerStartPos.x
                            let preValueY = val.translation.height + onDragTextLayerStartPos.y
                            
                            
                            /// -150 - 150
                            /// Val -width/2 - width/20
                            let xCords = (preValueX + minSquareHeight/2.0) / minSquareHeight //+ 1.0 // maxWidth
                            
                            let yCords = (preValueY + minSquareHeight/2.0) / minSquareHeight// preValueY // minSquareHeight
                            
                            let coordinatesForRender = CGPoint(x: xCords, y: yCords)
                            print("Coordinates for render \(xCords) \(yCords)")
                            
                            onDragTextLayerStartPos = onDragTextLayerPos
//                            onDragInitialLayerPos = onDragTextLayerPos
                            
                            self.isDraggingIcon = false
                            
                            if currentTxtLayer != nil {
                                currentTxtLayer?.coordinates = coordinatesForRender
//                                onDragTextLayerPos = coordinatesForRender //rel
//                                onDragTextLayerStartPos = .zero
                                self.reloadPreviewPlayer()
                                
                                return
                            }
                            /// New Text layer
                            addNewTextLayer(coordinatesForRender)
                            
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
                .overlay {
//                    if let selTextLayer = currentTxtLayer {
//                        let absPos = CGPoint(x: selTextLayer.coordinates.x * minSquareHeight, y: 0.0)
////                            .offset(absPos)
//                    }
                    
//                    let onDragTextLayerPos = CGPointMake(onDragTextLayerPos.x + onDragTextLayerStartPos.x, onDragTextLayerPos.y + onDragTextLayerStartPos.y)
                    
                    let selScale = renderOptions.renderSize.width / minSquareHeight
                    let extSize = AppState.shared.selTextExt ?? .zero
//                    let extAsp = extSize.width / extSize.height
//                    let relAbs = CGPointMake(onDragTextLayerPos.x * minSquareHeight - minSquareHeight / 2.0, onDragTextLayerPos.y * minSquareHeight - minSquareHeight / 2.0)
                    // 3
                    Rectangle()
                        .stroke(.blue, lineWidth: 4.0)
                        .offset(x: onDragTextLayerPos.x, y: onDragTextLayerPos.y)
                        .frame(width: extSize.width / selScale, height: extSize.height / selScale)
//                        .offset(x: relAbs.x, y: relAbs.y)

                }
//                .padding(.bottom, 24.0)
//                .overlay(alignment: .bottom) {
//                    if selectedEditingTextIdx != nil {
//                        Button {
//                            
//                        } label: {
//                            Text("Done")
//                        }
//                        .foregroundColor(.primary)
//                        .background {
//                            foregroundStyle(.ultraThinMaterial)
//                        }
//                        .frame(maxWidth: .infinity, alignment: .trailing)
//                    }
//                    
//                }
            
            /// Handler empty View
            Image(systemName:"line.3.horizontal")
                .foregroundColor(.primary.opacity(0.2))
                .font(.largeTitle)
                .opacity(0.0)
                .frame(width: 10, height: 10)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)

            if let idx = AppState.shared.selIdx {

            Text("Selected Layer")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 32)

                SelectedLayerFontOptionsView(selIdx: idx)
                    .onChange(of: (self.renderOptions.textLayers[idx].textFontSize + renderOptions.textLayers[idx].textFontWeight.rawValue +
                                   renderOptions.textLayers[idx].textRotation
                                  ),  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: self.renderOptions.textLayers[idx].textColor,  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
            }
            
            
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
                    CellLayerView(layerText, idx)
                        .contentShape(.rect)
                        .onTapGesture {
                            
//                            self.currentEditing = layerText.textString
//                            self.selectedEditingTextIdx = idx
//                            self.focusedField = .text
                            currentTxtLayer = layerText
                            
                            didCreateNew = false
                            
                            // Select frame
                            AppState.shared.selIdx = idx
                            
                            self.reloadOnlyThumbnail()
                        }

                }
            }
            
            Rectangle()
                .foregroundStyle(.clear)
                .frame(height: 400)
        }
        
    }
    
    func createDraggingIconTextOverlay() {
        
    }
    
    @ViewBuilder
    func SelectedLayerFontOptionsView(selIdx: Int) -> some View {
        
        
        BlenderStyleInput(value: $renderOptions.textLayers[selIdx].textFontSize, title: "Font Size", unitStr: "px", minValue: 0)
        
        HStack {
            Text("Weight")
                .frame(width: 120, alignment: .trailing)

            let weightOptions: [UIFont.Weight] = [.ultraLight, .thin, .light, .regular]
            let weightOptionsSw: [Font.Weight] = [.ultraLight, .thin, .light, .regular]
            let weightOptTitles: [String] = ["Ultra", "Thin", "Light", "Thin", "Regular"]
            
            let weightOptionsRow2: [UIFont.Weight] = [.semibold, .bold, .heavy, .black]
            let weightOptionsSwRow2: [Font.Weight] = [.semibold, .bold, .heavy, .black]
            let weightOptTitlesRow2: [String] = ["Semi", "Bold", "Heavy", "Black"]
            
            VStack(spacing: 4.0) {
                Picker("", selection: $renderOptions.textLayers[selIdx].textFontWeight) {
                    ForEach(0..<weightOptions.count, id: \.self) { idx in
                        let weightTitle = weightOptTitles[idx]
                        let fontWeight = weightOptions[idx]
                        let fontUIWeight = weightOptionsSw[idx]
                        Text(weightTitle)
                            .tag(fontWeight)
                    }
                }
                .pickerStyle(.segmented)
                
                /// Second layer
                Picker("", selection: $renderOptions.textLayers[selIdx].textFontWeight) {
                    ForEach(0..<weightOptionsRow2.count, id: \.self) { idx in
                        let weightTitle = weightOptTitlesRow2[idx]
                        let fontWeight = weightOptionsRow2[idx]
                        let fontUIWeight = weightOptionsSwRow2[idx]
                        Text(weightTitle)
                            .tag(fontWeight)
                    }
                }
                .pickerStyle(.segmented)
            }
            

        }

//        BlenderStyleInput(value: $renderOptions.overlayTextScale, title: "Scale", unitStr: "%", unitScale: 0.1, minValue: 0)
        
        BlenderStyleInput(value: $renderOptions.textLayers[selIdx].textRotation, title: "Rotation", unitStr: "º")

        HStack {
            Text("Z Position")
                .frame(width: 120, alignment: .trailing)

            Picker("", selection: $renderOptions.textLayers[selIdx].textZPosition) {
                ForEach(0..<TextZPosition.allCases.count, id: \.self) { idx in
                    let iPhoneColor = TextZPosition.allCases[idx]
                    Text(iPhoneColor.rawValue)
                        .tag(iPhoneColor)
                }
            }
            .pickerStyle(.segmented)
        }
        
        ColorPicker(selection: $renderOptions.textLayers[selIdx].textColor, label: {
            Text("Color")
                .frame(width: 120, alignment: .trailing)
        })
        .background {
            Rectangle()
                .foregroundStyle(.clear)
                .onTapGesture {}
        }

    }
    
    func addNewTextLayer(_ coordinatesForRender: CGPoint) {
        
        let newLayerText = RenderTextLayer()
        newLayerText.coordinates = coordinatesForRender
        newLayerText.textString = String(format: "hey")
        newLayerText.zPosition = .infront
        
        self.selectedEditingTextIdx = self.renderOptions.textLayers.count
        AppState.shared.selIdx = self.selectedEditingTextIdx
        self.renderOptions.textLayers.append(newLayerText)
        
        self.reloadPreviewPlayer()
        currentTxtLayer = newLayerText
        print("drag add sticker end \(coordinatesForRender)")
        
        self.currentEditing = newLayerText.textString
        self.focusedField = .text

        didCreateNew = true
    }
    
    @ViewBuilder
    func CellLayerView(_ layerText: RenderTextLayer, _ idx: Int) -> some View {
        HStack {
            
            VStack {
                Text(layerText.textString)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let formPosStr = String(format: "x%.2f y%.2f", CGFloat(layerText.coordinates.x), CGFloat(layerText.coordinates.y))
                Text(formPosStr)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 16)
            
            
            Button {
                self.currentEditing = layerText.textString
                self.selectedEditingTextIdx = idx
                self.focusedField = .text
            } label: {
                Image(systemName: "character.cursor.ibeam")
                    .font(.system(size: 18, weight: .bold))
                    .padding(13)
                    .background {
                        Circle()
                            .foregroundStyle(.ultraThinMaterial)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            Menu {
                Button {
                    self.currentEditing = layerText.textString
                    self.selectedEditingTextIdx = idx
                    self.focusedField = .text

                } label: {
                    Label("Edit", systemImage: "character.cursor.ibeam")
                }
                
//                Button {
////                    showRequestFeatureForm = true
//                } label: {
//                    Label("Request Feature", systemImage: "star.bubble")
//                }

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
            .padding(.trailing, 16)

            
//            Button {
//                
//            } label: {
//                Image(systemName: "ellipsis")
//            }
//            .foregroundStyle(.primary.opacity(0.8))

        }
        .background {
            if idx == AppState.shared.selIdx {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .foregroundStyle(.primary.opacity(0.1))
            } else {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(.primary.opacity(0.1))
            }
            
        }
        .frame(maxWidth: .infinity)

    }
    
    enum FocusedField {
        case text
    }

    @FocusState private var focusedField: FocusedField?

    
    @State private var currentEditing: String = ""
    @ViewBuilder
    func CenterTextField() -> some View {
//        TextField("", text: $currentEditing)
//        TextEditor(text: $currentEditing)
        TextField("", text: $currentEditing,  axis: .vertical)
            .focused($focusedField, equals: .text)
        .lineLimit(1...5)
        .frame(height: 200)
        .onSubmit {
            self.endEditingTextF()
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
        .ignoresSafeArea(.keyboard)

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
        self.renderOptions.selectedVideoURL = Bundle.main.url(forResource: "uiux-test2", withExtension: "mov")
        
        let asset = AVURLAsset(url: self.renderOptions.selectedVideoURL!)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
//        generator.maximumSize = thumbSize

        self.renderOptions.videoDuration = asset.duration.seconds
        
        Task {
            
            let imgPrevTime: CMTime = .zero
            let cgImage = try await generator.image(at: imgPrevTime).image
            guard let colorCorrectedImage = cgImage.copy(colorSpace: CGColorSpaceCreateDeviceRGB()) else { return }
            let thumbnail = UIImage(cgImage: colorCorrectedImage)
            

            await MainActor.run {
                self.renderOptions.selectedVideoThumbnail = thumbnail
                let filteredImg = videoComposer.createImagePreview(thumbnail, renderOptions: renderOptions)
                self.renderOptions.selectedFiltered = filteredImg
                self.frameZeroImage = filteredImg
            }
            
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1.0) {
                
                let coordinatesForRender = CGPointMake(0.5, 0.5)

                let newLayerText = RenderTextLayer()
                newLayerText.coordinates = coordinatesForRender
                newLayerText.textString = String(format: "hey")
                newLayerText.zPosition = .infront
                
//                self.selectedEditingTextIdx = self.renderOptions.textLayers.count
                AppState.shared.selIdx = 0
                
                self.currentTxtLayer = newLayerText
                
                /// New Text layer
    //            addNewTextLayer(coordinatesForRender)

                self.renderOptions.textLayers.append(newLayerText)

                self.reloadPreviewPlayer()

            }
        }

        
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

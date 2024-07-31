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
    
    @State private var showOptions: Bool = false
    
    enum OptionsGroup: String, CaseIterable {
        case Video
        case Text
        case Shadow
    }
    @AppStorage("optionsGroup") var optionsGroupSaved: OptionsGroup = .Video
    @State var optionsGroup: OptionsGroup = .Video

    enum MockupStyle: CaseIterable {
        case simple
//        case scene3d
//        case fromVideo
    }
    
    @State private var mockupStyleSelected: MockupStyle = .simple
    @State private var idxBottomSelected: Int = 0
    

    @State private var player: AVPlayer?
    
    /// Video Picker
    @State private var shoeVideosPicker: Bool = false
    @State private var selectedItems: [PhotosPickerItem] = []
    
    @StateObject var renderOptions: RenderOptions = .init()
    private var videoComposer: VideoComposer = .init()
    
    @State var frameZeroImage: UIImage?
    
    /// Nav
    @Environment(\.containerNavPath) var navPath
    
    /// Render state properties
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
    
    /// Stop motion player - not enabled yet
    @State private var timerForStopPlayer: Timer?
    @State private var frameRenderImg: UIImage?
    @State private var playerStopMotionIdx: Int = 0
    @State private var totalStopMotionFrames: Int = 2
    @State private var isPlaying: Bool = false
    @State private var showButtonCenterPlay: Bool = false
    
    @State private var selectedEditingTextIdx: Int?
    
    /// Dragging values For Move Video Layer
    @State var valueOffX: CGFloat = 0.0 //= 0.0
    @State var startValueOffX: CGFloat = 0.0
    
    @State var valueOffY: CGFloat = 0.0 //= 0.0
    @State var startValueOffY: CGFloat = 0.0

    var minValue: CGFloat?
    var maxValue: CGFloat?
    
    /// Zoom for Video Layer
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0

    @Namespace var animation
    
    /// For gizmo
    @State private var startAddTextCoordinate: CGPoint = .zero
    
    @State private var currentTxtLayer: RenderTextLayer?
    
    @State private var didCreateNew: Bool = false
    
    @State private var isDraggingIcon: Bool = false
    
    @State private var onDragInitialLayerPos: CGPoint = .zero
    
    @State private var onDragTextLayerPos: CGPoint = .zero
    @State private var onDragTextLayerStartPos: CGPoint = .zero
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// Animation for save movie
    @State var animateFromRect: CGRect = .zero
    @State var animateScreenshot = false
    @State var secondSwipeAnimation = false
    @State var flashAnimation = false
    @State var showNewScreenshotAnimationImage:UIImage? = nil
    
    @State var offsetY: CGFloat = 0.0
    @State var colorFeedbackForSave: CGFloat = 0.0
    @State var gestureOffsetX: CGFloat = 0
//    @State var scaleOnTapAnimaiton = false

    
    /// Custom Images
    @State private var imageBycodeKey: [String: Data] = [:]
    /// Image picker for custom text layer
    @State private var showSignaturePicker: Bool = false
    @State private var selectedSignatureItems: [PhotosPickerItem] = []
    
    @State var moreFontOptionsStateIdx: Int = 0
    
    /// Blender style toolbar selected item
    @State private var selectedVideoToolbarItemIdx: Int? = 0
    @State private var selectedTextToolbarItemIdx: Int? = 0

    
    /// Video info section properties
    @State private var nativeVideoSize: CGSize = .zero
    @State private var videoSizeMB: CGFloat = 0.0
    @State private var videoInfoFPS: CGFloat = 0.0
    @State private var videoInfoName: String = "" //"REPPlay_Final17123128"
    @State private var videoInfoDate:String?
    
    @State private var moreStateDir: Int = 1
    
    @State private var newOrigin: CGPoint?
    @State private var regionEndPos: CGPoint?

    
    //MARK: - Body
    var body: some View {
        
        NavigationStack {
            ZStack {
                
                centerPreviewVideoPlayerAndOptions

                barButtons
                
                topSettingsButtonMenu
                
            }
        }
        .overlay {
            if showNewScreenshotAnimationImage != nil {
                NewScreenshotAnimatedView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    /// Remove just created (bad code) - needs redo :jw
                    if didCreateNew {
                        Button {

                            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.01) {
                                
                                AppState.shared.selIdx = nil
                                let lastIdx = self.renderOptions.textLayers.count-1
                                self.renderOptions.textLayers.remove(at: lastIdx)
                                
                            }
                            
                            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.3) {
                                self.reloadPreviewPlayerWithTimer()
                                self.didCreateNew = false
                            }
                            
                            self.currentTxtLayer = nil
                            self.selectedEditingTextIdx = nil
                            self.focusedField = .none
                            clarCreateGizmoValues()
                            
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
            self.reloadPreviewPlayerWithTimer()
        })
        .sheet(isPresented: $showRenderResultView, content: {
            if let renderVideoURL {
                ResultRenderView(videoURL: renderVideoURL)
            }
        })

    }
    
    var centerPreviewVideoPlayerAndOptions: some View {
        
        GeometryReader {
            
            let playerContainerSize: CGFloat = showOptions ? 120 : 396
            let sSize: CGSize = $0.size
            let centerY: CGFloat = (sSize.height - playerContainerSize) / 2.0
            let safeTop = $0.safeAreaInsets.top
//                    let _ = print("safeTop \(safeTop)")
            ScrollView(showsIndicators: false) {
                
                /// Video Player centered
                VStack(spacing: 0) {
                    
                    HStack {
                        
                        Rectangle()
                            .foregroundStyle(.gray.opacity(0.2))
                            .frame(width: playerContainerSize, height: playerContainerSize)
                            .overlay {
                                if let player {
                                    VideoPlayerView(player: player)
                                        .scaledToFit()
                                }
                            }
                            
                        Spacer()
                        
                    }
                    .onAppear {
                        self.player = AVPlayer()
                    }
                    .shadow(color: .black.opacity(showOptions ? 0 : 0.2), radius: 2, x: 0.0, y: 0.0)
                    .ignoresSafeArea()
                    .padding(.top, showOptions ? safeTop : 0)

                    if showOptions {
                        VStack {
                            
//                            VideoInfo()
                            
                            OptionsEditorView()
                        }
                        .frame(width: sSize.width)
                        .padding(.top, 32)
                    }
                }
                .offset(y: showOptions ? 0 : centerY)

            }
            .ignoresSafeArea()
            .frame(width:sSize.width, height: sSize.height)
        }
    }
    
    @ViewBuilder
    func StopMotionStylePlayer() -> some View {
        Rectangle()
            .overlay {
                if showButtonCenterPlay {
                    ZStack {
                        if isPlaying {
                            Image(systemName: "play.fill")
                                .font(.system(size: 40))
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 0.0, y: 0.0)
                        } else {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 40))
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 0.0, y: 0.0)
                        }

                    }
                }

            }
            .contentShape(.rect)
            .onTapGesture {
                if isPlaying {
                    /// Stop
                    self.isPlaying = false
                    self.timerForStopPlayer?.invalidate()
                } else {
                    self.isPlaying = true
                    self.timerForStopPlayer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
                        self.playerStopMotionIdx += 1
                        self.requestNewTimeThumbForIdx()
                    })
                }

                withAnimation(.linear(duration: 0.2)) {
                    showButtonCenterPlay = true
                }
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 2.0) {
                    withAnimation(.linear(duration: 0.2)) {
                        showButtonCenterPlay = false
                    }
                }
            }
    }
    
    
    //MARK: Animation for save image
    @ViewBuilder
    func NewScreenshotAnimatedView() -> some View {
        
        let isRenderLandspcpe = renderOptions.renderSize.width > renderOptions.renderSize.height
        var aspect: CGFloat = isRenderLandspcpe ?  showNewScreenshotAnimationImage!.size.height / showNewScreenshotAnimationImage!.size.width : showNewScreenshotAnimationImage!.size.height / showNewScreenshotAnimationImage!.size.height
                
        let iconSizeWidth: CGFloat = horizontalSizeClass == .compact ? 160.0 : 190
        let size = showNewScreenshotAnimationImage!.size
        let aspH = (size.height / size.width) * 0.78
        let aspW = (size.width / size.height) * 0.78
        let imgIsPortrait = size.height > size.width
        let isSquare = size.height == size.width
        let iconSquareSide: CGFloat = iconSizeWidth
        let heightC: CGFloat = iconSquareSide * aspH
        let onlySqrDebuSize = CGSize(width: 120, height: 120)
        let iconSizeFitAspect: CGSize = imgIsPortrait ? CGSize(width: iconSquareSide, height: heightC) : isSquare ? CGSize(width: iconSquareSide, height: iconSquareSide) :  CGSize(width: max(240, iconSquareSide * aspW), height: iconSquareSide)
        var iconSizeScaled = iconSizeFitAspect //true ?  : CGSize(width: 50, height: 50)
        let xOffsetForLandscape = imgIsPortrait || isSquare ? 0 : -30.0
//        let window = UIApplication.shared.windows.first
//        let topPadding = (window?.safeAreaInsets.top ?? 0)
//        let _ = print("scaled  \(onlySqrDebuSize)")
        
        ZStack {
            
            Image(uiImage: showNewScreenshotAnimationImage!)
                .resizable()
                .aspectRatio(contentMode: .fill)
//                .overlay(content: {
//                    RoundedRectangle(cornerRadius: 16, style: .continuous)
//                        .stroke(Color.primary, lineWidth: 4.0)
//                })
                .overlay {
                    Color.white.opacity(flashAnimation ? 0.0 : 1.0)
                        .ignoresSafeArea()
                }
                .frame(width: animateScreenshot ? iconSizeScaled.width : animateFromRect.width,
                       height: animateScreenshot ? iconSizeScaled.height : animateFromRect.height)
                .clipShape(RoundedRectangle(cornerRadius: animateScreenshot ? 16 : 0, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0.0, y: 0.0)
                .frame(width: iconSquareSide, height: iconSquareSide)
                .ignoresSafeArea()

        }
        .frame(width: animateScreenshot ? iconSizeScaled.width : animateFromRect.width,
               height: animateScreenshot ? iconSizeScaled.height : animateFromRect.height)
        
        .offset(x: animateScreenshot ? (UIScreen.main.bounds.width * (horizontalSizeClass == .compact ? 0.2 : 0.24) + xOffsetForLandscape)  : 0.0,
                y: animateScreenshot ? UIScreen.main.bounds.height * (horizontalSizeClass == .compact ? 0.3 : 0.34) : 0.0)
        
        .offset(x: secondSwipeAnimation ? UIScreen.main.bounds.width * 0.8 : 0)
        .offset(x: shakeIdx == 1 ? 6.0 : shakeIdx == 2 ? -6 : 0.0)

    }
    
    @State private var shakeIdx: Int = 0
    @State private var shakeLoop: Int = 2
    
    func shake() {
        shakeIdx = 0
        shakeLoop = 2
        shakeLeft()
    }
    
    func shakeLeft() {

        withAnimation(.linear(duration: 0.125)) {
            shakeIdx = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.124, execute: {
            self.shakeRight()
        })
        
    }
    
    func shakeRight() {
        
        withAnimation(.linear(duration: 0.125)) {
            shakeIdx = 2
        }
        
        shakeLoop -= 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.124){
            if shakeLoop > 0 {
                shakeLeft()
            } else {
                withAnimation(.easeIn(duration: 0.25)) {
                    shakeIdx = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    withAnimation(.linear(duration: 0.3).delay(0.01)) {
                        self.secondSwipeAnimation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6){
                        resetNewScreenshotStates()
                    }
                }
            }
        }
    }
    

    func resetNewScreenshotStates() {
        
        animateScreenshot = false
        showNewScreenshotAnimationImage = nil
        gestureOffsetX = 0
        colorFeedbackForSave = 0
        secondSwipeAnimation = false
        flashAnimation = false
//        withAnimation(.easeInOut(duration: 0.3)) {
//            scaleOnTapAnimaiton = false
//        }
//        self.animateFromRect = .zero
        offsetY = 0.0
    }
    
    func saveImageAnimated() {
        
        guard let zframe = frameZeroImage else { return }
        showNewScreenshotAnimationImage = zframe
//        let screenCapURL = Bundle.main.url(forResource: "screencap1", withExtension: "jpg")!
//        let img = UIImage(contentsOfFile: screenCapURL.path())!
        let centerScreenY = UIScreen.main.bounds.size.height / 2.0
        let widthScre = UIScreen.main.bounds.width
        var asp = zframe.size.width / zframe.size.height
        if zframe.size.height > zframe.size.width && renderOptions.renderSize.height > renderOptions.renderSize.width {
            asp = zframe.size.height / zframe.size.width
        }
        
        let scaledAspHeight: CGFloat = widthScre //min(380.0, widthScre * asp)
        let rectForAnim = CGRect(x: 0, y: centerScreenY, width: widthScre, height: scaledAspHeight)
        

        self.animateNewSaveImage(zframe, rectForAnim)
        
    }
    
    @State private var shouldShake: Bool = false
    func animateNewSaveImage(_ image: UIImage, _ frame: CGRect) {
        /// - Save image animations
        showNewScreenshotAnimationImage = image
        animateFromRect = frame //initial rect position
        print("Animation \(showNewScreenshotAnimationImage) fr \(animateFromRect)")
        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.7).delay(0.1)) {
            self.animateScreenshot = true
        }
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1.0) {
            if !shouldShake {
                //// If state two play animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.secondSwipeAnimation = true
                }
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1.3) {
                    resetNewScreenshotStates()
                }
            } else {
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.01) {
                    self.shake()
                }
            }
        }
        
        withAnimation(.easeIn(duration: 0.55)) {
            flashAnimation = true
        }
    }
    
    @State private var shakeAnimation: Bool = false
    
    @ViewBuilder
    func BlenderStyleTextToolbar() -> some View {
        let toolBarOptionsItemsTitles = [
            "hand.point.up.left.and.text",
            "arrow.up.and.down.and.arrow.left.and.right"
        ]
        let customImgs: [Int: UIImage] = [
            1 : UIImage(named: "moveblendericon")!,
            0 : UIImage(named: "addtext")!
        ]
        let customSelImgs: [Int: UIImage] = [
            1 : UIImage(named: "move-sel")!,
            0 : UIImage(named: "addtext-sel")!
        ]
        VStack(spacing: 0.0) {
            
            
            ForEach(0..<toolBarOptionsItemsTitles.count, id: \.self) { idx in
                
                let isSel = idx == selectedTextToolbarItemIdx
                    
                Button {
//                    print("Bt action")
                    if isSel {
//                        print("Bt is")
                        selectedTextToolbarItemIdx = nil
                        self.reloadOnlyThumbnail()
                        return
                    }
                    selectedTextToolbarItemIdx = idx
                    self.reloadOnlyThumbnail()
                    print("sel")
                } label: {
                    if let ui = customImgs[idx], let uiSel = customSelImgs[idx]  {
                        Image(uiImage: isSel ? uiSel : ui)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: toolBarOptionsItemsTitles[idx])
                    }
                }
                .frame(width: 36, height: 36)
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background {
                    Rectangle()
                        .foregroundStyle(isSel ? Color(red: 56/255, green: 115/255, blue: 184/255) : Color(red: 40/255, green: 40/255, blue: 40/255))
                }

            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .padding(.trailing, 8)
        .padding(.top, 8)
        .onChange(of: selectedTextToolbarItemIdx, perform: { value in
            if let newValue = value {
                if  newValue == 0 {
                    deselectLayer()
                }
                
                print("Changed toolbar to \(value) didCreateNew \(didCreateNew) \(AppState.shared.selIdx) last \(lastLayerSel)")
                /// If selected move //&& !didCreateNew
                if value == 1 && AppState.shared.selIdx == nil {
                    print("will select \(lastLayerSel)")
                    selectLastLayerSel()
                }
            }
            if value == nil {
                deselectLayer()
            }
        })
    }
    
    func selectLastLayerSel() {
        if let selID = self.lastLayerSel {
            AppState.shared.selIdx = selID
            let layerToMove = self.renderOptions.textLayers[selID]
            self.currentTxtLayer = layerToMove
            self.didCreateNew = false
            self.selectLayer(selID, layerToMove)
            self.reloadOnlyThumbnail()
        } else {
            print("no last idx")
        }
    }

    @ViewBuilder
    func BlenderStyleToolbar() -> some View {
        let toolBarOptionsItemsTitles = ["arrow.up.and.down.and.arrow.left.and.right",
                                         "arrow.up.backward.and.arrow.down.forward"]
        
        let customImgs: [Int: UIImage] = [
            0 : UIImage(named: "moveblendericon")!,
            1 : UIImage(named: "scaleicon")!
        ]

        let customSelImgs: [Int: UIImage] = [
            0 : UIImage(named: "move-sel")!,
            1 : UIImage(named: "scale-sel")!
        ]

        VStack(spacing: 0.0) {
            ForEach(0..<toolBarOptionsItemsTitles.count, id: \.self) { idx in
                let isSel = idx == selectedVideoToolbarItemIdx
                Button {
                    if isSel {
                        selectedVideoToolbarItemIdx = nil
                        self.reloadOnlyThumbnail()
                        return
                    }
                    selectedVideoToolbarItemIdx = idx
                    self.reloadOnlyThumbnail()
                } label: {
                    if let ui = customImgs[idx], let uiSel = customSelImgs[idx]  {
                        Image(uiImage: isSel ? uiSel : ui)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: toolBarOptionsItemsTitles[idx])
                    }
                }
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background {
                    Rectangle()
                        .foregroundStyle(isSel ? Color(red: 56/255, green: 115/255, blue: 184/255) : Color(red: 40/255, green: 40/255, blue: 40/255))
                }


            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .padding(.trailing, 8)
        .padding(.top, 8)
    }
    
    
    
    @ViewBuilder
    func VideoInfo() -> some View {
        
        VStack {
            HStack {
                Text(videoInfoDate ?? "no date")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
            }
            .padding(.horizontal, 12)
                        
            Text(videoInfoName)
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

                let natSizeStr = String(format:"%ix%i", Int(nativeVideoSize.width), Int(nativeVideoSize.height) )
                ///Size info
                VStack(spacing: 4) {
                    Text("No information")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    let totMbSize = String(format: "%i MB", Int(videoSizeMB))
                    Text("\(natSizeStr) • \(totMbSize)")
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
                    
                    let durString = String(format: "%.2fs", renderOptions.videoDuration ?? 0.0)
                    Text(durString) //"00:07"
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
        
        if didCreateNew {
            
            let inputRect = rectForDots(self.newOrigin ?? .zero, self.regionEndPos ?? .zero)
            calculateValues(inputRect)
            print("print fit rect \(didCreateNew) \(inputRect)")

            self.selectedTextToolbarItemIdx = 1

            self.clarCreateGizmoValues()

//            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.4) {
//
//            }
        }
        
        //Change text
        if let edIdx = selectedEditingTextIdx {
            self.renderOptions.textLayers[edIdx].textString = currentEditing
            selectedEditingTextIdx = nil
            self.lastLayerSel = edIdx
            self.currentEditing = ""
            self.reloadPreviewPlayerWithTimer()
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
        VStack(spacing: 12) {
            
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
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0.0, y: 0.0)
                .padding(.bottom, 24)


            VStack(spacing: 12) {
                BlenderStyleInput(value: $renderOptions.shadowOffset.x, title: "Shadow X", unitStr: "px")
                
                BlenderStyleInput(value: $renderOptions.shadowOffset.y, title: "Y", unitStr: "px")
                
                BlenderStyleInput(value: $renderOptions.shadowRadius, title: "Blur", unitStr: "px", minValue: 0)
                
                BlenderStyleInput(value: $renderOptions.shadowOpacity, title: "Opacity", unitStr: "%", unitScale: 0.1, minValue: 0)
            }
            .padding(.trailing, 12)
            
        }
        .onChange(of: (renderOptions.shadowOffset.x +
                       renderOptions.shadowOffset.y +
                       renderOptions.shadowRadius +
                       renderOptions.shadowOpacity), perform: { value in
            self.reloadPreviewPlayerWithTimer()
        })
        .padding(.top, 16)
        .padding(.bottom, 120)
    }

    
    func reloadPreviewPlayer() {
        
        guard let baseVideoURL = renderOptions.selectedVideoURL else { print("missing base video"); return }
        
        let outputURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(for: .mpeg4Movie)
        print("reload with data ")
        videoComposer.createCompositionOnlyForPreview(videoURL: baseVideoURL, outputURL: outputURL, renderOptions: self.renderOptions, renderCustomCodeByKey: self.imageBycodeKey) { progressVal in
            
        } completion: { playerItem, errorOrNil in
            
            guard let playerItem = playerItem else {
                return
            }
            
            self.player?.replaceCurrentItem(with: playerItem)
            
//            let recreatePlayer = AVPlayer(playerItem: playerItem)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
//                self.player = recreatePlayer
//                self.player?.play()
//            })
            reloadOnlyThumbnail()
        }
    }
    
    @State private var timerForReloadPlayer: Timer?
    
    /// Reload the thumbnail for some icons / tools
    func reloadOnlyThumbnail() {
        
        timerForReloadPlayer?.invalidate()
        
        guard let defaultThumb = self.renderOptions.selectedVideoThumbnail else { print("no thmb"); return }
        let selectFrame = defaultThumb
        
        let isSelForVide = optionsGroup == .Video && selectedVideoToolbarItemIdx != nil
        let isSelForLayer = optionsGroup == .Text && AppState.shared.selIdx != nil
        print("sel reload \(AppState.shared.selIdx) ")
        //selectedEditingTextIdx
        let filteredImg = videoComposer
            .createImagePreview(defaultThumb,
                               renderOptions: renderOptions,
                                selected: isSelForVide ? RenderSelectionElement.phone : isSelForLayer ? RenderSelectionElement.layer : nil , renderCustomCodeByKey: self.imageBycodeKey)

        self.frameZeroImage = filteredImg

//        print("recreate thumbnail")
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
            .frame(width: 24, height: 24)
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
                        .font(.system(size: 18))
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
        
        videoComposer.createAndExportComposition(videoURL: baseVideoURL, outputURL: outputURL, renderOptions: self.renderOptions, renderCustomCodeByKey: self.imageBycodeKey, progress: { perc in
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
    func VideoOptionsView() -> some View {
        VStack(spacing: 12.0) {
            
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

            
            Text("Move and scale")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                
            
            let sqSize = UIScreen.main.bounds.width - 0.0
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
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0.0, y: 0.0)
//                .padding(.horizontal, 0)
                .padding(.bottom, 16)
                .gesture(
                    DragGesture(minimumDistance: 0.0)
                        .onChanged({ val in
                            
                            if !isDraggingIcon {
                                isDraggingIcon = true
                            }
                            
                            let preValue = val.translation.width * (renderOptions.renderSize.width / sqSize ) + startValueOffX
                            let preValueY = -1.0 * val.translation.height * (renderOptions.renderSize.height / sqSize ) + startValueOffY

                            valueOffX = applyMinMax(preValue)
                            valueOffY = applyMinMax(preValueY)
                            
//                            print("x value \(valueOffX)")
                        })
                        .onEnded({ _ in
                            startValueOffX = valueOffX
                            startValueOffY = valueOffY
                            
                            isDraggingIcon = false
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
                .overlay {
                    
                    let selExtent = AppState.shared.selTextExt ?? CGRect.zero
                    let extSize = selExtent.size
                    let selScale: CGFloat = (renderOptions.renderSize.width / sqSize )
                    
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(.clear.opacity(0.8), lineWidth: 2.0)
                        .overlay {
                            centerAxisIndicator
                        }
                        .offset(x: onDragTextLayerPos.x, y: onDragTextLayerPos.y)
                        .frame(width: extSize.width / selScale, height: extSize.height / selScale)
                        .transformEffect(.init(translationX: valueOffX/selScale, y:(-valueOffY/selScale)))
                }
                .allowsHitTesting(selectedVideoToolbarItemIdx != nil)
                .overlay(alignment: .topTrailing, content: {
                    BlenderStyleToolbar()
                })
                .padding(.bottom, 32)
                .onAppear {
                    //Reload blender gizmo position
                    onDragTextLayerPos = .zero// .zero/// set current
                }


            VStack(spacing: 12) {
                BlenderStyleInput(value: $renderOptions.scaleVideo, title: "Scale", unitStr: "%", unitScale: 0.1, minValue: 0)
                    .padding(.bottom, 32)
                
                BlenderStyleInput(value: $renderOptions.videoSpeed, title: "Video Speed", unitStr: "%", unitScale: 0.1, minValue: 100)
                
                let durWSpeed = (renderOptions.videoDuration ?? 60.0) / (renderOptions.videoSpeed / 100)
                let durFloatStr = String(format: "Duration %.1fs", durWSpeed)
                Text(durFloatStr)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 240, alignment: .trailing)
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
            .padding(.trailing, 12)


        }
        .onChange(of: renderOptions.scaleVideo, perform: { _ in
            reloadOnlyThumbnail()
            self.reloadPreviewPlayerWithTimer()
        })
        .onChange(of: renderOptions.selectediPhoneColor) { newVal in
            renderOptions.selectediPhoneOverlay = newVal.image()
            self.reloadOnlyThumbnail()
        }
        .padding(.bottom, 120.0)
        .padding(.top, 16)
    }
    
    func reloadPreviewPlayerWithTimer() {
        
        self.timerForReloadPlayer?.invalidate()
        self.timerForReloadPlayer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
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
                        
                        let sqSizeOpt22: CGSize = .init(width: 1080, height: 1920)
                        ButtonRoundedRectForSize(sqSizeOpt22, selSize.equalTo(sqSizeOpt22)) {
                            self.renderOptions.renderSize = sqSizeOpt22

                        }
                        
                        let sqSizeOpt33: CGSize = .init(width: 1920, height: 1080)
                        ButtonRoundedRectForSize(sqSizeOpt33, selSize.equalTo(sqSizeOpt33)) {
                            self.renderOptions.renderSize = sqSizeOpt33

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
    func MockupStypeSelectionView() -> some View {
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

    }
    
    @ViewBuilder
    func OptionsEditorView() -> some View {
        VStack {

//            MockupStypeSelectionView()
            
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
                    optionsGroupSaved = new /// To save on user defaults
                    self.reloadOnlyThumbnail()
                }

                switch self.optionsGroup {
                case .Video:
                    VideoOptionsView()
                        .padding(.top, 16)
                case .Text:
                    TextLayerOptions()
                        .padding(.top, 16)
                case .Shadow:
                    ShadowOptionsView()
                        .padding(.top, 16)
                default:
                    EmptyView()
                }

            default:
                EmptyView()
            }
        }
    }

    func clarCreateGizmoValues() {
        self.newOrigin = nil
        self.regionEndPos = nil
    }
    
    @ViewBuilder
    func TextLayerOptions() -> some View {
        
        VStack(spacing: 12) {
            
            Text("Tap to add text")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(currentTxtLayer == nil ? Color.primary : Color.clear)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 32)
                
            
            let renderAspect = renderOptions.renderSize.width / renderOptions.renderSize.height
            let minSquareHeight: CGFloat = UIScreen.main.bounds.width
//            let maxWidth = minSquareHeight * renderAspect
            
            //// Square view to show frame and gestures
            RoundedRectangle(cornerRadius: 1.0, style: .continuous)
                .foregroundStyle(.gray.opacity(0.2))
                .frame(height: minSquareHeight)
                .padding(.horizontal, 0)
            /// Base Icon
                .overlay {
                    if let frameZeroImage {
                        Image(uiImage: frameZeroImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
            /// Done buttons for layers editing
                .overlay(alignment: .bottom) {
                    /// Done btn
                    if currentTxtLayer != nil {
                        Button {
                            deselectLayer()
                            //Deselect tool
                            selectedTextToolbarItemIdx = nil
                        } label: {
                            Text("Done")
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0.0, y: 0.0)
                        }
                        .foregroundStyle(.primary.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .offset(y: 24)
                        .padding(.trailing, 8)
                        .opacity(selectedEditingTextIdx == nil ? 1.0 : 0.0)
                    }
                    
                }
            /// On drag create text yellow overlay
                .overlay {
                    
                    if selectedTextToolbarItemIdx == 0 {
                        
                        ZStack {
                            if let newOrigin {
                                Circle()
                                    .foregroundStyle(.black.opacity(0.2))
                                    .frame(width: 10, height: 10)
                                    .position(x: newOrigin.x, y: newOrigin.y)
                            }
                            
                            if let regionEndPos {
                                Circle()
                                    .foregroundStyle(.black)
                                    .frame(width: 10, height: 10)
                                    .position(x: regionEndPos.x, y: regionEndPos.y)
                            }

                            if let newOrigin, let regionEndPos {
                                Canvas { ctx, size in
                                    let rectWithRegions = rectForDots(newOrigin, regionEndPos)
                                    let path = CGMutablePath()
                                    path.addRect(rectWithRegions)
                                    ctx.stroke(Path(path), with: .color(.yellow))
                                }
                            }
                        }
//                        .opacity(isDraggingIcon ? 1 : 0)
                    }
                }
                .padding(.bottom, 16)
            
            /// Gesture for add new text tool
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged({ value in
                            if selectedTextToolbarItemIdx != 0 { return }
                            if newOrigin == nil {
                                newOrigin = value.startLocation
                            }
                            regionEndPos = value.location
        //                    print("val \(value.location)")
                        })
                        .onEnded({ value in
        //                    print("ended")
                            
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//                                clearValues()
//                            })
                            
                        })
                )
                .simultaneousGesture(
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
//                            print("Val \(val.translation) preValueX \(preValueX) preValueY \(preValueY)")

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
                            
                            /// Val -width/2 - width/20
                            let xCords = (preValueX + minSquareHeight/2.0) / minSquareHeight //+ 1.0 // maxWidth
                            let yCords = (preValueY + minSquareHeight/2.0) / minSquareHeight// preValueY // minSquareHeight
                            
                            let coordinatesForRender = CGPoint(x: xCords, y: yCords)
//                            print("Coordinates for render \(xCords) \(yCords)")
                            
                            onDragTextLayerStartPos = onDragTextLayerPos
//                            onDragInitialLayerPos = onDragTextLayerPos
                            
                            self.isDraggingIcon = false
                            
                            if let currentTxtLayer {
                                currentTxtLayer.coordinates = coordinatesForRender
//                                onDragTextLayerPos = coordinatesForRender //rel
//                                onDragTextLayerStartPos = .zero
                                self.reloadPreviewPlayer()
                                return
                            }
                            
                            /// New Text layer
                            if selectedTextToolbarItemIdx == 0 {
                                
                                let rect = rectForDots(self.newOrigin ?? .zero, self.regionEndPos ?? .zero)
                                
                                let inputRect = rect
                                
                                let centeredBoxPosition = CGPoint(x:rect.midX / minSquareHeight, y: rect.midY / minSquareHeight) //
                                let coordinatesForRender = centeredBoxPosition //CGPoint(x: xCords, y: yCords)
                                addNewTextLayer(coordinatesForRender)
                                

                            }
                            
                        })
                )
                .onChange(of: (valueOffX + valueOffY) , perform: { value in
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

                    /// Ondrag move tool indicator
                    let selScale = renderOptions.renderSize.width / minSquareHeight
                    let extSize = AppState.shared.selTextExt ?? .zero
                    
                    let dragTextLayer = onDragTextLayerPos
//                    let _ = print("dragTextLayer \(dragTextLayer)")
                    
                    /// Selectes tood move
                    if selectedTextToolbarItemIdx == 1 {
                        
                        ZStack {
                            
                            /// Back gray circle
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(.green.opacity(0.0), lineWidth: 2.0)
                                .overlay {
                                    let minCircleSize = 6.0
                                    Circle()
                                        .foregroundStyle(.gray)
                                        .frame(width: minCircleSize, height: minCircleSize)
                                        .overlay {
                                            Circle()
                                                .stroke(.black, lineWidth: 1)
                                        }
                                }
                                .offset(x: onDragTextLayerStartPos.x, y: onDragTextLayerStartPos.y)
                                .frame(width: extSize.width / selScale, height: extSize.height / selScale)
//                                .allowsHitTesting(false)

                            /// Dashed line
                            Canvas { ctx, size in
                                /// Line for connect
                                /// Pos are in offset values, needds to convert
                                let initialPos = CGPoint(x: onDragTextLayerStartPos.x + size.width/2.0, y: onDragTextLayerStartPos.y + size.height/2.0) //minSquareHeight - onDragTextLayerStartPos.y
                                
                                let currentLineEnd = CGPoint(x: onDragTextLayerPos.x + size.width/2.0, y: onDragTextLayerPos.y + size.height/2.0)
                                
//                                currentLineEnd = .init(x: size.width, y: size.height)
//                                let rectWithRegions = rectForDots(newOrigin, regionEndPos)
                                let sizeOfLine = CGFloat((currentLineEnd.x - initialPos.x) * (currentLineEnd.x - initialPos.x)).squareRoot() + CGFloat( (currentLineEnd.y - initialPos.y) * (currentLineEnd.y - initialPos.y) ).squareRoot()
//                                print("Ct size \(size) initialPos \(initialPos) currentLineEnd \(currentLineEnd) sizeOfLine \(sizeOfLine)")

                                let path = CGMutablePath()
                                path.move(to: initialPos)
                                path.addLine(to: currentLineEnd)
                                
                                let dashPath = UIBezierPath()
                                
                                /// Not working
                                dashPath.lineCapStyle = .butt
                                dashPath.setLineDash([7.0, 7.0], count: 2, phase: 0.0)
                                dashPath.move(to: initialPos)
                                dashPath.addLine(to: currentLineEnd)
                                dashPath.close()

//                                let mutPath = path.cgPath
                                let phaseRel: CGFloat = sizeOfLine.truncatingRemainder(dividingBy: 7)// 7.0 //sizeOfLine.formRemainder(dividingBy: 7.0)
                                ctx.stroke(Path(path), with: .color(.black.opacity(0.9)), style: .init(lineWidth: 2.0, dash: [7, 7], dashPhase: phaseRel))
//                                ctx.stroke(Path(dashPath.cgPath), with: .color(.red))
                            }
//                            .stroke(.red)
//                            .frame(width: 390, height: 390)
//                            .allowsHitTesting(false)

                            
                            /// Blender style icon
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(.orange.opacity(0.89), lineWidth: 2.0)
                                .overlay {
                                    centerAxisIndicator
                                }
                                .offset(x: onDragTextLayerPos.x, y: onDragTextLayerPos.y)
                                .frame(width: extSize.width / selScale, height: extSize.height / selScale)
//                                .allowsHitTesting(false)

                        }
                        .allowsHitTesting(false)
//                            .opacity(isDraggingIcon ? 1 : 0)
                        //                        .offset(x: relAbs.x, y: relAbs.y)
                    }
                }
                .onAppear {
                    if selectedTextToolbarItemIdx == 1 {
                        
                        let initialPosCoord: CGPoint = currentTxtLayer?.coordinates ?? .zero
                        
                        let coordsAbs = CGPointMake(initialPosCoord.x * minSquareHeight, initialPosCoord.y * minSquareHeight)
                        
                        onDragTextLayerPos = coordsAbs
                        onDragInitialLayerPos = coordsAbs
                        if let lyrI = AppState.shared.selIdx, let lyrVal = self.currentTxtLayer {
                            self.selectLayer(lyrI, lyrVal)
                            print("Set pos \(coordsAbs)")
                        }

//                        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.0, execute: {
//                        })
//                        self.reloadOnlyThumbnail()
                        
                    }
                }
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0.0, y: 0.0)
                .allowsHitTesting(selectedTextToolbarItemIdx != nil)
                .overlay(alignment: .topTrailing, content: {
                    BlenderStyleTextToolbar()
                })

            ///Selected layer data
            if let idx = AppState.shared.selIdx {

            Text("Selected Layer")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 32)

                //+ renderOptions.textLayers[idx].textStrikeStyle.rawValue
                SelectedLayerFontOptionsView(selIdx: idx)
                    .padding(.bottom, 32)
                    .overlay(alignment: .bottomTrailing) {
                        let maxElm: Int = 3
                        let limit = moreFontOptionsStateIdx >= maxElm
                        let moreStr = moreStateDir < 0 ? "Less" : "More"
                        Button {
//                            showExtraFontOptions = !showExtraFontOptions
                            print("moreFontOptionsStateIdx \(moreFontOptionsStateIdx)")
                            moreFontOptionsStateIdx += moreStateDir
                            if moreFontOptionsStateIdx > maxElm && moreStateDir == 1 {
                                moreStateDir = -1
                            }
                            if moreFontOptionsStateIdx < 1 && moreStateDir == -1 {
                                moreStateDir = 1
                            }
                        } label: {
                            Text(moreStr)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background {
                                    Capsule(style: .continuous)
                                        .foregroundStyle(Color.gray)
                                        .opacity(0.5)
                                }
                        }
                        .alignmentGuide(.bottom) { d in
                            d[.top]
                        }
                        .foregroundColor(.primary.opacity(0.9))
                    }
                    .padding(.trailing, 12)
                /// Update on change values
                    .onChange(of: (self.renderOptions.textLayers[idx].textFontSize + renderOptions.textLayers[idx].textFontWeight.rawValue +
                                   renderOptions.textLayers[idx].textRotation + renderOptions.textLayers[idx].textKerning + renderOptions.textLayers[idx].textLineSpacing +
                                   renderOptions.textLayers[idx].textTrackingStyle +
                                   renderOptions.textLayers[idx].textStrokeWidth
                                   
                                  ),  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: self.renderOptions.textLayers[idx].textColor,  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: self.renderOptions.textLayers[idx].textStrikeStyle,  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: self.renderOptions.textLayers[idx].textUnderlineStyle,  perform: { value in
                        self.reloadOnlyThumbnail()
                    }) 
                    .onChange(of: self.renderOptions.textLayers[idx].textTrackingEffect,  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: self.renderOptions.textLayers[idx].textStrokeColor,  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: self.renderOptions.textLayers[idx].zPosition,  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: self.renderOptions.textLayers[idx].shadowColor,  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: self.renderOptions.textLayers[idx].shadowOpacity,  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: self.renderOptions.textLayers[idx].shadowRadius,  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: (self.renderOptions.textLayers[idx].shadowOffset.x + self.renderOptions.textLayers[idx].shadowOffset.y),  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                    .onChange(of: (self.renderOptions.textLayers[idx].transformScale),  perform: { value in
                        self.reloadOnlyThumbnail()
                    })
                //$renderOptions.textLayers[selIdx].transformScale

//                renderOptions.textLayers[selIdx].textZPosition
            }
            
            
            /// Layers list
            LayersList()

            Rectangle()
                .foregroundStyle(.clear)
                .frame(height: 400)
        }
        
    }
    
    func calculateValues(_ rect: CGRect) {
        
        /// Calculate font to fit
        guard var txtLayerInfo = renderOptions.textLayers.last else { print("nono"); return }
        
        var didFitHeight: Bool = false
        
        while !didFitHeight {
            
            let attributes = videoComposer.fontDict(renderOptions, txtLayerInfo)
            print(" \(rect) attributes \(attributes)")

            let text = self.currentEditing
            let attrStringWithText = NSAttributedString(string: text, attributes: attributes)
            let sizeToFit = attrStringWithText.height(withConstrainedWidth: rect.width)
            if sizeToFit > rect.height {
                didFitHeight = true
            } else {
                txtLayerInfo.textFontSize += 4.0
            }
        }
        
    }
    
    @ViewBuilder
    func LayersList() -> some View {
        
        Text("Layers")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 32)

//        let invLayers = Array(self.renderOptions.textLayers.reversed())
        ///Layers
        VStack(spacing: 4) {
            ForEach(0..<self.renderOptions.textLayers.count, id: \.self) { idx in
                let layerText = renderOptions.textLayers[idx]
//                let isSel = AppState.shared.selIdx == idx
                CellLayerView(layerText, idx)
                    .contentShape(.rect)

            }
        }

    }
    
    func rectForDots(_ newOrigin: CGPoint, _ regionEndPos: CGPoint) -> CGRect {
        
        let minX = min(newOrigin.x, regionEndPos.x)
        let maxX = max(newOrigin.x, regionEndPos.x)
        
        let minY = min(newOrigin.y, regionEndPos.y)
        let maxY = max(newOrigin.y, regionEndPos.y)

        let regRect = CGRect.init(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return regRect
    }
    

    
    var centerAxisIndicator: some View {
        Rectangle()
            .stroke(.clear, lineWidth: 2.0)
            .overlay {
                BlenderStyleAxisView()
            }
    }
    
    @State private var lastLayerSel: Int?
    func deselectLayer() {
        
        if let lasSel = AppState.shared.selIdx {
            lastLayerSel = lasSel
        }
        
        currentTxtLayer = nil
        AppState.shared.selIdx = nil
//        selectedTextToolbarItemIdx = nil
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.1, execute: {
            self.reloadOnlyThumbnail()
        })
    }
    
    func createDraggingIconTextOverlay() {
        
    }
    
    @ViewBuilder
    func WeightTextOptions(_ selIdx: Int) -> some View {
        HStack {
            Text("Weight")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
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
    }
    
    
    @ViewBuilder
    func WeightStrikeTextOptions(_ selIdx: Int) -> some View {
        HStack {
            Text("Strike")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(width: 120, alignment: .trailing)

            let strikeOptions: [NSUnderlineStyle?] = [nil, .single, .double, .thick]
            let strikeOptTitle: [String] = ["no", "single", "double", "thick"]
                        
            Picker("", selection: $renderOptions.textLayers[selIdx].textStrikeStyle) {
                ForEach(0..<strikeOptions.count, id: \.self) { idx in
                    let weightTitle = strikeOptTitle[idx]
                    let strikeOpt = strikeOptions[idx]
                    Text(weightTitle)
                        .tag(strikeOpt)
                }
            }
            .pickerStyle(.segmented)

        }
    }
    
    @ViewBuilder
    func UnderlineTextOptions(_ selIdx: Int) -> some View {
        HStack {
            Text("Under")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(width: 120, alignment: .trailing)

            let strikeOptions: [NSUnderlineStyle?] = [nil, .single, .double, .thick]
            let strikeOptTitle: [String] = ["no", "single", "double", "thick"]
                        
            Picker("", selection: $renderOptions.textLayers[selIdx].textUnderlineStyle) {
                ForEach(0..<strikeOptions.count, id: \.self) { idx in
                    let weightTitle = strikeOptTitle[idx]
                    let strikeOpt = strikeOptions[idx]
                    Text(weightTitle)
                        .tag(strikeOpt)
                }
            }
            .pickerStyle(.segmented)

        }
    }

    var allCodeKeys: [String] {
        Array(self.imageBycodeKey.keys)
    }

//    @State private var showExtraFontOptions: Bool = false
    @ViewBuilder
    func SelectedLayerFontOptionsView(selIdx: Int) -> some View {
        
        VStack(spacing: 16) {
            
            let layerStr = renderOptions.textLayers[selIdx].textString
            let isCodeIncluded = allCodeKeys.contains(layerStr)
            
            if isCodeIncluded {
                BlenderStyleInput(value: $renderOptions.textLayers[selIdx].transformScale, title: "Scale", unitStr: "%", unitScale: 0.1, minValue: 0)
            } else {
                ColorPicker(selection: $renderOptions.textLayers[selIdx].textColor, label: {
                    Text("Color")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(width: 120, alignment: .trailing)
                })
                .background {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .onTapGesture {}
                }
                
                HStack {
                    Text("Edit")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(width: 120, alignment: .trailing)

                    Spacer()
                    Button {
                        self.currentEditing = renderOptions.textLayers[selIdx].textString
                        self.selectedEditingTextIdx = selIdx
                        self.focusedField = .text
                    } label: {
                        Image(systemName: "character.cursor.ibeam")
                            .font(.system(size: 13, weight: .bold))
                            .padding(8)
                            .background {
                                Circle()
                                    .foregroundStyle(.ultraThinMaterial)
                            }
                            .offset(x: 2)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .foregroundStyle(Color.primary.opacity(0.6))

                }
                .frame(maxWidth: .infinity)
                
                
                BlenderStyleInput(value: $renderOptions.textLayers[selIdx].textFontSize, title: "Font Size", unitStr: "px", unitScale: 0.5, minValue: 0)
                
                VStack(spacing: 16) {
                    
                    if moreFontOptionsStateIdx > 0 {
                        
                        WeightTextOptions(selIdx)
                        
                        BlenderStyleInput(value: $renderOptions.textLayers[selIdx].textKerning, title: "Kerning", unitStr: "px")
                        
                        if moreFontOptionsStateIdx > 1 {
                            
                            UnderlineTextOptions(selIdx)

                            WeightStrikeTextOptions(selIdx)
                            
                            
                            BlenderStyleInput(value: $renderOptions.textLayers[selIdx].textStrokeWidth, title: "Stroke Width", unitStr: ".px", unitScale: 1.0, minValue: -600, maxValue: 600)

                            ColorPicker(selection: $renderOptions.textLayers[selIdx].textStrokeColor, label: {
                                Text("Stroke")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .frame(width: 120, alignment: .trailing)
                            })
                            .background {
                                Rectangle()
                                    .foregroundStyle(.clear)
                                    .onTapGesture {}
                            }


                            if moreFontOptionsStateIdx > 2 {
                                
                                BlenderStyleInput(value: $renderOptions.textLayers[selIdx].shadowOffset.x, title: "Shadow X", unitStr: "px")
                                
                                BlenderStyleInput(value: $renderOptions.textLayers[selIdx].shadowOffset.y, title: "Y", unitStr: "px")
                                
                                BlenderStyleInput(value: $renderOptions.textLayers[selIdx].shadowRadius, title: "Blur", unitStr: "px", minValue: 0)
                                
                                BlenderStyleInput(value: $renderOptions.textLayers[selIdx].shadowOpacity, title: "Opacity", unitStr: "%", unitScale: 0.1, minValue: 0)
                                
                                ColorPicker(selection: $renderOptions.textLayers[selIdx].shadowColor, label: {
                                    Text("Color")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                        .frame(width: 120, alignment: .trailing)
                                })
                                .background {
                                    Rectangle()
                                        .foregroundStyle(.clear)
                                        .onTapGesture {}
                                }
                                
                                if moreFontOptionsStateIdx > 3 {
                                    
                                    BlenderStyleInput(value: $renderOptions.textLayers[selIdx].textLineSpacing, title: "Line Spacing", unitStr: "px")
                                    
                                    HStack {
                                        Text("Z Position")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                            .frame(width: 120, alignment: .trailing)
                                        
                                        
                                        Picker("", selection: $renderOptions.textLayers[selIdx].zPosition) {
                                            ForEach(0..<TextZPosition.allCases.count, id: \.self) { idx in
                                                let iPhoneColor = TextZPosition.allCases[idx]
                                                Text(iPhoneColor.rawValue)
                                                    .tag(iPhoneColor)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                    
                                    BlenderStyleInput(value: $renderOptions.textLayers[selIdx].textRotation, title: "Rotation", unitStr: "º")
                                }
                            }
                        }
                    }

                }
                
        //        let showExtraFontOptions = false
                

            }

        }

        

    }
    
    
    func addNewTextLayer(_ coordinatesForRender: CGPoint) {
        
        let newLayerText = RenderTextLayer()
        newLayerText.coordinates = coordinatesForRender
        newLayerText.textString = String(format: "")
        newLayerText.zPosition = .infront // harcoded - fix - jw
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now()) {
            
            self.selectedEditingTextIdx = self.renderOptions.textLayers.count
            
//            AppState.shared.selIdx = self.selectedEditingTextIdx
            
            self.currentEditing = newLayerText.textString
            self.focusedField = .text
            self.renderOptions.textLayers.append(newLayerText)
            
//            self.selectLayer(self.selectedEditingTextIdx ?? 0, newLayerText)
            
            self.reloadPreviewPlayerWithTimer()
        }
        
//        currentTxtLayer = newLayerText
        print("drag add sticker end \(coordinatesForRender)")
        
        didCreateNew = true
    }
    
    fileprivate func deleteLayerAction(_ idx: Int) {
        if idx == AppState.shared.selIdx {
            self.deselectLayer()
        }
        self.currentTxtLayer = nil
        renderOptions.textLayers.remove(at: idx)
        if idx == lastLayerSel {
            lastLayerSel = nil
        }
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
            .contentShape(.rect)
            .gesture(
                TapGesture()
                    .onEnded( {
                        let isSel = AppState.shared.selIdx == idx
                        if isSel {
                            deselectLayer()
                            print("Deselect")
                            return
                        }
//                        print("Select ly \(idx)")
                        didCreateNew = false
                        // Select frame
                        self.selectLayer(idx, layerText)
                        selectedTextToolbarItemIdx = 1 /// Will auto select last idx
                    })
            )
            
            
            Button {
                self.currentEditing = layerText.textString
                self.selectedEditingTextIdx = idx
                self.focusedField = .text
            } label: {
                Image(systemName: "character.cursor.ibeam")
                    .font(.system(size: 15, weight: .bold))
                    .padding(10)
                    .background {
                        Circle()
                            .foregroundStyle(.ultraThinMaterial)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .foregroundStyle(Color.primary.opacity(0.6))

            Menu {
                Button {
                    self.currentEditing = layerText.textString
                    self.selectedEditingTextIdx = idx
                    self.focusedField = .text

                } label: {
                    Label("Edit", systemImage: "character.cursor.ibeam")
                }
                
                Button {
//                    self.currentEditing = layerText.textString
//                    self.selectedEditingTextIdx = idx
//                    self.focusedField = .text

                } label: {
                    Label("QR", systemImage: "qrcode")
                }
                
                Button {
//                    self.currentEditing = layerText.textString
//                    self.selectedEditingTextIdx = idx
//                    self.focusedField = .text
                    selectCustomImage(for: idx)
                } label: {
                    Label("Custom", systemImage: "apple.terminal")
                }

                
                Button {
                    deleteLayerAction(idx)
                } label: {
                    Label("Delete", systemImage: "xmark")
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
        .photosPicker(isPresented: $showSignaturePicker, selection: $selectedSignatureItems, maxSelectionCount: 1, selectionBehavior: .default, matching: .images) //.all(of: [, .screenRecordings] //.videos
        /// Load when selected items change
        .onChange(of: selectedSignatureItems) { newSelectedItems in
            Task {
                try? await processSelectedSignatures(newSelectedItems)
            }
//                    processSelectedVideo(newSelectedItems)
        }

    }
    
    func processSelectedSignatures(_ newSelectedItems: [PhotosPickerItem]) async throws {
        
        guard let firsItem = newSelectedItems.first else { return }

        guard let type = firsItem.supportedContentTypes.first else {
            print("There is no supported type")
            return
        }
        

        print("Selected items \(newSelectedItems)")
        var itemImageURL: URL?
        
//        if firsItem.canLoadObject(ofClass: UIImage.self) {
//            firsItem.loadObject(ofClass: UIImage.self) { (image, error) in
//                        if let image = image as? UIImage {
//                                self.parent.images.append(image)
//                        } else {
//                                print("Could not load image", error?.localizedDescription ?? "")
//                        }
//                }
//        }
        
        if type.conforms(to: UTType.png) {
            print("PNG ")
//            firsItem.loadTransferable(type: Data.self) { res  in
//                //(data, error)
//                
//            }
            
            if let imgData = try await firsItem.loadTransferable(type: Data.self) {
                print("Loaded data \(imgData.count)")
//                print("")
//                itemVideoURL = video.url
                self.selectCustomImageData(imgData)
            } else {
                print("error png")
            }
            
        } else if type.conforms(to: UTType.jpeg) {
            print("JPG")
            if let imgData = try await firsItem.loadTransferable(type: Data.self) {
                print("Loaded data jpg \(imgData.count)")
//                print("")
//                itemVideoURL = video.url
                self.selectCustomImageData(imgData)
            } else {
                print("error png")
            }

        } else {
           print("no img")
       }

    }
    
    @State private var toSelectCustomIdx: Int?
    
    func selectCustomImage(for idx: Int ) {
        // Present image picker
        //Save tmp somewhere
        //Use it in render
        
//        let customImgURL = Bundle.main.url(forResource: "signaturex", withExtension: "png")!
//        guard let imgData = try? Data(contentsOf: customImgURL) else { return }
//        
        toSelectCustomIdx = idx
        self.showSignaturePicker = true
    }
    
    func selectCustomImageData(_ data: Data) {
        
        guard let idx = toSelectCustomIdx else {
            self.selectedSignatureItems = []
            print("no idx");
            return;
        }
        
        let customStr = renderOptions.textLayers[idx].textString
        
        guard !customStr.isEmpty else { print("empty"); return }

        print("Save data \(customStr)")
        imageBycodeKey[customStr] = data

        self.reloadOnlyThumbnail()
        self.reloadPreviewPlayerWithTimer()
        
        self.selectedSignatureItems = []
        toSelectCustomIdx = nil
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
        .textInputAutocapitalization(.never)
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
                    .frame(width: 80, height: 80)
                
                let titleStr = String(format: "%i x %i", Int(size.width), Int(size.height))
                Text(titleStr)
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .frame(width: 110, height: 110)
            
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(.gray.opacity(isSel ? 0.2 : 0.05))
            }
        }
        .foregroundColor(isSel ? .primary : .secondary.opacity(0.6))

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
                        
                        let selColOptn = renderOptions.selectediPhoneColor
                        let isSelB = renderOptions.selectediPhoneColor == .black
                        ButtonFormatDevices("iphone", "Black", isSelB) {
                            renderOptions.selectediPhoneColor = .black
                        }
                        
                        let isSelBl = renderOptions.selectediPhoneColor == .blue
                        ButtonFormatDevices("iphone", "Blue", isSelBl) {
                            renderOptions.selectediPhoneColor = .blue
                        }
                        
                        let isSelNa = renderOptions.selectediPhoneColor == .natural
                        ButtonFormatDevices("iphone", "Natural", isSelNa) {
                            renderOptions.selectediPhoneColor = .natural
                        }
                        
                        let isSelW = renderOptions.selectediPhoneColor == .white
                        ButtonFormatDevices("iphone", "White", isSelW) {
                            renderOptions.selectediPhoneColor = .white
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
                        self.reloadOnlyThumbnail()
                    }
                    
                    ButtonFormatDevices("iphone.landscape", "Landscape", renderOptions.selectedFormat == .landscape) {
                        renderOptions.selectedFormat = .landscape
                        self.reloadOnlyThumbnail()
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
                shoeVideosPicker = true
            } label: {
                OptionLabel("iphone.badge.play", "Media")
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.secondary)
            .photosPicker(isPresented: $shoeVideosPicker, selection: $selectedItems, maxSelectionCount: 1, selectionBehavior: .default, matching: .screenRecordings) //.all(of: [, .screenRecordings] //.videos
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
                 
            
            Button {
                self.shouldShake = videoComposer.isRendering
                saveImageAnimated()
                if !videoComposer.isRendering {
                    makeVideoWithComposition()
                }
            } label: {
                OptionLabel("square.and.arrow.down", "Save")
                    .opacity(renderState == .none ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.secondary)
            .overlay {
                if renderState != .none {
                    RenderStatusOverlay()
                        .overlay{
                            Text("Rendering")
                                .frame(width: 60)
                                .font(.system(size: 10))
                                .offset(y: 14)
                        }
                        .offset(y: -4)
                        .frame(maxWidth: .infinity)
                }
            }
            
        }
        .offset(y: horizontalSizeClass == .regular ? 0 : 0.0)
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
            // get info
            Task {
                guard let localID = firsItem.itemIdentifier else { return }
                let result = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
                if let asset = result.firstObject {
                    print("Got " + asset.debugDescription)
                    let longDateSting = asset.creationDate?.formatted(date: .complete, time: .complete)
                    self.videoInfoDate = longDateSting
                }

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
                    
                    updateVideoInfo(videoAsset)

                    self.renderOptions.selectedVideoThumbnail = thumbnail
                    self.renderOptions.selectedVideoURL = itemVideoURL

                    let filteredImg = videoComposer.createImagePreview(thumbnail, renderOptions: renderOptions, renderCustomCodeByKey: self.imageBycodeKey)
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
                let filteredImg = videoComposer.createImagePreview(actRender, renderOptions: renderOptions, renderCustomCodeByKey: self.imageBycodeKey)
                frameRenderImg = filteredImg
            }
            

        }
        
    }
    
    @ViewBuilder
    func OptionLabel(_ icon: String, _ title: String) -> some View {
        
        let iconSize: CGFloat = 24.0
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 18))
//                .offset(y: -2)
                .frame(width: iconSize, height: iconSize)
            
            Text(title)
                .font(.system(size: 12))
                .fontWeight(.semibold)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)


    }
    
    func updateVideoInfo(_ asset: AVURLAsset) {
        
        if let videoTrack = asset.tracks(withMediaType: .video).first {
            self.nativeVideoSize = videoTrack.naturalSize
            self.videoInfoFPS = CGFloat(videoTrack.nominalFrameRate)
        }

        let result = try? asset.url.resourceValues(forKeys: [URLResourceKey.fileSizeKey])

        if let result = result as? URLResourceValues {
            let resValues = (result.allValues[URLResourceKey.fileSizeKey] as? NSNumber)?.intValue ?? 0
//            print("resValues \(resValues)")
            videoSizeMB = CGFloat(resValues) / 1024.0 / 1024.0
        }
        videoInfoName = asset.url.lastPathComponent
        
        self.videoInfoDate = Date.now.formatted(date: .long, time: .complete)

        self.renderOptions.videoDuration = asset.duration.seconds

    }
    
    func setDefaultData() {
        //uiux-short
        //uiux-black-sound //uiux-black-sound
        self.renderOptions.selectedVideoURL = Bundle.main.url(forResource: "uiux-show3", withExtension: "mov")
        
        let asset = AVURLAsset(url: self.renderOptions.selectedVideoURL!)
        
        updateVideoInfo(asset)
//        var result: AnyObject?
        
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        Task {
            
            let imgPrevTime: CMTime = .zero
            let cgImage = try await generator.image(at: imgPrevTime).image
            guard let colorCorrectedImage = cgImage.copy(colorSpace: CGColorSpaceCreateDeviceRGB()) else { return }
            let thumbnail = UIImage(cgImage: colorCorrectedImage)

            await MainActor.run {
                self.renderOptions.selectedVideoThumbnail = thumbnail
                let filteredImg = videoComposer.createImagePreview(thumbnail, renderOptions: renderOptions, renderCustomCodeByKey: self.imageBycodeKey)
                self.renderOptions.selectedFiltered = filteredImg
                self.frameZeroImage = filteredImg
            }
            
            //// Debug add layer
//            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.1) {
//                        self.reloadPreviewPlayer()
//                
//                        // debug layer
//        
//                        let coordinatesForRender = CGPointMake(0.25, 0.5)
//        
//                        let newLayerText = RenderTextLayer()
//                        newLayerText.coordinates = coordinatesForRender
//                        newLayerText.textString = String(format: "hey")
//                        newLayerText.zPosition = .infront
//                        self.renderOptions.textLayers.append(newLayerText)
//                
//                        self.reloadPreviewPlayerWithTimer()
//                        self.selectedTextToolbarItemIdx = 1
//                        self.selectLayer(0, newLayerText)
//
//            }
        }

        
    }
    
    func selectLayer(_ idx: Int, _ layer: RenderTextLayer) {
        //                self.selectedEditingTextIdx = self.renderOptions.textLayers.count
        self.currentTxtLayer = layer // for selection movement
        AppState.shared.selIdx = idx // for selection

        let minSquareSize: CGFloat = UIScreen.main.bounds.width
        let scaleImg = renderOptions.renderSize.width / minSquareSize
        let initialPosCoord: CGPoint = currentTxtLayer?.coordinates ?? .zero
        
        let preValueX: CGFloat = initialPosCoord.x
        let preValueY: CGFloat = initialPosCoord.y
        
//        print("initialPosCoord idx \(idx) \(initialPosCoord)")

        /// Val -width/2 - width/20
        let xCordsForOffset = ((preValueX - 1.0) * minSquareSize) + (minSquareSize/2.0)//((minSquareSize/2.0) - (preValueX * minSquareSize)) - (minSquareSize/2.0)//2.0// (preValueX + ) / minSquareHeight //+ 1.0 // maxWidth
        let yCordsForOffset = ((minSquareSize/2.0) - ((1.0 - preValueY) * minSquareSize))// preValueY // minSquareHeight

        let ppp = CGPointMake(xCordsForOffset, yCordsForOffset)
        
//        valueOffX = 0.0 //xCordsForOffset * scaleImg
//        valueOffY = 0.0 //yCordsForOffset * scaleImg
        
        onDragTextLayerPos = ppp// .zero/// set current
        onDragTextLayerStartPos = ppp // set for gesture initial state
        
        self.reloadOnlyThumbnail()
        
//        print("Set pot \(ppp)")

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
        .preferredColorScheme(.light)
//        .addGrid()
}
//
//#Preview {
//    RenderLiveWithOptionsView()
//        .preferredColorScheme(.dark)
//}

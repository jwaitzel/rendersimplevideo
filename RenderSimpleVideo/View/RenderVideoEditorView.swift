//
//  RenderVideoEditorView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/8/24.
//

import SwiftUI
import AVKit
import CoreImage
import PhotosUI


struct RenderVideoEditorView: View {
        
    @State private var videoComposer: VideoComposer = .init()
    
    @Environment(\.containerNavPath) var navPath
    
    @State private var showImagePicker: Bool = false
    
    @State private var selectedItems: [PhotosPickerItem] = []
    
    @State private var showVideoOptions: Bool = false
    
    @StateObject var renderOptions: RenderOptions = .init()
    
    @State private var showRenderResultView: Bool = false
    
    enum RenderState {
        case none
        case rendering
        case finish
    }
    
    @State private var renderState: RenderState = .none
    @State private var renderProgress: CGFloat = 0
    
    @State private var renderVideoURL: URL?
    
    @ObservedObject var storeKit: StoreKitManager = .shared

    var body: some View {
        
        ZStack {
            
            gearSettingsButton
            
            centerContentRender

            bottomActiosButtons

        }
        .overlay(content: {
            if showVideoOptions {
                OptionsOverlayView()
                    .environmentObject(renderOptions)
            }
        })

        .onAppear {
            if renderOptions.selectedVideoURL == nil {
                self.setDefaultData()
            }
        }
        .overlay {
            if renderState == .rendering {
                Rectangle()
                    .foregroundStyle(.black.opacity(0.2))
                    .ignoresSafeArea()
                    .onTapGesture { }
            }
        }
    }
    
    var bottomActiosButtons: some View {
        VStack {
            
            let iconSize: CGFloat = 34.0
            let btnSquareSize: CGFloat = 64.0
            
            HStack(spacing: 16) {
                Button {
                    showImagePicker.toggle()
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "iphone.badge.play")
                            .font(.system(size: 24))
                            .frame(width:iconSize, height: iconSize)
                        
                        Text("Video")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(width:btnSquareSize, height: btnSquareSize)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.secondary.opacity(0.2))
                            .shadow(color: .black.opacity(0.5), radius: 2.0, x: 0, y: 2)
                    }
                }
                
                .foregroundStyle(.primary)
                .photosPicker(isPresented: $showImagePicker, selection: $selectedItems, maxSelectionCount: 1, selectionBehavior: .default, matching: .screenRecordings) //.all(of: [, .screenRecordings] //.videos
                /// Load when selected items change
                .onChange(of: selectedItems) { newSelectedItems in
                    processSelectedVideo(newSelectedItems)
                }
                
                Button {
                    showEditViewAction()
                } label: {
                    VStack(spacing: 2) {
                        
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 24))
                            .frame(width:iconSize, height: iconSize)
                        
                        Text("Options")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(width:btnSquareSize, height: btnSquareSize)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.secondary.opacity(0.2))
                            .shadow(color: .black.opacity(0.5), radius: 2.0, x: 0, y: 2)
                    }
                }
                .foregroundStyle(.primary)

            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .trailing) {
                Button {
//                    showRenderResultView = true
                    self.makeVideoWithComposition()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 24))
                        .offset(y: -2)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .foregroundStyle(.primary)
                                .shadow(color: .black.opacity(0.4), radius: 2.0, x: 0, y: 2)
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .sheet(isPresented: $showRenderResultView, content: {
            if let renderVideoURL {
                ResultRenderView(videoURL: renderVideoURL)
            }
        })
    }
    
    var centerContentRender: some View {
        VStack {
            Rectangle()
                .foregroundStyle(renderOptions.backColor)
                .frame(width: 360, height: 360)
                .overlay {
                    if let thumb = renderOptions.selectedFiltered {
                        Image(uiImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 4.0, x: 0, y: 3)
                .overlay {
                    if renderState != .none {
                        RenderStatusOverlay()
                    }
                }
                .padding(.bottom, 84)
        }
    }
    
    @State private var showRequestFeatureForm: Bool = false

    var gearSettingsButton: some View {
        HStack(spacing: 0) {
            Button {
                showRequestFeatureForm = true
            } label: {
                Image(systemName: "star.bubble")
                    .frame(width: 44, height: 44, alignment: .trailing)
                    .offset(y: 1)
            }
//            .border(Color.black)
            
            Button {
                navPath.wrappedValue.append(Routes.settings)
            } label: {
                Image(systemName: "gearshape")
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color.secondary)
            }
//            .border(Color.black)
        }
        .foregroundStyle(Color.secondary)
        .font(.system(size: 24, weight: .light))
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 10)
        .sheet(isPresented: $showRequestFeatureForm, content: {
            SendRequestFormView()
        })

    }
    
    @ViewBuilder
    func RenderStatusOverlay() -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .foregroundStyle(.ultraThinMaterial)
            .frame(width: 200, height: 200)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .overlay {
                VStack(spacing: 16) {
                    
                    if renderState == .rendering {
                        Text("Rendering...")
                            .font(.subheadline)

                        ProgressView(value: self.renderProgress, total: 1.0)
                            .padding(.horizontal, 16)
                            .progressViewStyle(.automatic)
                    } else if renderState == .finish {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 44))
                            .fontWeight(.light)
                            .foregroundStyle(.green)
                    }
                }
            }
    }
    
    @ViewBuilder
    func OptionsOverlayView() -> some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Color.black.opacity(0.6))
                .ignoresSafeArea()

            Rectangle()
                .foregroundStyle(.ultraThinMaterial)
                .contentShape(.rect)
//                .onTapGesture {
//                    withAnimation(.linear(duration: 0.23)) {
//                        showVideoOptions = false
//                    }
//                }
                .ignoresSafeArea()

            VideoOptionsView(screenImage: self.renderOptions.selectedVideoThumbnail!)
                .transition(.scale.combined(with: .opacity))
                .overlay(alignment: .topTrailing) {
                    Button {
                        withAnimation(.linear(duration: 0.23)) {
                            showVideoOptions = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 32))
                            .padding(.trailing, 14)
                    }
                    .foregroundColor(.secondary)
                    .offset(y: -12)
                    
                }

        }
    }
    
    //MARK: - Make video
    func makeVideoWithComposition() {
        
        guard let baseVideoURL = renderOptions.selectedVideoURL else { print("missing base video"); return }
        let outputURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(for: .mpeg4Movie)
        DispatchQueue.main.async {
            self.renderState = .rendering
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
                    print("set thumbnail \(thumbnail)")
                }
            }
           
        }
        
    }
    
    func setDefaultData() {
        //uiux-short
        //uiux-black-sound //uiux-black-sound
        
        
        self.renderOptions.selectedVideoURL = Bundle.main.url(forResource: "uiux-show3", withExtension: "mp4")
        let defaultThumb = UIImage(contentsOfFile: Bundle.main.url(forResource: "screencap1", withExtension: "jpg")!.path)!
        let asset = AVURLAsset(url: self.renderOptions.selectedVideoURL!)
        self.renderOptions.videoDuration = asset.duration.seconds
        self.renderOptions.selectedVideoThumbnail = defaultThumb
        let filteredImg = videoComposer.createImagePreview(defaultThumb, renderOptions: renderOptions)
        self.renderOptions.selectedFiltered = filteredImg
                
    }
    
    func showEditViewAction() {
        withAnimation(.easeOut(duration: 0.23)) {
            showVideoOptions = true
        }
    }
    
}


#Preview {
//    RenderVideoEditorView()
    MainView()
//        .addGrid()
}

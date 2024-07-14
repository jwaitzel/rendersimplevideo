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
    
    @State private var player: AVPlayer?
    
    @State private var videoComposer: VideoComposer = .init()
    
    @Environment(\.containerNavPath) var navPath
    
    @State private var showImagePicker: Bool = false
    
    @State private var selectedItems: [PhotosPickerItem] = []
    
    @State private var showVideoOptions: Bool = false
    
    @StateObject var renderOptions: RenderOptions = .init()
    
    enum RenderState {
        case none
        case rendering
        case finish
    }
    
    @State private var renderState: RenderState = .none
    @State private var renderProgress: CGFloat = 0
    
    
    
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
    }
    
    var bottomActiosButtons: some View {
        VStack {
            
            let iconSize: CGFloat = 34.0
            let btnSquareSize: CGFloat = 64.0
            HStack {
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
                    }
                }
                .foregroundStyle(.primary)
                .photosPicker(isPresented: $showImagePicker, selection: $selectedItems, maxSelectionCount: 1, selectionBehavior: .default, matching: .videos) //.all(of: [, .screenRecordings]
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
                    }
                }
                .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .trailing) {
                Button {
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
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    var centerContentRender: some View {
        VStack {
            Rectangle()
                .foregroundStyle(renderOptions.backColor)
                .frame(width: 300, height: 300)
                .overlay {
                    if let thumb = renderOptions.selectedFiltered {
                        Image(uiImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .overlay {
                    if let player {
                        VideoPlayer(player: player)
                            .scaledToFit()
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
    
    var gearSettingsButton: some View {
        HStack {
            Button {
                navPath.wrappedValue.append(Routes.settings)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
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
                    self.player = AVPlayer(url: outputURL)
                    self.shareContent(videoURL: outputURL)
                    
                    DispatchQueue.main.async {
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
    
    func shareContent(videoURL: URL) {
        
        let itemsToShare = [videoURL] // Add more items if needed (e.g., URLs, images)
        
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        guard let rootVC = UIApplication.shared.connectedScenes.compactMap({$0 as? UIWindowScene}).first?.windows.first?.rootViewController else{
            return
        }

        rootVC.present(activityViewController, animated: true, completion: nil)
    }
    
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
        self.renderOptions.selectedVideoURL = Bundle.main.url(forResource: "uiux-short", withExtension: "mp4")
        let defaultThumb = UIImage(contentsOfFile: Bundle.main.url(forResource: "screencap1", withExtension: "jpg")!.path)!
        self.renderOptions.selectedVideoThumbnail = defaultThumb
        let filteredImg = videoComposer.createImagePreview(defaultThumb, renderOptions: renderOptions)
        self.renderOptions.selectedFiltered = filteredImg

    }
    
    @ViewBuilder
    func OptionsOverlayView() -> some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Color.black.opacity(0.6))
            
            Rectangle()
                .foregroundStyle(.ultraThinMaterial)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.linear(duration: 0.23)) {
                        showVideoOptions = false
        //                showOptionsBackground = false
                    }
                }

            VideoOptionsView(screenImage: self.renderOptions.selectedVideoThumbnail!)
                .transition(.scale.combined(with: .opacity))

        }
        .ignoresSafeArea()
    }
    
    func showEditViewAction() {
        withAnimation(.easeOut(duration: 0.3)) {
            showVideoOptions = true
        }
    }
    
    
}


#Preview {
//    RenderVideoEditorView()
    MainView()
}

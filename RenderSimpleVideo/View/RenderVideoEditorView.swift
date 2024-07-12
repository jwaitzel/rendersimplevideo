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
    
    var body: some View {
        
        ZStack {
            
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
            
            VStack {
                Rectangle()
                    .foregroundStyle(.gray.opacity(0.2))
                    .frame(width: 300, height: 300)
                    .overlay {
                        if let thumb = renderOptions.selectedVideoThumbnail {
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
                    .padding(.bottom, 64)
            }
            
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
                     .onChange(of: selectedItems) { newSelectedItem in
                         Task {
                             
                             guard let firsItem = newSelectedItem.first else { return }

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
                                 let thumbSize: CGSize = .init(width: 512, height: 512)
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
                                 }
                             }
                         }
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
        .overlay(content: {
            if showVideoOptions {
                OptionsOverlayView()
                    .environmentObject(renderOptions)
            }
        })
    }
    
    @ViewBuilder
    func OptionsOverlayView() -> some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Color.black.opacity(0.6))
            
            Rectangle()
                .foregroundStyle(.ultraThinMaterial)
            
            VideoOptionsView()
                .transition(.scale.combined(with: .opacity))

        }
        .ignoresSafeArea()
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.linear(duration: 0.23)) {
                showVideoOptions = false
//                showOptionsBackground = false
            }
        }
    }
    
    func showEditViewAction() {
        withAnimation(.easeOut(duration: 0.3)) {
            showVideoOptions = true
        }
    }
    
    func renderComposition() {
        
        let videoURL = Bundle.main.url(forResource: "screen2", withExtension: "mp4")!
        let outputURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(for: .mpeg4Movie)
        
        videoComposer.createAndExportComposition(videoURL: videoURL, outputURL: outputURL) { err in
            if let err {
                print("Error ", err)
            } else {
                print("Completed \(outputURL)")
                DispatchQueue.main.async {
                    self.player = AVPlayer(url: outputURL)
                }

            }
            
        }
    }
    
    func testCreateImageVideo() {
        
        let videoURL = Bundle.main.url(forResource: "screen2", withExtension: "mp4")!
        let videoAsset = AVURLAsset(url: videoURL)

        let backgroundImageURL = Bundle.main.url(forResource: "backt", withExtension: "jpg")!
        let imageRef = UIImage(contentsOfFile: backgroundImageURL.path())!.cgImage!
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("outputimg\(UUID().uuidString.prefix(4)).mp4")
        
        try? videoComposer.createVideoFromImage(imageRef, duration: videoAsset.duration.seconds, outputURL: outputURL) {
            print("Finished \(outputURL)")
        }
        
//        try? createVideoFromImage(imageRef, duration: videoAsset.duration.seconds, outputURL: outputURL, completion: {
//            print("finished making background video \(outputURL)")
//            
//            createAndExportComposition(backVideo: outputURL) { error in
//                print("error \(error)")
//            }
//            
//        })
        
    }
    
}


#Preview {
//    RenderVideoEditorView()
    MainView()
}

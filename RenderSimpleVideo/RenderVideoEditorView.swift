//
//  RenderVideoEditorView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/8/24.
//

import SwiftUI
import AVKit
import CoreImage

struct RenderVideoEditorView: View {
    
    @State private var player: AVPlayer?

    @State private var videoComposer: VideoComposer = .init()
    
    @Environment(\.containerNavPath) var navPath
    
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
//                        .background {
//                            Circle()
//                                .foregroundStyle(Color(uiColor: .systemGray2))
//                        }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 16)
            
            VStack {
                
                if let player {
                    VideoPlayer(player: player)
                        .scaledToFit()
                }
                                
            }
            
            VStack {
                
                HStack {
                    Button("Video") {
                        
                    }
                    
                    Button("Edit") {
                        
                    }
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
        
    }
    
    func renderComposition() {
        
        let videoURL = Bundle.main.url(forResource: "screen2", withExtension: "mp4")!
        let outputURL = URL.temporaryDirectory.appending(path: UUID().uuidString).appendingPathExtension(for: .mpeg4Movie)
//        let backVideoURL = URL.temporaryDirectory.appending(path: "outputimg19AF.mp4")
//        let backVideoURL = URL.temporaryDirectory.appending(path: "outputimg1DAA.mp4")
//        let backVideoURL = URL.temporaryDirectory.appending(path: "outputimgF166.mp4")
//        let videoAsset = AVURLAsset(url: videoURL)

//        let backgroundImageURL = Bundle.main.url(forResource: "backt", withExtension: "jpg")!
//        let imageRef = UIImage(contentsOfFile: backgroundImageURL.path())!.cgImage!
//        let outputBackVideoURL = FileManager.default.temporaryDirectory.appendingPathComponent("outputimg\(UUID().uuidString.prefix(4)).mp4")
        
        
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
//        try? videoComposer.createVideoFromImage(imageRef, duration: videoAsset.duration.seconds, outputURL: outputBackVideoURL) {
//            
//        }
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

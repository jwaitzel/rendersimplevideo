//
//  ResultRenderView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/16/24.
//

import SwiftUI
import AVKit
import Photos

struct ResultRenderView: View {
    
    var videoURL: URL
    @State private var player: AVPlayer?
    @State private var videoSaveResult: ResultSave?
    
    var body: some View {
        VStack {
            Rectangle()
                .foregroundStyle(Color(uiColor: .systemGray6))
                .frame(width: 300, height: 300)
                .overlay {
                    if let player {
                        VideoPlayer(player: player)
                            .scaledToFit()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 4.0, x: 0, y: 3)
                .padding(.bottom, 84)
            
            HStack(spacing: 32) {
                
                Button {
                    shareContent(videoURL: self.videoURL)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .offset(y: -2)
                        Text("Share")
                    }
                    .font(.headline)
                    .frame(width: 120)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .foregroundStyle(Color(uiColor: .systemGray5))
                    }
                    .shadow(color: .black.opacity(0.1), radius: 2.0, x: 0, y: 2)

                }
                
                Button {
                    saveAction()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .offset(y: -2)
                        Text("Save")
                    }
                    .font(.headline)
                    .frame(width: 120)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .foregroundStyle(Color(uiColor: .systemGray5))
                    }
                    
                }
                .overlay {
                    if let videoSaveResult {
                        ResultSaveOverlay(videoSaveResult)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 2.0, x: 0, y: 2)
            }
        }
        .onAppear {
            if self.player == nil {
                self.player = AVPlayer(url: self.videoURL)
                self.player?.play()
            }
        }
//        .overlay {
//            if let videoSaveResult {
//            }
//        }
    }
    
    func shareContent(videoURL: URL) {
        
        let itemsToShare = [videoURL] // Add more items if needed (e.g., URLs, images)
        
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        guard let rootVC = UIApplication.shared.connectedScenes.compactMap({$0 as? UIWindowScene}).first?.windows.first?.rootViewController?.presentedViewController else{
            return
        }

        rootVC.present(activityViewController, animated: true, completion: nil)
    }
    
    
    func saveAction() {
        
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .video, fileURL: self.videoURL, options: nil)
        }) { (result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print(error.localizedDescription)
                    self.videoSaveResult = .error
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.videoSaveResult = nil
                    }
                } else {
                    print("Saved successfully")
                    self.videoSaveResult = .succeed
                }
                
            }
        }

    }
    
    enum ResultSave {
        case error
        case succeed
    }
    
    @ViewBuilder
    func ResultSaveOverlay(_ res: ResultSave) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .foregroundStyle(.ultraThinMaterial)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
//            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .overlay {
                VStack(spacing: 16) {
                    
                    if res == .error {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 22))
                            .fontWeight(.light)
                            .foregroundStyle(.red)
                        
                    } else if res == .succeed {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 22))
                                .fontWeight(.light)
                                .foregroundStyle(.green)
                        }
                        
                    }
                }
            }
    }
}

#Preview {
    struct PreviewData: View {
        @State private var videoURL: URL = Bundle.main.url(forResource: "uiux-show3", withExtension: "mov")!
        var body: some View {
            ResultRenderView(videoURL: videoURL)
        }
        
    }
    
    return PreviewData()
}

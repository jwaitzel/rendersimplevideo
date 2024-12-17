//
//  VideoInfoView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 12/17/24.
//

import SwiftUI

struct VideoInfoView: View {
    
    var videoInfoDate: String?
    var videoInfoName: String = ""
    var nativeVideoSize: CGSize = .zero
    var videoSizeMB: CGFloat = 0
    var videoDuration: CGFloat?
    
    var body: some View {
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
                    
                    let durString = String(format: "%.2fs", videoDuration ?? 0.0)
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
}

#Preview {
    VideoInfoView(videoInfoDate: "12 jul", videoInfoName: "videotest", nativeVideoSize: .init(width: 1024, height: 1024), videoSizeMB: 1000, videoDuration: 1.3)
}

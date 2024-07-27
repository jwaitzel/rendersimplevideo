//
//  WelcomeSimpleModalView.swift
//  AnimatedZoomMap
//
//  Created by javi www on 7/3/24.
//

import SwiftUI

struct WelcomeSimpleModalView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 14) {
                Text("Welcome to \nSimple Video Mockup")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                
                Text("beautify your app demos instantly")
                    .font(.subheadline)
            }
            .padding(.horizontal, 24)
            .multilineTextAlignment(.center)
            .padding(.top, 64)
            VStack(alignment: .leading, spacing: 32) {
                
                let iconSquareSize: CGFloat = 70
                HStack {
                    
                    Image(systemName: "tag.slash")
                        .foregroundStyle(.tint)
                        .font(.system(size: 44))
                        .frame(width: iconSquareSize, height: iconSquareSize)
                    
                    VStack(alignment: .leading) {
                        Text("No watermark")
                            .fontWeight(.semibold)

                        Text("Just select your screen recording and save.")
                            .font(.callout)
                            .foregroundStyle(.primary.opacity(0.7))
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack {
                    
                    Image(systemName: "slider.horizontal.2.square")
                        .font(.system(size: 44))
                        .foregroundStyle(.tint)
                        .frame(width: iconSquareSize, height: iconSquareSize)

                    VStack(alignment: .leading) {
                        Text("Customize")
                            .fontWeight(.semibold)
                        
                        Text("Adjust video speed, add text and select bezels.")
                            .font(.callout)
                            .foregroundStyle(.primary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 44)
            .padding(.horizontal, 32)
            
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    WelcomeSimpleModalView()
}

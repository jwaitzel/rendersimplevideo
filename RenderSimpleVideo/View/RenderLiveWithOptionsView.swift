//
//  RenderLiveWithOptionsView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/23/24.
//

import SwiftUI

struct RenderLiveWithOptionsView: View {
    
    @State private var showOptions: Bool = false
    
    enum OptionsGroup: String, CaseIterable {
        case Video
        case Text
        case Shadow
    }
    
    @AppStorage("optionsGroup") var optionsGroup: OptionsGroup = .Video

    
    var body: some View {
        ZStack {
            let playerContainerSize: CGFloat = 396
            
            GeometryReader {
                let sSize: CGSize = $0.size
//                let _ = print("size \(sSize)")
                let centerY: CGFloat = (sSize.height - playerContainerSize) / 2.0
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .foregroundStyle(.gray.opacity(0.2))
                            .frame(width: playerContainerSize, height: playerContainerSize)
                            .ignoresSafeArea()

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
            
        }
        
    }
    
    @ViewBuilder
    func OptionsEditorView() -> some View {
        VStack {
            Picker("", selection: $optionsGroup) {
                ForEach(0..<OptionsGroup.allCases.count, id: \.self) { idx in
                    let iPhoneColor = OptionsGroup.allCases[idx]
                    Text(iPhoneColor.rawValue)
                        .tag(iPhoneColor)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

        }
    }
    
    var barButtons: some View {
        HStack {
            
            Button{
                
            } label: {
                OptionLabel("iphone.badge.play", "Media")
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.secondary)
            
            Button{
                withAnimation(.easeInOut(duration: 0.23)) {
                    showOptions.toggle()
                }
            } label: {
                OptionLabel("slider.horizontal.3", "Options")
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(showOptions ? .white : .secondary)
            
            Spacer(minLength: 120)
            
            Button {
                
            } label: {
                OptionLabel("square.and.arrow.down", "Save")
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.secondary)
        }
        .background {
            Rectangle()
                .foregroundStyle(.ultraThinMaterial) ////red
                .ignoresSafeArea()
                .frame(height: 100)
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

    }
    
    
    @ViewBuilder
    func OptionLabel(_ icon: String, _ title: String) -> some View {
        let iconSize: CGFloat = 32.0
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .offset(y: -2)
                .frame(width: iconSize, height: iconSize)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)


    }
}

#Preview {
    RenderLiveWithOptionsView()
        .preferredColorScheme(.dark)
}

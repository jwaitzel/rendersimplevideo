//
//  BlenderStyleInput.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/11/24.
//

import SwiftUI

struct BlenderStyleInput: View {
    
    @Binding var value: CGFloat //= 0.0
    @State private var startValue: CGFloat = 0.0
    
    var title: String

    var body: some View {
        ZStack {
            HStack {
                
                Text(title)
                    .frame(width: 120, alignment: .trailing)
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .foregroundStyle(Color(uiColor: .systemGray6))
                    
                    let opOffX: (CGFloat)->() = {
                        value += $0
                        startValue = value
                    }
                    HStack {
                        Button {
                            opOffX(-1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .frame(width: 34, height: 34)
                                .background {
                                    Color(uiColor: .systemGray5)
                                }
                                
                        }
                        
                        Text("\(Int(value)) px")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                        
                        Button {
                            opOffX(1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .frame(width: 34, height: 34)
                                .background {
                                    Color(uiColor: .systemGray5)
                                }
                        }
                        
                    }
                    .contentShape(.rect)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ val in
                                value = val.translation.width + startValue
                            })
                            .onEnded({ _ in
                                startValue = value
                            })
                    )
                }
                .frame(height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                
            }
        }
    }
}

#Preview {
    struct Prev: View {
        @State private var offX: CGFloat = 0
        var body: some View {
            BlenderStyleInput(value: $offX, title: "Position X")
        }
    }
    return Prev()
}

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
    var unitStr: String = "px"
    var unitScale: CGFloat = 1.0
    var minValue: CGFloat?
    var maxValue: CGFloat?

    var body: some View {
        ZStack {
            HStack {
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 120, alignment: .trailing)
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .foregroundStyle(Color(uiColor: .systemGray6))
                    
                    let opOffX: (CGFloat)->() = {
                        value = applyMinMax(value + $0)
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
                                .opacity(0.08)
                        }
                        .foregroundStyle(.primary.opacity(0.07))
                        
                        Text("\(Int(value)) \(unitStr)")
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
                                .opacity(0.08)
                        }
                        .foregroundStyle(.primary.opacity(0.07))
                        
                    }
                    .contentShape(.rect)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ val in
                                let preValue = val.translation.width  * unitScale + startValue
                                value = applyMinMax(preValue)
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
        .onAppear {
            startValue = value
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
}

#Preview {
    struct Prev: View {
        @State private var offX: CGFloat = 100
        var body: some View {
            BlenderStyleInput(value: $offX, title: "Scale", unitStr: "%", unitScale: 0.1, minValue: 100, maxValue: 200)
//            BlenderStyleInput(value: $offX, title: "Position X", unitStr: "px")

        }
    }
    return Prev()
}

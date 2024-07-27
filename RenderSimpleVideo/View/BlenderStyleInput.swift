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
    
    @State private var animateShowAlpha: Bool = false

    @State private var timerForOut: Timer?
    
    @State private var animateAlphaDistance: CGFloat = 0.0
    
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
                        
                        let alphaForLeft: CGFloat = animateAlphaDistance < 0 && animateShowAlpha ? 0.9 : 0.02
                        Button {
                            opOffX(-1)
                            self.animateAndStartOut()
                        } label: {
                            Image(systemName: "chevron.left")
                                .frame(width: 34, height: 34)
                                .background {
                                    Color(uiColor: .systemGray5)
                                        .opacity(alphaForLeft)
                                }
//                                .opacity(animateShowAlpha ? 0.04 : 0.8)
                        }
                        .foregroundStyle(.primary.opacity(alphaForLeft))
//                        .opacity(animateAlphaDistance < 0 ? 1.0 : 0.9)
                        
                        Text("\(Int(value)) \(unitStr)")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                        
                        let alphaForRight = animateShowAlpha && animateAlphaDistance > 0 ? 0.9 : 0.02

                        Button {
                            opOffX(1)
                            self.animateAndStartOut()
                        } label: {
                            Image(systemName: "chevron.right")
                                .frame(width: 34, height: 34)
                                .background {
                                    Color(uiColor: .systemGray5)
                                        .opacity(alphaForRight)
                                }
                        }
                        .foregroundStyle(.primary.opacity(alphaForRight))
//                        .opacity(animateAlphaDistance > 0 ? 1.0 : 0.9)

                    }
                    .contentShape(.rect)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ val in
                                let preValue = val.translation.width  * unitScale + startValue
                                value = applyMinMax(preValue)
                                
                                animateAlphaDistance = val.translation.width
                                animateAndStartOut()
                            })
                            .onEnded({ _ in
                                startValue = value
                                animateAndStartOut()
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
    
    func animateAndStartOut() {
        
        self.timerForOut?.invalidate()
        if animateShowAlpha == false {
            withAnimation(.linear(duration: 0.23).delay(0.09)) {
                self.animateShowAlpha = true
            }
        }
        
        self.timerForOut = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
            withAnimation(.linear(duration: 0.23).delay(0.09)) {
                self.animateShowAlpha = false
            }
        })
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
            BlenderStyleInput(value: $offX, title: "Scale", unitStr: "px", unitScale: 0.1, minValue: -200, maxValue: 200)
                .preferredColorScheme(.dark)
//            BlenderStyleInput(value: $offX, title: "Position X", unitStr: "px")

        }
    }
    return Prev()
}

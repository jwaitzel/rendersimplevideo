//
//  RenderTextLayer.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/26/24.
//

import SwiftUI

enum TextZPosition: String, CaseIterable {
    case behind
    case infront
}


class RenderTextLayer: ObservableObject {
    
    @Published var textString = ""
    @Published var coordinates = CGPoint.zero
    @Published var zPosition: TextZPosition = .behind

    @Published var textScale: CGFloat = 100
    @Published var textColor: Color = .black
    @Published var textRotation: CGFloat = 0
    @Published var textKerning: CGFloat = 0
    @Published var textLineSpacing: CGFloat = 0
    @Published var textFontSize: CGFloat = 64
    @Published var textFontWeight: UIFont.Weight = .bold
    @Published var textStrikeStyle: NSUnderlineStyle? = nil //NSUnderlineStyle.single//.none
    @Published var textUnderlineStyle: NSUnderlineStyle? = nil //NSUnderlineStyle.single//.none
    @Published var textTrackingStyle: CGFloat = 0
    @Published var textTrackingEffect: NSAttributedString.TextEffectStyle? = .letterpressStyle

    @Published var textStrokeWidth: CGFloat = 0.0
    @Published var textStrokeColor: Color = .black
    
//    shadowOffset
//    shadowRadius
//    shadowOpacity
    
    @Published var shadowOffset: CGPoint = .zero
    @Published var shadowRadius: CGFloat = 4.0
    @Published var shadowOpacity: CGFloat = 80

    @Published var shadowColor: Color = .black

//    overlayTextFontSize
//    overlayTextFontWeight
}

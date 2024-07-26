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
    @Published var textZPosition: TextZPosition = .behind
    @Published var textFontSize: CGFloat = 44
    @Published var textFontWeight: UIFont.Weight = .bold

//    overlayTextFontSize
//    overlayTextFontWeight
}

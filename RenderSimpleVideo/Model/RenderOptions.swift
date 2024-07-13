//
//  RenderOptions.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/12/24.
//

import SwiftUI

class RenderOptions: ObservableObject {
    
    @Published var selectedVideoURL: URL?
    @Published var selectedVideoThumbnail: UIImage?
    @Published var selectedFiltered: UIImage?

    @Published var backColor: Color = Color(uiColor: .systemGray6)// .pink// .init(hue: 217.0/360.0, saturation: 77.0/100.0, brightness: 97.0/100.0)
    
    @Published var offsetX: CGFloat = 0.0
    @Published var offsetY: CGFloat = 0.0
    
    @Published var scaleVideo: CGFloat = 90.0
    @Published var maskCorners: CGFloat = 55.0
    
    @Published var renderSize: CGSize = .init(width: 1024, height: 1024)
    
}


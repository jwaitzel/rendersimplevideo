//
//  RenderOptions.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/12/24.
//

import SwiftUI

enum iPhoneColorOptions: String, CaseIterable {
    case black
    case blue
    case natural
    case white
    
    func image() -> UIImage {
        var imgName = "iPhone 15 Pro - Black Titanium - Portrait"
        switch self {
        case .black:
            imgName = "iPhone 15 Pro - Black Titanium - Portrait"
        case .blue:
            imgName = "iPhone 15 Pro - Blue Titanium - Portrait"
        case .natural:
            imgName = "iPhone 15 Pro - Natural Titanium - Portrait"
        case .white:
            imgName = "iPhone 15 Pro - White Titanium - Portrait"
        }
        
        var imgURL: URL = Bundle.main.url(forResource: imgName, withExtension: "png")!
        let iphoneOverlayImg = UIImage(contentsOfFile: imgURL.path)!
        return iphoneOverlayImg
    }
}

enum TextZPosition: String, CaseIterable {
    case Behind
    case Infront
}

class RenderOptions: ObservableObject {
    
    @Published var selectedVideoURL: URL?
    @Published var selectedVideoThumbnail: UIImage?
    @Published var selectedFiltered: UIImage?
    
    @Published var renderSize: CGSize = .init(width: 1024, height: 1024)

    @Published var offsetX: CGFloat = 0.0
    @Published var offsetY: CGFloat = 0.0
    
    @Published var scaleVideo: CGFloat = 90.0
    @Published var scaleMask: CGFloat = 94.0
    @Published var maskCorners: CGFloat = 55.0
    
    @Published var videoSpeed: CGFloat = 100.0

    @Published var selectediPhoneOverlay: UIImage?
    @Published var selectediPhoneColor: iPhoneColorOptions = .black
    
    @Published var backColor: Color = Color(uiColor: .systemGray6)// .pink// .init(hue: 217.0/360.0, saturation: 77.0/100.0, brightness: 97.0/100.0)

    @Published var shadowOffset: CGPoint = .zero
    @Published var shadowRadius: CGFloat = 16
    @Published var shadowOpacity: CGFloat = 80.0
    
    @Published var overlayText: String = "TEST"
    @Published var overlayTextOffset: CGPoint = .zero
    @Published var overlayTextFontSize: CGFloat = 44
    @Published var overlayTextFontWeight: UIFont.Weight = .bold
    @Published var overlayTextScale: CGFloat = 100
    @Published var overlayTextColor: Color = .black
    @Published var overlayTextRotation: CGFloat = 0
    @Published var overlayTextZPosition: TextZPosition = .Behind

    init() {
        self.selectediPhoneOverlay = selectediPhoneColor.image()
    }
    
}


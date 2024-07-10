//
//  VideoOptionsView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/10/24.
//

import SwiftUI

struct VideoOptionsView: View {
    var body: some View {
        VStack {
            let uiImg = UIImage(contentsOfFile: Bundle.main.url(forResource: "screencap1", withExtension: "jpg")!.path)!
            Image(uiImage: uiImg)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200)
        }
        
    }
}

#Preview {
    VideoOptionsView()
}

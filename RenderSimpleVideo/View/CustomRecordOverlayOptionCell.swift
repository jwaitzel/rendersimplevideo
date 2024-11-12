//
//  CustomRecordOverlayOptionCell.swift
//  RenderSimpleVideo
//
//  Created by javi www on 10/10/24.
//

import SwiftUI

struct CustomRecordOverlayOptionCell: View {
    
    @Binding var recordIndicatorOverlayText: String
    @Binding var showRecordOverlayTextInput: Bool
    
    
    var body: some View {
        VStack {
            
            Text("Custom Record Indicator Overlay")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 16)

            
            Button {
                showRecordOverlayTextInput = true
            } label: {
                Capsule(style: .continuous)
                    .foregroundStyle(.red)
                    .frame(width: 30, height: 16)
                    .scaleEffect(2.0)
                    .overlay {
                        Text(recordIndicatorOverlayText)
                            .foregroundStyle(.white)
                            .font(.system(size: 14, weight: .bold, design: .default))
                            .frame(width: 50)
                    }
            }
            
        }
        .padding(.bottom, 32)
        
    }
}

#Preview {
    CustomRecordOverlayOptionCell(recordIndicatorOverlayText:.constant("4:20"), showRecordOverlayTextInput: .constant(true))
}

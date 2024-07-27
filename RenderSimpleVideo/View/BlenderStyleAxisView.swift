//
//  BlenderStyleAxisView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/28/24.
//

import SwiftUI

struct BlenderStyleAxisView: View {
    
    let minCircleSize: CGFloat = 6.0
    let minCircleDashSize: CGFloat = 46.0
    
    var body: some View {
        let rect = CGRect(x: 0, y: 0, width: 80, height: 80)
        Rectangle()
            .stroke(.clear, lineWidth: 3.0)
            .overlay {
                centerCircleOrange
            }
            .overlay {
                centerDashCircle
            }
            .overlay {
                centerCrossLines
                    .mask {
                        maskCross
                    }
            }
            .frame(width: 60, height: 60)
    }
    
    var maskCross: some View {
        ZStack {
              Rectangle() // destination
                
              Circle()    // source
                .frame(width: 22, height: 22)
                .blendMode(.destinationOut)
            }
            .compositingGroup()

    }

    
    var centerCircleOrange: some View {
        Circle()
            .foregroundStyle(.orange)
            .frame(width: minCircleSize, height: minCircleSize)
            .overlay {
                Circle()
                    .stroke(.black, lineWidth: 1)
            }

    }
    
    var centerDashCircle: some View {
        ZStack {
            let dashP = 9.0
            let dashOFf = 12.1
            Circle()
                .stroke(.red, style: StrokeStyle(lineWidth: 2,  dash: [dashP], dashPhase: dashOFf))
                .frame(width: minCircleDashSize, height: minCircleDashSize)
            
            Circle()
                .stroke(.white, style: StrokeStyle(lineWidth: 2,  dash: [dashP], dashPhase: dashOFf + dashP))
                .frame(width: minCircleDashSize, height: minCircleDashSize)
        }
    }
    
    var centerCrossLines: some View {
        Canvas { ctx, size in
            
            let newPath = CGMutablePath()
            newPath.move(to: .init(x: 0.0, y: size.height/2.0))
            newPath.addLine(to: .init(x: size.width, y: size.height/2.0))
            newPath.closeSubpath()
            
            newPath.move(to: .init(x: size.width/2.0, y: 0.0))
            newPath.addLine(to: .init(x: size.width/2.0, y: size.height))
            newPath.closeSubpath()

            newPath.closeSubpath()
            ctx.stroke(Path(newPath), with: .color(.black))
        }
    }
    

}

#Preview {
    BlenderStyleAxisView()
        .background {
            Color.gray
        }
}

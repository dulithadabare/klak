//
//  IncomingMessageShape.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-05.
//

import SwiftUI

struct IncomingMessageShape: Shape {
    var addTail: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = CGFloat(8)
        
        let leftBorderX = CGFloat(rect.minX + radius)
        
        // bottom right corner
        path.move(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
        
        //bottom border
        path.addLine(to: CGPoint(x: leftBorderX + radius, y: rect.maxY))
        
        // top left curve
        path.addQuadCurve(to: CGPoint(x: leftBorderX, y: rect.maxY - radius), control: CGPoint(x: leftBorderX, y: rect.maxY ))
        
        //add tail
        if addTail {
            let tailHeight = CGFloat(4)
            path.addQuadCurve(to: CGPoint(x: leftBorderX - radius, y: rect.maxY -  radius - tailHeight), control: CGPoint(x: leftBorderX - radius, y: rect.maxY - radius - tailHeight/5 ))
            path.addQuadCurve(to: CGPoint(x: leftBorderX, y: rect.maxY -  radius -  tailHeight - radius), control: CGPoint(x: leftBorderX , y: rect.maxY - radius - tailHeight ))
        }
        
        //left border
        path.addLine(to: CGPoint(x: leftBorderX, y: rect.minY + radius))
        
        // to left corner
        path.addQuadCurve(to: CGPoint(x: leftBorderX + radius, y: rect.minY), control: CGPoint(x: leftBorderX, y: rect.minY ))
        
        // top border
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        
        //lower right curve
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY ))
        
        
        
        // right border
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        
        // top right curve
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY ))
        
        return path
    }
}

struct IncomingMessageShape_Previews: PreviewProvider {
    static var previews: some View {
        IncomingMessageShape(addTail: false)

                    .frame(width: 200, height: 200)
    }
}

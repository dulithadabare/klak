//
//  CurrentSenderMessageShape.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-01-12.
//

import SwiftUI

struct CurrentSenderMessageShape: Shape {
    var isFromCurrentSender: Bool
    var addTail: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = CGFloat(8)
        
        // top right corner
        path.move(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        //top border
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        
        // top left curve
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + radius), control: CGPoint(x: rect.minX, y: rect.minY ))
        
        //left border
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
        
        // bottom right corner
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.maxY), control: CGPoint(x: rect.minX, y: rect.maxY ))
        
        // bottom border
        let rightBorderX = CGFloat(rect.maxX - radius)
        path.addLine(to: CGPoint(x: rightBorderX - radius, y: rect.maxY))
        
        //lower right curve
        path.addQuadCurve(to: CGPoint(x: rightBorderX, y: rect.maxY -  radius), control: CGPoint(x: rightBorderX, y: rect.maxY ))
        
        //add tail
        if addTail {
            let tailHeight = CGFloat(4)
            path.addQuadCurve(to: CGPoint(x: rightBorderX + radius, y: rect.maxY -  radius - tailHeight), control: CGPoint(x: rightBorderX + radius, y: rect.maxY - radius - tailHeight/5 ))
            path.addQuadCurve(to: CGPoint(x: rightBorderX, y: rect.maxY -  radius -  tailHeight - radius), control: CGPoint(x: rightBorderX , y: rect.maxY - radius - tailHeight ))
        }
        
        
        // right border
        path.addLine(to: CGPoint(x: rightBorderX, y: rect.minY + radius))
        
        // top right curve
        path.addQuadCurve(to: CGPoint(x: rightBorderX - radius, y: rect.minY), control: CGPoint(x: rightBorderX, y: rect.minY ))
        
        return path
    }
}

struct CurrentSenderMessageShape_Previews: PreviewProvider {
    static var previews: some View {
        CurrentSenderMessageShape(isFromCurrentSender: true, addTail: false)
            .frame(width: 300, height: 40)
            .background(Rectangle().stroke())
    }
}

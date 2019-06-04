//
//  CGRect.swift
//  Gravitate
//
//  Created by Nate Sesti on 6/19/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {
    func max() -> CGPoint {
        return CGPoint(x: maxX, y: maxY)
    }
    func mid() -> CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    func min() -> CGPoint {
        return CGPoint(x: minX, y: minY)
    }
    func centerOnPoint(point: CGPoint) -> CGRect {
        return CGRect(x: point.x - width/2.0, y: point.y - height/2.0, width: width, height: height)
    }
    init(width: CGFloat, height: CGFloat, centerOn: CGPoint) {
        self.init(x: centerOn.x - 0.5*width, y: centerOn.y - 0.5*height, width: width, height: height)
    }
    func corners() -> [CGPoint] {
        // 1=topleft, 2=topright, 3=bottomleft, 4=bottomright
        return [CGPoint(x: self.minX, y: self.minY), CGPoint(x: self.maxX, y: self.minY), CGPoint(x: self.minX, y: self.maxY), CGPoint(x: self.maxX, y: self.maxY)]
    }
}

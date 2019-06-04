//
//  CGPoint.swift
//  Gravitate
//
//  Created by Nate Sesti on 6/19/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import UIKit

extension CGPoint {
    static let one = CGPoint(x: 1.0, y: 1.0)
    static let mid = CGPoint(x: 0.5, y: 0.5)
    
    init(inside: CGRect) {
        let xPos = CGFloat(low: inside.minX, high: inside.maxX)
        let yPos = CGFloat(low: inside.minY, high: inside.maxY)
        self.init(x: xPos, y: yPos)
    }
}

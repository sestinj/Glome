//
//  CGVector.swift
//  Taco Tapper
//
//  Created by Nate Sesti on 6/24/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import UIKit

extension CGVector {
    init(from: CGPoint, to: CGPoint, multiplier: CGFloat) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        self.init(dx: dx*multiplier, dy: dy*multiplier)
    }
}

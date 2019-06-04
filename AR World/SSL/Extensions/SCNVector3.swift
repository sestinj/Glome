//
//  SCNVector3.swift
//  D4
//
//  Created by Nate Sesti on 8/25/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import ARKit

extension SCNVector3 {
    mutating func rotateY(by: Float) {
        let x2 = cos(by * x) - sin(by * z)
        let z2 = sin(by * x) + cos(by * z)
        x = x2
        y = z2
    }
    
}

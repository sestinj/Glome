//
//  CGFloat.swift
//  Gravitate
//
//  Created by Nate Sesti on 6/19/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import UIKit

extension CGFloat {
    init(low: CGFloat, high: CGFloat) {
        let range = high - low
        let num = arc4random_uniform(UInt32(range*1000.0))
        let final = CGFloat(num)/1000.0 + low
        self = final
    }
}

//
//  Double.swift
//  Taco Tapper
//
//  Created by Nate Sesti on 6/25/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation

extension Double {
    static func ^(lhs: Double, rhs: Double) -> Double {
        return pow(lhs, rhs)
    }
    init(bool: Bool) {
        if bool {
            self = 1.0
        } else {
            self = 0.0
        }
    }
}

//
//  Int.swift
//  Taco Tapper
//
//  Created by Nate Sesti on 6/25/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation

extension Int {
    static func ^(lhs: Int, rhs: Int) -> Int {
        return Int(pow(Double(lhs), Double(rhs)))
    }
}

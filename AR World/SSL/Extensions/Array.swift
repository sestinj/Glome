//
//  Array.swift
//  FaceControlled
//
//  Created by Nate Sesti on 7/17/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation

extension Array {
    func random() -> Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        let array = self
        return array[index]
    }
}

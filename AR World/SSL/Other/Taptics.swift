//
//  Taptics.swift
//  Taco Tapper
//
//  Created by Nate Sesti on 6/23/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import GameplayKit


func impact(style: UIImpactFeedbackStyle) {
    if #available(iOS 10.0, *) {
        let feedback = UIImpactFeedbackGenerator(style: style)
        feedback.impactOccurred()
    }
}

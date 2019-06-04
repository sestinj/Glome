//
//  UIColor.swift
//  Gravitate
//
//  Created by Nate Sesti on 6/19/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(low: CGFloat, high: CGFloat) {
        let r = CGFloat(low: 0, high: CGFloat(min(1.0, high*3)))
        let g = CGFloat(low: 0, high: CGFloat(min(1.0, high*3 - r)))
        let b = high*3 - r - g
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    convenience init(r: Int, g: Int, b: Int) {
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1.0)
    }
    
    func r() -> CGFloat {
        return self.cgColor.components![0]
    }
    func g() -> CGFloat {
        return self.cgColor.components![1]
    }
    func b() -> CGFloat {
        return self.cgColor.components![2]
    }
    func alpha() -> CGFloat {
        return self.cgColor.components![3]
    }
    
    func brighten(percentage: CGFloat) -> UIColor {
        return UIColor(red: percentage*(1.0 - self.r()) + self.r(), green: percentage*(1.0 - self.g()) + self.g(), blue: percentage*(1.0 - self.b()) + self.b(), alpha: self.alpha())
    }
}

//
//  CALayer.swift
//  Taco Tapper
//This is a cal
//  Created by Nate Sesti on 6/22/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import UIKit

extension CALayer {
    func animate(_ keyPath: String, from: Any, duration: Double, autoreverses: Bool = false) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = self.value(forKey: keyPath)
        animation.duration = duration
        animation.autoreverses = autoreverses
        self.add(animation, forKey: keyPath)
    }
    
    func roundCorners() {
        cornerRadius = min(frame.width, frame.height)/2
        masksToBounds = true
    }
    
    func addCircularBorder(color: UIColor, lineWidth: CGFloat) -> CAShapeLayer {
        let circle = CAShapeLayer()
        circle.path = UIBezierPath(ovalIn: bounds).cgPath
        circle.strokeColor = color.cgColor
        circle.fillColor = UIColor.clear.cgColor
        circle.lineWidth = lineWidth
        addSublayer(circle)
        return circle
    }
    
    func gradiate(color: UIColor) {
        let gradLayer = CAGradientLayer()
        gradLayer.colors = [color.cgColor, color.brighten(percentage: 0.85).cgColor]
        gradLayer.frame = frame
        gradLayer.name = "gradLayer"
        gradLayer.startPoint = CGPoint.zero
        gradLayer.endPoint = CGPoint.one
        addSublayer(gradLayer)
    }
    
    func alphaGradiate(color: UIColor) {
        let gradLayer = CAGradientLayer()
        gradLayer.colors = [color.cgColor, UIColor.clear.cgColor]
        gradLayer.frame = frame
        gradLayer.name = "gradLayer"
        gradLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        addSublayer(gradLayer)
    }
    
    func addHoles(paths: [UIBezierPath]) {
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.fillColor = UIColor.black.cgColor
        let path1 = UIBezierPath(rect: bounds)
        for path in paths {
            path1.append(path)
        }
        maskLayer.path = path1.cgPath
        maskLayer.fillRule = kCAFillRuleEvenOdd
        mask = maskLayer
    }
}

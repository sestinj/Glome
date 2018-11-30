//
//  DrawingView.swift
//  AR World
//
//  Created by Nate Sesti on 11/30/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit

class DrawingView: UIView {
    var drawColor = UIColor.red    // A color for drawing
    var lineWidth: CGFloat = 5              // A line width
    private var lastPoint: CGPoint!         // A point for storing the last position
    private var bezierPath: UIBezierPath!   // A bezier path
    private var pointCounter: Int = 0       // A counter of points
    private let pointLimit: Int = 128       // A limit of the points
    private var preRenderImage: UIImage!    // A pre-render image
    private var clearImage: UIImage!
    public func getImage() -> UIImage? {
        return preRenderImage
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initBezierPath()
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        initBezierPath()
    }
    
    func initBezierPath() {
        backgroundColor = .white
        bezierPath = UIBezierPath()
        bezierPath.lineCapStyle = .round
        bezierPath.lineJoinStyle = .round
    }
    
    func renderToImage() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
        if preRenderImage != nil {
            preRenderImage.draw(in: self.bounds)
        }
        
        
        bezierPath.lineWidth = lineWidth
        drawColor.setFill()
        drawColor.setStroke()
        bezierPath.stroke()
        
        preRenderImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if preRenderImage != nil {
            preRenderImage.draw(in: self.bounds)
        }
        
        bezierPath.lineWidth = lineWidth
        drawColor.setFill()
        drawColor.setStroke()
        bezierPath.stroke()
    }
    private var widthFactor: CGFloat = 1.0
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch: AnyObject? = touches.first
        lastPoint = touch!.location(in: self)
        pointCounter = 0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch: AnyObject? = touches.first
        var newPoint = touch!.location(in: self)
        
        widthFactor = CGVector(from: lastPoint, to: newPoint, multiplier: 1.0).magnitude()
        
        bezierPath.move(to: lastPoint)
        bezierPath.addLine(to: newPoint)
        lastPoint = newPoint
        
        pointCounter += 1
        
        if pointCounter == pointLimit {
            pointCounter = 0
            renderToImage()
            setNeedsDisplay()
            bezierPath.removeAllPoints()
        }
        else {
            setNeedsDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        pointCounter = 0
        renderToImage()
        setNeedsDisplay()
        bezierPath.removeAllPoints()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    @objc public func clear() {
        preRenderImage = nil
        bezierPath.removeAllPoints()
        setNeedsDisplay()
    }
    
    func hasLines() -> Bool {
        return preRenderImage != nil || !bezierPath.isEmpty
    }

}

//
//  CalloutViewController.swift
//  AR World
//
//  Created by Nate Sesti on 6/5/19.
//  Copyright © 2019 Nate Sesti. All rights reserved.
//

import UIKit
import MapKit
import Foundation

class CalloutViewController: UIViewController {

    private let arrowSideLength: CGFloat = 20.0
    
    public var shadowOffset: CGFloat = 2.0 {
        didSet {
            view.layer.sublayers?.removeAll(where: { (layer) -> Bool in
                return layer.name == "shadowLayer"
            })
            let _ = view.layer.addShadowLayer(self.shadowOffset)
        }
    }
    
    private var arrowLayer: CAShapeLayer!
    private var frame: CGRect
    private var point: CGPoint
    public init(size: CGSize, at point: CGPoint, _ parentVC: UIViewController) {
        var origin = point
        self.point = point
        if point.y > screen.height/2.0 {
            //View below arrow
            origin = CGPoint(x: (screen.width - size.width)/2.0, y: point.y - 2*arrowSideLength - size.height)
        } else {
            //View above arrow
            origin = CGPoint(x: (screen.width - size.width)/2.0, y: point.y + 2*arrowSideLength + size.height)
        }
        frame = CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
        super.init(nibName: nil, bundle: nil)
        parentVC.addChild(self)
        parentVC.view.addSubview(view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.frame = self.frame
        view.backgroundColor = .green
        let fx = UIVisualEffectView(frame: view.frame)
        fx.effect = UIBlurEffect(style: .light)
        view.addSubview(fx)
        parent!.view.addSubview(self.view)
        
        //Fade in
        view.layer.opacity = 1.0
        view.layer.animate("opacity", from: 0.0, duration: 0.6)

        let shadow = view.layer.addShadowLayer(shadowOffset)
        shadow.name = "shadowlayer"
        view.roundCorners(.allCorners, radius: 5.0)
        view.layer.masksToBounds = false
        view.layer.cornerRadius = 10.0

        arrowLayer = CAShapeLayer()
        let path = CGMutablePath()
        path.move(to: point)
        path.move(to: CGPoint(x: point.x - arrowSideLength/2.0, y: point.y + arrowSideLength*2.0/sqrt(3)))
        path.move(to: CGPoint(x: point.x + arrowSideLength/2.0, y: point.y + arrowSideLength*2.0/sqrt(3)))
        path.move(to: point)
        path.closeSubpath()
        arrowLayer.path = path
        arrowLayer.strokeColor = CGColor.black
        arrowLayer.fillColor = CGColor.white
        arrowLayer.backgroundColor = CGColor.white
        arrowLayer.zPosition = 10
        parent!.view.layer.addSublayer(arrowLayer)
        arrowLayer.addShadow(shadowOffset, color: .black)
    }
    
    override public func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        view.layer.opacity = 0.0
        view.layer.animate("opacity", from: 1.0, duration: 0.6)
        let _ = Timer(timeInterval: 0.6, repeats: false) { (timer) in
            super.dismiss(animated: flag, completion: completion)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

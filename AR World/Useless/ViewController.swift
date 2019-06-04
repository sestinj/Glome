//
//  ViewController.swift
//  D4
//
//  Created by Nate Sesti on 7/15/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class ViewController: AuthHandlerViewController, UIScrollViewDelegate {
    //Top level UI
    var lastVC = 2
    var appBorder: CAShapeLayer!
    var pinBorder: CAShapeLayer!
    var userBorder: CAShapeLayer!
    var topLine: CAShapeLayer!
    var topBackground: CAShapeLayer!
    
    var camView: UIView?
    var otherView: UIView?
    var camVC: CameraViewController!
    var mapVC: MapViewController!
    var otherVC: OtherViewController!
    
    
    //MARK: Outlets
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var purplePin: UIButton!
    @IBAction func pinPressed(_ sender: UIButton) {
        scrollView.scrollRectToVisible(CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), animated: true)
        purplePin.setImage(#imageLiteral(resourceName: "purplePin"), for: .normal)
        appTitle.setTitleColor(.black, for: .normal)
        userIcon.setImage(#imageLiteral(resourceName: "userIconBlack"), for: .normal)
        lastVC = 1
    }
    @IBAction func titlePressed(_ sender: UIButton) {
        scrollView.scrollRectToVisible(CGRect(x: view.frame.width, y: 0, width: view.frame.width, height: view.frame.height), animated: true)
        purplePin.setImage(#imageLiteral(resourceName: "clearPin"), for: .normal)
        appTitle.setTitleColor(vibrantPurple, for: .normal)
        userIcon.setImage(#imageLiteral(resourceName: "userIconBlack"), for: .normal)
        lastVC = 2
    }
    @IBAction func userIconPressed(_ sender: UIButton) {
        scrollView.scrollRectToVisible(CGRect(x: view.frame.width*2, y: 0, width: view.frame.width, height: view.frame.height), animated: true)
        
        
        purplePin.setImage(#imageLiteral(resourceName: "clearPin"), for: .normal)
        appTitle.setTitleColor(.black, for: .normal)
        userIcon.setImage(#imageLiteral(resourceName: "userIconPurple"), for: .normal)
        lastVC = 3
    }
    @IBOutlet weak var userIcon: UIButton!
    @IBOutlet weak var appTitle: UIButton!
    
    //MARK: Scrolling - This could be improved to be similar to Snapchat
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let cellWidth = view.frame.width
        let positionX = round(targetContentOffset.pointee.x / cellWidth) * cellWidth
        var frame = view.frame
        frame.origin.x = positionX
        scrollView.scrollRectToVisible(frame, animated: true)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let width = view.frame.width
        
        
        if x < 0.5*width {
            purplePin.setImage(#imageLiteral(resourceName: "purplePin"), for: .normal)
            appTitle.setTitleColor(.black, for: .normal)
            userIcon.setImage(#imageLiteral(resourceName: "userIconBlack"), for: .normal)
            lastVC = 1
        } else if x < 1.5*width {
            purplePin.setImage(#imageLiteral(resourceName: "clearPin"), for: .normal)
            appTitle.setTitleColor(vibrantPurple, for: .normal)
            userIcon.setImage(#imageLiteral(resourceName: "userIconBlack"), for: .normal)
            lastVC = 2
        } else {
            purplePin.setImage(#imageLiteral(resourceName: "clearPin"), for: .normal)
            appTitle.setTitleColor(.black, for: .normal)
            userIcon.setImage(#imageLiteral(resourceName: "userIconPurple"), for: .normal)
            lastVC = 3
        }
    }

    
    //MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeKeysInDatabase(from: "stuff", to: "message", in: .flagged, true)
        
//        referralDatabase.collection("codes").getDocuments { (querySnap, err) in
//            if let err = err {
//                print(err)
//            } else {
//                if let querySnap = querySnap {
//                    for doc in querySnap.documents {
//                        print(doc.documentID)
//                    }
//                }
//            }
//        }
        
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.frame.origin.y = -10
        
        mainVC = self
        //Load and place VCs
        mapVC = MapViewController(nibName: "MapViewController", bundle: nil)
        mapVC.parentVC = self
        camVC = CameraViewController(nibName: "CameraViewController", bundle: nil)
        camVC.parentVC = self
        otherVC = OtherViewController(nibName: "OtherViewController", bundle: nil)
        otherVC.parentVC = self
        otherVC.isRootBio = true
        camView = camVC.view
        otherView = otherVC.view
        self.addChild(mapVC)
        self.addChild(camVC)
        self.addChild(otherVC)
        self.scrollView.addSubview(mapVC.view)
        self.scrollView.addSubview(camVC.view)
        self.scrollView.addSubview(otherVC.view)
        mapVC.didMove(toParent: self)
        camVC.didMove(toParent: self)
        otherVC.didMove(toParent: self)
        
        var camFrame: CGRect = camVC.view.frame
        camFrame.origin.x = view.frame.width
        camVC.view.frame = camFrame
        
        var otherFrame: CGRect = otherVC.view.frame
        otherFrame.origin.x = 2 * view.frame.width
        otherVC.view.frame = otherFrame
        
        scrollView.contentSize = CGSize(width: view.frame.width * 3, height: view.frame.height)
        scrollView.scrollRectToVisible(camFrame, animated: true)
        
        
        //Setup top of screen icons and title and bar
        appTitle.layer.zPosition = 5
        userIcon.layer.zPosition = 5
        purplePin.layer.zPosition = 5
        if X() {
            appTitle.frame.origin.y += 22
            userIcon.frame.origin.y += 22
            purplePin.frame.origin.y += 22
        }
        
        topBackground = CAShapeLayer()
        topBackground.path = CGPath(rect: CGRect(x: 0, y: 83-150, width: view.frame.width, height: 150), transform: nil)
        topBackground.fillColor = UIColor.white.withAlphaComponent(0.5).cgColor
        view.layer.addSublayer(topBackground)
        topLine = CAShapeLayer()
        topLine.path = CGPath(rect: CGRect(x: 0, y: 83, width: view.frame.width, height: 3), transform: nil)
        view.layer.addSublayer(topLine)
        if !X() {
            topLine.frame.origin.y -= 22
            topBackground.frame.origin.y -= 22
        }
        
        
        //PopupView
        popUpView.layer.masksToBounds = true
        popUpView.layer.cornerRadius = popUpView.frame.width/2.0
//        popUpView.layer.opacity = 0.0
        
    }
    
    
    //****************************************************************************************
    //STUFF FOR POPUPVIEW ------------------------------------------------------------------**
    //****************************************************************************************
    //PopupView
    var popVC: PopupViewController?
    var popUpShown = false
    public func showPopUpView(type: PopUpType) {
        if popUpShown {
            return
        }
        popVC!.view.layer.zPosition = 1000
        popUpShown = true
        popVC!.popUpType = type
        popVC!.load()
        //Animate the view
        popUpView.layer.opacity = 1.0
        popUpView.alpha = 1.0
        let tempPos = popUpView.layer.position
        popUpView.layer.position.y -= popUpView.layer.frame.height/1.5
        popUpView.layer.animate(#keyPath(CALayer.position), from: tempPos, duration: 0.5)
        popUpView.layer.animate(#keyPath(CALayer.opacity), from: 0.0, duration: 0.5)
        let _ = Timer(timeInterval: 0.5, target: self, selector: #selector(makeImpact), userInfo: nil, repeats: false)
    }
    @objc func makeImpact() {
        impact(style: .light)
    }
    @objc func hidePopUpView() {
        if !popUpShown {
            return
        }
        popUpShown = false
        //Animate
//        popUpView.alpha = 0.0
//        popUpView.layer.opacity = 0.0
        let tempPos = popUpView.layer.position
        popUpView.layer.position.y += popUpView.layer.frame.height/1.5
        popUpView.layer.animate(#keyPath(CALayer.position), from: tempPos, duration: 0.5)
//        popUpView.layer.animate(#keyPath(CALayer.opacity), from: 1.0, duration: 0.5)
        let _ = Timer(timeInterval: 0.5, target: self, selector: #selector(makeImpact), userInfo: nil, repeats: false)
        for subview in popUpView.subviews {
            subview.removeFromSuperview()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Sets the popVC variable once it is loaded
        if let id = segue.identifier {
            if id == "popUpSegue" {
                if let authVC = segue.destination as? AuthHandlerViewController {
                    if let VC = authVC as? PopupViewController {
                        popVC = VC
                        popVC!.popUpType = .info
                        popVC!.parentVC = self
                    }
                }
            }
        }
    }
}

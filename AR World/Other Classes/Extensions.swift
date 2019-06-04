//
//  Extensions.swift
//  AR World
//
//  Created by Nate Sesti on 10/17/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

private var vcForBlockedSelector: UIViewController?
extension UIView {
    @objc func dismissParentVC() {
        //Leave the profile
        if let vc = vcForBlockedSelector {
            vc.dismiss(animated: true, completion: nil)
        }
    }
    func checkBlockStatus(uid: String, vc: UIViewController) {
        
        //Check for block
        //If uid is contained in currentUser's list of blocked people, blur the whole view out with a UIVisualEffectView.
        if let currentUser = auth.currentUser {
            getUser(uid: currentUser.uid, with: { (user) in
                for blockedUser in user.blocked {
                    if blockedUser == uid {
                        //Create blur view and contents
                        let blurView = UIVisualEffectView(frame: self.frame)
                        blurView.effect = UIBlurEffect(style: UIBlurEffect.Style.regular)
                        let label = UILabel(frame: CGRect(width: self.frame.width, height: self.frame.height/2.0, centerOn: self.frame.mid()))
                        label.textAlignment = .center
                        label.text = "You have blocked this user."
                        label.adjustsFontSizeToFitWidth = true
                        blurView.contentView.addSubview(label)
                        let okButton = UIButton(frame: CGRect(x: self.frame.midX - self.frame.width/2.0, y: self.frame.midY + 25 - self.frame.height/2.0, width: self.frame.width, height: self.frame.height/2.0))
                        okButton.contentVerticalAlignment = .center
                        okButton.contentHorizontalAlignment = .center
                        okButton.setTitle("OK", for: .normal)
                        okButton.setTitleColor(.black, for: .normal)
                        vcForBlockedSelector = vc
                        okButton.addTarget(self, action: #selector(self.dismissParentVC), for: .touchUpInside)
                        blurView.contentView.addSubview(okButton)
                        self.addSubview(blurView)
                    }
                }
            })
        }
    }
}

extension Firestore {
    public func collection(named collectionPath: DatabaseCollections) -> CollectionReference {
        return self.collection(collectionPath.rawValue)
    }
}
extension GeoPoint {
    public var coordinates: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

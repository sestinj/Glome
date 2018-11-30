//
//  UsernameLinkButton.swift
//  AR World
//
//  Created by Nate Sesti on 9/30/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import FirebaseAuth


class UsernameLinkButton: UIButton, UINavigationControllerDelegate {
    private var uid: String!
    private var parentVC: UIViewController!
    required init(uid: String, parentVC: UIViewController) {
        super.init(frame: .zero)
        self.initialize(uid: uid, parentVC: parentVC)
    }
    func initialize(uid: String, parentVC: UIViewController) {
        self.uid = uid
        self.setTitleColor(vibrantPurple, for: .normal)
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        self.parentVC = parentVC
        self.addTarget(self, action: #selector(openUserPage), for: .touchUpInside)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    @objc func openUserPage() {
        //Go to user profile with UINavigationController
        guard let uid = uid else {
            print("User ID not found for UsernameLinkButton.")
            return}
        let otherVC = OtherViewController()
        otherVC.uid = uid
        
        let navVC = UINavigationController(rootViewController: otherVC)
        navVC.delegate = self
        otherVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: otherVC, action: #selector(otherVC.done))
        otherVC.navigationItem.title = "Username"
        parentVC.present(navVC, animated: true, completion: nil)
    }
}

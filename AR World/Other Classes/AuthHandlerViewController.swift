//
//  TestingViewController.swift
//  AR World
//
//  Created by Nate Sesti on 10/23/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import Firebase

class AuthHandlerViewController: UIViewController {
    
    //MARK: Auth
    var handle: AuthStateDidChangeListenerHandle!
    override func viewDidAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // Why is this class here?
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        Auth.auth().removeStateDidChangeListener(handle!)
    }
}

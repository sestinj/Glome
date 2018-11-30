//
//  LogInViewController.swift
//  AR World
//
//  Created by Nate Sesti on 10/23/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import Firebase

class LogInViewController: AuthHandlerViewController {
    private func signInOrUp() {
        let emailAlert = alert(title: "Email", hasTextField: true, message: nil) { (alert1) in
            if let email = alert1.textFields!.first!.text {
                
                let passwordAlert = alert(title: "Password", hasTextField: true, message: nil, completion: { (alert2) in
                    if let password = alert2.textFields!.first!.text {
                        auth.signIn(withEmail: email, password: password) { (user, error) in
                            //Incorrect password
                            if let error = error {
                                if (error as NSError).code == 17009 {
                                    let wrongPassAlert = alert(title: "Incorrect Password", hasTextField: false, message: nil, completion: { (alert) in
                                        self.dismiss(animated: true, completion: nil)
                                    })
                                    self.present(wrongPassAlert, animated: true, completion: nil)
                                    return
                                }
                            }
                            if let user = user {
                                //User exists
                                //Get info from the user
                                self.titleLabel.text = "Welcome back!"
                                self.dismiss(animated: true, completion: nil)
                                
                                //This came from what was previously the authUI didSignInWithuser function
                                //Basically, it just gets the otherVC and tells it to load the bio with the new user
                                // handle user and error as necessary
                                guard let rootVC = applicationDelegate.window!!.rootViewController else {return}
                                var optionalOtherVC: OtherViewController?
                                
                                for child in rootVC.childViewControllers {
                                    if let child = child as? OtherViewController {
                                        optionalOtherVC = child
                                    }
                                }
                                guard let otherVC = optionalOtherVC else {return}
                                otherVC.uid = user.user.uid
                                otherVC.loadBio()
                                self.dismiss(animated: true, completion: nil)
                                
                            } else {
                                //User doesn't exist
                                //Create an account
                                self.titleLabel.text = "Thanks for joining!"
                                auth.createUser(withEmail: email, password: password, completion: { (user1, err1) in
                                    if let err1 = err1 {
                                        print(err1)
                                        self.titleLabel.text = "Welcome!"
                                        self.dismiss(animated: true, completion: nil)
                                        return
                                    }
                                    //Here, the same thing is happening, just with a newly created user
                                    guard let rootVC = applicationDelegate.window!!.rootViewController else {return}
                                    var optionalOtherVC: OtherViewController?
                                    
                                    for child in rootVC.childViewControllers {
                                        if let child = child as? OtherViewController {
                                            optionalOtherVC = child
                                        }
                                    }
                                    guard let otherVC = optionalOtherVC else {return}
                                    guard let user1 = user1 else {return}
                                    
                                    //Create the new user document, after getting the display name
                                    let nameAlert = alert(title: "Username", hasTextField: true, message: nil, completion: { (alert3) in
                                        if let displayName = alert3.textFields!.first!.text {
                                            let changeRequest = auth.currentUser!.createProfileChangeRequest()
                                            changeRequest.displayName = displayName
                                            changeRequest.commitChanges { (error) in
                                                if let error = error {
                                                    print(error)
                                                }
                                            }
                                            db.collection("users").addDocument(data: ["uid":user1.user.uid, "name":displayName, "bioText":"", "followers":[String](), "following":[String](), "blocked":[String](), "imageName":"", "numberOfFollowers":0, "numberOfFollowing":0])
                                            
                                            otherVC.uid = user1.user.uid
                                            otherVC.loadBio()
                                        }
                                        print("New user made")
                                        self.dismiss(animated: true, completion: nil)
                                    })
                                    self.present(nameAlert, animated: true, completion: nil)
                                })
                            }
                        }
                    }
                })
                self.present(passwordAlert, animated: true, completion: nil)
            }
        }
        present(emailAlert, animated: true, completion: nil)
    }
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBAction func signIn(_ sender: UIButton) {
        signInOrUp()
    }
    @IBAction func signUp(_ sender: UIButton) {
        signInOrUp()
    }
    @IBOutlet weak var background: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if X() {
            background.frame.size.height += 150
            background.frame.size.width += 50
            background.frame.origin.x -= 25
            titleLabel.frame.origin.y += 150
            signUpButton.frame.origin.y += 150
            signInButton.frame.origin.y += 150
        }
        
        signInButton.layer.roundCorners()
        signUpButton.layer.roundCorners()
        signInButton.layer.borderColor = UIColor.black.cgColor
        signUpButton.layer.borderColor = UIColor.black.cgColor
        signInButton.layer.borderWidth = 3
        signUpButton.layer.borderWidth = 3
    }

}

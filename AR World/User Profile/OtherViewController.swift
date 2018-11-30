//
//  OtherViewController.swift
//  D4
//
//  Created by Nate Sesti on 7/15/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit

import Firebase
import FirebaseUI
import GoogleSignIn

class OtherViewController: AuthHandlerViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextViewDelegate, UIWebViewDelegate {
    
    private var isSignedIn = false
    var isRootBio = false
    public var uid: String?
    private var userData: [String:Any]?
    private var userDocRef: DocumentReference?
    var items = [DocumentSnapshot]()
    var parentVC: ViewController!
    
    
    //MARK: UITextViewDelegate
    //Biography
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.becomeFirstResponder()
    }
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.resignFirstResponder()
        let newText = textView.text
        userDocRef!.updateData(["bioText": newText ?? ""])
    }
    
    
    //MARK: UIImagePickerDelegate
    //User photo
    @objc func selectImage() {
        if !isRootBio {
            return
        }
        let picker = UIImagePickerController()
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        //Save image to storage
        userDocRef!.getDocument { (docSnap, err) in
            if let err = err {
                print(err)
            } else {
                guard let png = UIImagePNGRepresentation(selectedImage) else {return}
                if let imageName = docSnap!.data()!["imageName"] as? String {
                    //Delete old image - a new imageName is always created
                    storage.reference().child(imageName).delete(completion: nil)
                }
                //Add new photo to storage, add name to database under user item
                let root = storage.reference()
                let name = "\(CGFloat(low: 0.0, high: 100000.0))"
                let newRef = root.child(name)
                docSnap!.reference.updateData(["imageName":name])
                newRef.putData(png, metadata: nil) { (metaData, err) in
                    if let err = err {
                        print(err)
                    }
                }
                
            }
        }
        //Update image immediately
        userPhoto.image = selectedImage
        dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: Outlets
    @IBOutlet weak var infoButton: UIButton!
    @IBAction func followPressed(_ sender: UIButton) {
        if followButton.title(for: .normal) == "Follow" {
            guard let uid = uid else {return}
            //Add user to currentUser's following//Add currentUser to user's followers
            if let currentUser = auth.currentUser {
                addUserToUserList(user: uid, userToAdd: currentUser.uid, list: "followers")
                addUserToUserList(user: currentUser.uid, userToAdd: uid, list: "following")
            }
        } else {
            //When user isn't signed in, follow button = signin button
            if sender.title(for: .normal) == "Sign In/Up" {
                //Go to login page
                present(LogInViewController(), animated: true, completion: nil)
            } else if sender.title(for: .normal) == "Sign Out" {
                //Sign out and clear bio page
                do {
                    try auth.signOut()
                } catch {
                    print(error)
                }
                sender.setTitle("Sign In/Up", for: .normal)
                followersButton.setTitle("Followers", for: .normal)
                followingButton.setTitle("Following", for: .normal)
                usernameLabel.alpha = 0.0
                bioTextView.alpha = 0.0
                userPhoto.image = UIImage(named: "ZStudiosLogo")
                items.removeAll()
                collectionView.reloadData()
            }
        }
    }
    @IBOutlet weak var blockButton: UIButton!
    @IBAction func blockPressed(_ sender: UIButton) {
        let blockAlert = UIAlertController(title: "Are you sure?", message: "Blocking this user will also report them.", preferredStyle: .actionSheet)
        blockAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        //Make sure they really want to block the user
        let blockAction = UIAlertAction(title: "Block", style: .destructive) { (action) in
            //Block user and send message to CSC
            guard let uid = self.uid else {return}
            if let currentUser = auth.currentUser {
                db.collection("flagged").addDocument(data: ["stuff": "The user with uid \(uid) has been blocked by the user with uid \(currentUser.uid)"])
                db.collection("users").whereField("uid", isEqualTo: currentUser.uid).getDocuments { (querySnap, err) in
                    if let err = err {
                        print(err)
                    } else {
                        let queryDoc = querySnap!.documents.first!
                        if var blocked = queryDoc.data()["blocked"] as? [String] {
                            blocked.append(uid)
                            queryDoc.reference.updateData(["blocked": blocked])
                        } else {
                            queryDoc.reference.updateData(["blocked": [uid]])
                        }
                        self.view.checkBlockStatus(uid: uid, vc: self)
                    }
                }
            }
        }
        blockAlert.addAction(blockAction)
        present(blockAlert, animated: true, completion: nil)
    }
    @IBAction func infoPressed(_ sender: UIButton) {
        mainVC.showPopUpView(type: .info)
    }
    @IBOutlet weak var followersButton: UIButton!
    private func showUsersTable(listType: String) {
        //present the users tableview
        guard let uid = uid else {return}
        let usersVC = UsersTableViewController()
        let navVC = UINavigationController()
        navVC.delegate = self
        navVC.addChildViewController(usersVC)
        usersVC.listType = listType
        usersVC.navigationItem.title = listType
        usersVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: usersVC, action: #selector(usersVC.done))
        usersVC.navigationItem.leftBarButtonItem!.tintColor = vibrantPurple
        usersVC.userUID = uid
        self.present(navVC, animated: true, completion: nil)
    }
    @IBAction func followersPressed(_ sender: UIButton) {
        return
        showUsersTable(listType: "followers")
    }
    @IBOutlet weak var followingButton: UIButton!
    @IBAction func followingPressed(_ sender: UIButton) {
        return
        showUsersTable(listType: "following")
    }
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var userPhoto: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    
    //MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if X() {
            self.view.frame.size.height += 150
        }
        
        followingButton.layer.roundCorners()
        followersButton.layer.roundCorners()
        followButton.layer.roundCorners()
        followingButton.layer.borderColor = vibrantPurple.cgColor
        followersButton.layer.borderColor = vibrantPurple.cgColor
        followingButton.layer.borderWidth = 1
        followersButton.layer.borderWidth = 1
        
        blockButton.layer.roundCorners()
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        recognizer.delegate = self
        userPhoto.layer.roundCorners()
        userPhoto.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.5).cgColor
        userPhoto.layer.borderWidth = 1.0
        userPhoto.addGestureRecognizer(recognizer)
        loadBio()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "OtherCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "otherReuseIdentifier")
    }
    func loadBio() {
        //Check if is root bio, if user is signed in, reset everything
        items.removeAll()
        //Check UID
        if let uid = uid {
            userDocRef = db.collection("users").document(uid)
            view.checkBlockStatus(uid: uid, vc: self)
        } else {
            if let authCurrentUser = auth.currentUser {
                uid = authCurrentUser.uid
                userDocRef = db.collection("users").document(uid!)
            }
        }
        //Root bio
        if isRootBio {
            blockButton.alpha = 0.0
            if auth.currentUser != nil {
                isSignedIn = true
                //when isRootBio, follow button = signin/out button
                followButton.setTitle("Sign Out", for: .normal)
            } else {
                //When the user isn't logged in, follow button = signin button
                followButton.setTitle("Sign In/Up", for: .normal)
            }
        }
        
        //Signedin/Rootbio
        usernameLabel.alpha = 1.0
        bioTextView.alpha = 1.0
        if isRootBio {
            
            if isSignedIn {
                bioTextView.delegate = self
                bioTextView.isEditable = true
                bioTextView.isSelectable = true
            } else {
                bioTextView.alpha = 0.0
                usernameLabel.alpha = 0.0
                userPhoto.isUserInteractionEnabled = false
            }
        } else {
            userPhoto.isUserInteractionEnabled = false
        }
        
        if let uid = uid {
            //Get user's bio photo and bio text
            db.collection("users").whereField("uid", isEqualTo: uid).getDocuments(completion: { (querySnap, err) in
                if let err = err {
                    print(err)
                } else {
                    if querySnap!.documents.count <= 0 {
                        return
                    }
                    let docSnap = querySnap!.documents[0]
                    self.userDocRef = docSnap.reference
                    let data = docSnap.data()
                    self.followingButton.setTitle("Following: \(String(describing: data["numberOfFollowing"] as! Int))", for: .normal)
                    self.followersButton.setTitle("Followers: \(String(describing: data["numberOfFollowers"] as! Int))", for: .normal)
                    if let bioText = data["bioText"] as? String {
                        self.bioTextView.text = bioText
                    }
                    self.usernameLabel.text = data["name"] as? String
                    self.navigationItem.title = data["name"] as? String
                    if let imageName = data["imageName"] as? String {
                        storage.reference().child(imageName).getData(maxSize: 10240*10240) { (imageData, err) in
                            if let err = err {
                                print(err)
                            } else {
                                guard let newImage = UIImage(data: imageData!) else {return}
                                self.userPhoto.image = newImage
                            }
                        }
                    }
                    
                    self.userDocRef!.collection("items").getDocuments { (querySnap, err) in
                        //Load items for collection view
                        if let err = err {
                            print(err)
                        } else {guard let querySnap = querySnap else {return}
                            guard let _ = querySnap.documents.first else {return}
                            var count = querySnap.documents.count
                            for nameDoc in querySnap.documents {
                                count -= 1
                                if let name = nameDoc.data()["name"] as? String {
                                    db.collection("items").whereField("Name", isEqualTo: name).getDocuments(completion: { (querySnap2, err2) in
                                        if let err2 = err2 {
                                            print(err2)
                                        } else {
                                            if querySnap2!.documents.count > 0 {
                                                self.items.append(querySnap2!.documents[0] as DocumentSnapshot)
                                            }
                                            if count < 1 {
                                                self.collectionView.reloadData()
                                            }
                                        }
                                    })
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    
    //MARK: UICollectionViewDelegate/DataSource
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? OtherCollectionViewCell {
            cell.tintView.alpha = 0.4
        }
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? OtherCollectionViewCell {
            cell.tintView.alpha = 0.0
        }
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    //Info button on collection view cell allows for changing name and deletion.
    @objc func infoButtonPressed(sender: InfoButton) {
        let indexPath = sender.indexPath!
        let item = items[indexPath.row]
        guard let data = item.data() else {return}
        let alert = UIAlertController(title: data["Name"] as? String, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            item.reference.delete()
            self.items.remove(at: sender.indexPath!.row)
            self.loadBio()
        }
        alert.addAction(deleteAction)
        let editAction = UIAlertAction(title: "Edit", style: .default) { (action) in
            let renameAlert = UIAlertController(title: "Edit", message: "Rename the item named \(data["Name"] as! String)", preferredStyle: .alert)
            renameAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            renameAlert.addTextField(configurationHandler: nil)
            let renameAction = UIAlertAction(title: "Rename", style: .default, handler: { (action) in
                if let textField = renameAlert.textFields!.first {
                    item.reference.updateData(["Name": textField.text!])
                    if let cell = self.collectionView.cellForItem(at: sender.indexPath!) as? OtherCollectionViewCell {
                        cell.nameLabel.text = textField.text!
                    }
                }
            })
            renameAlert.addAction(renameAction)
            self.present(renameAlert, animated: true, completion: nil)
        }
        alert.addAction(editAction)
        present(alert, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "otherReuseIdentifier", for: indexPath) as! OtherCollectionViewCell
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        
        //Info button
        if isRootBio {
            cell.infoButton.indexPath = indexPath
            cell.infoButton.addTarget(indexPath, action: #selector(infoButtonPressed(sender:)), for: .touchUpInside)
        } else {
            cell.infoButton.alpha = 0.0
        }
        
        
        guard let data = items[indexPath.row].data() else {return cell}
        let name = data["Name"] as? String
        cell.nameLabel.text = name
        //Cell depends on media type
        let mediaType = data["Media Type"] as! String
        switch mediaType {
        case "Text":
            break
        case "Gif":
            cell.imageView.image = UIImage(named: "giphy")
        case "Photo":
//            cell.nameLabel.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            storage.reference().child(data["Photo Name"] as! String).getData(maxSize: 10240*10240) { (imageData, err) in
                if let err = err {
                    print(err)
                } else {
                    guard let newImage = UIImage(data: imageData!) else {return}
                    cell.imageView.image = newImage
                    cell.nameLabel.text = ""
                }
            }
        case "Shape":
            cell.imageView.image = UIImage(named: "purpleCube3D")
        default:
            break
        }
        
        return cell
    }
}

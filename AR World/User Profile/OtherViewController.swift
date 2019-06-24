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

class OtherViewController: AuthHandlerViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextViewDelegate, UIWebViewDelegate, CardViewControllerDelegate {
    
    
    //Top level UI
    @IBOutlet weak var menuButton: UIButton!
    @IBAction func menuButtonPressed(_ sender: UIButton) {
        let menu = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)
        if !isRootBio {
            menu.addAction(UIAlertAction(title: "Block", style: .destructive, handler: { (action) in
                self.blockPressed()
            }))
        } else {
            
        }
        menu.addCancel()
        present(menu, animated: true, completion: nil)
    }
    
    @IBOutlet weak var glomeLabel: UIButton?
    @IBAction func glomeButtonPressed(_ sender: UIButton) {
    }
    
    var vibrantBanner: UIVisualEffectView!
    var topLine: CAShapeLayer!
    
    private var isSignedIn = false
    var isRootBio = false
    public var uid: String?
    private var userData: [String:Any]?
    private var userDocRef: DocumentReference?
    var items = [ARItem]()
    
    //Biography
    //MARK: UITextViewDelegate
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            let newText = textView.text
            userDocRef!.updateData(["bioText": newText ?? ""])
            return false
        }
        return true
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
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        guard let selectedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            return
        }
        //Save image to storage
        userDocRef!.getDocument { (docSnap, err) in
            if let err = err {
                print(err)
            } else {
                guard let png = selectedImage.pngData() else {return}
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
    
    //MARK: TODO: BioStates
    public var bioState: BioStates = .follow
    public enum BioStates: String {
        case follow = "Follow"
        case following = "Following"
        case signedout = "Sign In/Up"
        case signedin = "Sign Out"
        ///When the uid is nil
        case usernotfound = "User Not Found"
        
        func setupState() {
            switch self {
            case .follow:
                break
            case .following:
                break
            case .signedout:
                break
            case .usernotfound:
                break
            case .signedin:
                break
            }
        }
        
        var isRootBio: Bool {
            return self == .signedin || self == .signedout
        }
    }
    
    //MARK: Outlets
    @IBAction func followPressed(_ sender: UIButton) {
        switch bioState {
        case .follow:
            break
        case .following:
            break
        case .signedout:
            break
        case .usernotfound:
            break
        case .signedin:
            break
        }
        
        if sender.title(for: .normal) == "Follow" {
            guard let uid = uid else {return}
            //Add user to currentUser's following//Add currentUser to user's followers
            if let currentUser = auth.currentUser {
                addUserToUserList(user: uid, userToAdd: currentUser.uid, list: "followers")
                addUserToUserList(user: currentUser.uid, userToAdd: uid, list: "following")
                followButton.setTitle("Following", for: .normal)
                followButton.backgroundColor = .white
            }
        } else if sender.title(for: .normal) == "Following" {
            guard let uid = uid else {return}
            
            if let currentUser = auth.currentUser {
                //TODO: Remove follower
            }
        } else if sender.title(for: .normal) == "Sign In/Up" {
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
    @objc func blockPressed() {
        let blockAlert = UIAlertController(title: "Are you sure?", message: "Blocking this user will also report them.", preferredStyle: .actionSheet)
        blockAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        //Make sure they really want to block the user
        let blockAction = UIAlertAction(title: "Block", style: .destructive) { (action) in
            //Block user and send message to CSC
            guard let uid = self.uid else {return}
            if let currentUser = auth.currentUser {
                db.collection("flagged").addDocument(data: ["stuff": "The user with uid \(uid) has been blocked by the user with uid \(currentUser.uid)"])
                getUser(uid: currentUser.uid, with: { (user) in
                    user.blocked.append(uid)
                    self.view.checkBlockStatus(uid: uid, vc: self)
                })
            }
        }
        blockAlert.addAction(blockAction)
        present(blockAlert, animated: true, completion: nil)
    }
    @IBOutlet weak var followersButton: UIButton!
    private func showUsersTable(listType: String) {
        //present the users tableview
        guard let uid = uid else {return}
        let usersVC = UsersTableViewController()
        let navVC = UINavigationController()
        navVC.delegate = self
        navVC.addChild(usersVC)
        usersVC.listType = listType
        usersVC.navigationItem.title = listType
        usersVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: usersVC, action: #selector(usersVC.done))
        usersVC.navigationItem.leftBarButtonItem!.tintColor = vibrantPurple
        usersVC.userUID = uid
        usersVC.isRootBio = self.isRootBio
        self.present(navVC, animated: true, completion: nil)
    }
    @IBAction func followersPressed(_ sender: UIButton) {
        showUsersTable(listType: "followers")
    }
    @IBOutlet weak var followingButton: UIButton!
    @IBAction func followingPressed(_ sender: UIButton) {
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
            collectionView.frame.size.height += 150
            glomeLabel?.frame.origin.y += 22
        }
        
        bioTextView.delegate = self
        bioTextView.backgroundColor = .clear
        
        menuButton.setImage(UIImage(named: "dots")?.withRenderingMode(.alwaysTemplate), for: .normal)
        menuButton.tintColor = vibrantPurple
        menuButton.contentMode = .scaleAspectFit
        menuButton.imageView?.contentMode = .scaleAspectFit
        
        followingButton.layer.roundCorners()
        followersButton.layer.roundCorners()
        followButton.layer.roundCorners()
        followingButton.layer.borderColor = vibrantPurple.cgColor
        followersButton.layer.borderColor = vibrantPurple.cgColor
        followButton.layer.borderColor = vibrantPurple.cgColor
        followingButton.layer.borderWidth = 1
        followersButton.layer.borderWidth = 1
        followButton.layer.borderWidth = 1
        
        
        //Top Level UI
        if let _ = glomeLabel {
            vibrantBanner = UIVisualEffectView(frame: CGRect(x: 0, y: 83-150, width: view.frame.width, height: 150))
            vibrantBanner.layer.zPosition = 4
            vibrantBanner.effect = UIBlurEffect(style: .light)
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    vibrantBanner.effect = UIBlurEffect(style: .dark)
                }
            }
            view.addSubview(vibrantBanner)
            
            topLine = CAShapeLayer()
            topLine.path = CGPath(rect: CGRect(x: 0, y: 83, width: view.frame.width, height: 3), transform: nil)
            view.layer.addSublayer(topLine)
            if !X() {
                topLine.frame.origin.y -= 22
                vibrantBanner.frame.origin.y -= 22
            }
            glomeLabel?.layer.zPosition = 5
        }
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        recognizer.delegate = self
        userPhoto.layer.roundCorners()
        userPhoto.addGestureRecognizer(recognizer)
        loadBio()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "OtherCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "otherReuseIdentifier")
        collectionView.showsVerticalScrollIndicator = false
        collectionView.layer.masksToBounds = false
        collectionView.layer.zPosition = -2
        
        
        let fade = CAGradientLayer()
        fade.frame = CGRect(x: collectionView.frame.origin.x, y: collectionView.frame.origin.y - 50, width: collectionView.frame.width, height: 50)
        fade.colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.005).cgColor]
        view.layer.addSublayer(fade)
        let blockLayer = CALayer()
        //It would be better to just change the locations of the CAGradientLayer
        blockLayer.frame = CGRect(x: collectionView.frame.origin.x, y: collectionView.frame.origin.y - 250, width: collectionView.frame.width, height: 200)
        blockLayer.backgroundColor = CGColor.white
        blockLayer.zPosition = -1
        view.layer.addSublayer(blockLayer)
        bioTextView.layer.zPosition = 5
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard vibrantBanner != nil else {return}
        vibrantBanner.effect = UIBlurEffect(style: .light)
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                vibrantBanner.effect = UIBlurEffect(style: .dark)
            }
        }
    }
    
    func loadBio() {
        //Check if is root bio, if user is signed in, reset everything
        items.removeAll()
        //Check UID (if not specified, this is main rootBio)
        if let uid = uid {
            userDocRef = db.collection("users").document(uid)
            view.checkBlockStatus(uid: uid, vc: self)
        } else {
            isRootBio = true
        }
        //Root bio - this denotes the current user's bio
        if isRootBio {
            if let authCurrentUser = auth.currentUser {
                uid = authCurrentUser.uid
                userDocRef = db.collection("users").document(uid!)
                isSignedIn = true
                //when isRootBio, follow button = signin/out button
                followButton.setTitle("Sign Out", for: .normal)
            } else {
                //When the user isn't logged in, follow button = signin button
                followButton.setTitle("Sign In/Up", for: .normal)
            }
        }
        
        //Signedin/Rootbio - editing capabilities
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
        
        //User is found/signed in
        if let uid = uid {
            //Get user's bio photo and bio text
            getUser(uid: uid, with: { (user) in
                self.userDocRef = user.reference
                self.followingButton.setTitle("Following: \(String(describing: user.numFollowing))", for: .normal)
                self.followersButton.setTitle("Followers: \(String(describing: user.numFollowers))", for: .normal)
                self.bioTextView.text = user.bioText
                self.usernameLabel.text = user.name
                self.navigationItem.title = user.name
                storage.reference().child(user.imageName).getData(maxSize: 10240*10240) { (imageData, err) in
                    if let err = err {
                        print(err)
                    } else {
                        guard let newImage = UIImage(data: imageData!) else {return}
                        self.userPhoto.image = newImage
                    }
                }
                
                getDocuments(from: self.userDocRef!.collection("items"), with: { (docs) in
                    var count = docs.count
                    for doc in docs {
                        count -= 1
                        getFirstDocument(from: db.collection(named: .items).whereField("name", isEqualTo: doc.rawData![FirestoreKeys.name.rawValue]!), with: { (itm) in
                            self.items.append(ARItem(doc: itm.document))
                            if count < 1 {
                                self.collectionView.reloadData()
                            }
                        })
                    }
                })
            })
        }
    }
    
    
    //MARK: UICollectionViewDelegate/DataSource
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let _ = collectionView.cellForItem(at: indexPath) as? OtherCollectionViewCell {
            let card = CardViewController()
            card.delegate = self
            view.addSubview(card.view)
            addChild(card)
            
            let descriptionVC = DescriptionViewController()
            descriptionVC.doc = items[indexPath.row]
            card.addChild(descriptionVC)
            card.view.addSubview(descriptionVC.view)
            card.animateTransitionIfNeeded(state: .expanded, duration: 0.5)
        }
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    //Info button on collection view cell allows for changing name and deletion.
    @objc func infoButtonPressed(sender: InfoButton) {
        let indexPath = sender.indexPath!
        let item = items[indexPath.row]
        let alert = UIAlertController(title: item.name, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            item.delete()
            self.items.remove(at: sender.indexPath!.row)
            self.loadBio()
        }
        alert.addAction(deleteAction)
        let renameAction = UIAlertAction(title: "Rename", style: .default) { (action) in
            let renameAlert = UIAlertController(title: "Rename", message: "the item named \(item.name)", preferredStyle: .alert)
            renameAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            renameAlert.addTextField(configurationHandler: nil)
            let renameAction = UIAlertAction(title: "Rename", style: .default, handler: { (action) in
                if let textField = renameAlert.textFields!.first {
                    item.name = textField.text!
                    if let cell = self.collectionView.cellForItem(at: sender.indexPath!) as? OtherCollectionViewCell {
                        cell.nameLabel.text = textField.text!
                    }
                }
            })
            renameAlert.addAction(renameAction)
            self.present(renameAlert, animated: true, completion: nil)
        }
        alert.addAction(renameAction)
        present(alert, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "otherReuseIdentifier", for: indexPath) as! OtherCollectionViewCell
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.borderWidth = 1.0
        cell.layer.cornerRadius = 10.0
        cell.layer.masksToBounds = true
        
        //Info button
        if isRootBio {
            cell.infoButton.indexPath = indexPath
            cell.infoButton.addTarget(indexPath, action: #selector(infoButtonPressed(sender:)), for: .touchUpInside)
        } else {
            cell.infoButton.alpha = 0.0
        }
        
        let item = items[indexPath.row]
        
        cell.nameLabel.text = item.name
        cell.nameLabel.textColor = .black
        //Cell depends on media type
        switch item.mediaType {
        case .text:
            cell.imageView.image = UIImage(named: "image")
        case .gif:
            cell.imageView.image = UIImage(named: "giphy")
        case .photo(let photoID):
            cell.imageView.image = UIImage(named: "image")
//            cell.nameLabel.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            item.retrieveImage { (image) in
                cell.imageView.image = image
            }
//            storage.reference().child(photoID).getData(maxSize: 10240*10240) { (imageData, err) in
//                if let err = err {
//                    print(err)
//                } else {
//                    guard let newImage = UIImage(data: imageData!) else {return}
//                    cell.imageView.image = newImage
//                    cell.nameLabel.text = ""
//                }
//            }
        case .shape:
            cell.imageView.image = UIImage(named: "purpleCube3D")
        }
        
        return cell
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

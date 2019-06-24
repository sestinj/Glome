//
//  DescriptionViewController.swift
//  D4
//
//  Created by Nate Sesti on 8/30/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Firebase
import UIKit
import CoreLocation
import MapKit

class DescriptionViewController: AuthHandlerViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    var doc: ARItem?
    var comments = [Comment]()
    
    //Likes
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    private var liked = false
    private var numLikes = 0
    @IBAction func likeButtonPressed(_ sender: UIButton) {
        guard let currentUser = auth.currentUser else {return}
        if liked {
            likeButton.setImage(UIImage(named: "unliked"), for: .normal)
            numLikes -= 1
            likesLabel.text = "\(numLikes)"
            doc!.reference.updateData(["numLikes":numLikes])
            getFirstDocument(from: doc!.reference.collection("likes").whereField("uid", isEqualTo: currentUser.uid), with: { (queryDoc) in
                let like = Like(doc: queryDoc.document)
                like.delete()
            })
        } else {
            likeButton.setImage(UIImage(named: "liked"), for: .normal)
            numLikes += 1
            likesLabel.text = "\(numLikes)"
            doc!.reference.updateData(["numLikes":numLikes])
            doc!.reference.collection("likes").addDocument(data: ["uid":currentUser.uid, "username":currentUser.displayName!])
            
        }
        liked = !liked
    }
    
    //MARK: UITextViewDelegate
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = "   "
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            //Remove buffer from start of string
            let startIndex = textView.text.index(textView.text.startIndex, offsetBy: 3)
            let finalText = String(textView.text[startIndex...])
            guard finalText != "" else {textView.text = "";textView.resignFirstResponder();return false}
            if let currentUser = auth.currentUser {
                self.doc!.reference.collection("comments").addDocument(data: ["text": finalText, "username":currentUser.displayName!, "uid": currentUser.uid])
                //Show comment right away
                self.reloadComments()
            } else {
                let alert = UIAlertController(title: "", message: "You must be signed in to comment.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            textView.text = ""
            textView.resignFirstResponder()
            return false
        }
        if textView.text.count < 3 {
            textView.text = "   "
            return false
        } else if textView.text.count == 3 {
            textView.text = " " + textView.text
        }
        return true
    }
    
    @IBOutlet weak var commentContainerView: UIView!
    @IBOutlet weak var commentBox: MultilineTextField!
    @IBOutlet weak var glomeLogo: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var usernameButton: UsernameLinkButton!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBAction func xButtonPressed(_ sender: UIButton) {
        if let cardVC = self.parent as? CardViewController {
            cardVC.dismiss(animated: true, completion: nil)
            return
        }
        done()
    }
    @IBAction func menuButtonPressed(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Menu", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let viewAction = UIAlertAction(title: "View", style: .default) { (action) in
            actionSheet.dismiss(animated: true, completion: nil)
            camVC.singleDocToLoad = self.doc!
            camVC.loadItemNonGeo()
            tabVC.selectedIndex = 1
            self.dismiss(animated: true, completion: nil)
        }
        let directions = UIAlertAction(title: "Directions", style: .default) { (action) in
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self.doc!.coordinates.latitude, longitude: self.doc!.coordinates.longitude)))
            mapItem.name = self.titleLabel.text!
            mapItem.openInMaps(launchOptions: nil)
        }
        let flagAction = UIAlertAction(title: "Report", style: .destructive) { (alert) in
            let reportedAlert = UIAlertController(title: "Are you sure?", message: "Reporting this post may cause deletion of this account.", preferredStyle: .alert)
            reportedAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            let reportAction = UIAlertAction(title: "Report", style: .destructive, handler: { (theAction) in
                //Send message to community safety committee
                if let currentUser = auth.currentUser {
                    var docDescription: String
                    switch self.doc!.mediaType {
                    case .photo(let photoName):
                        docDescription = "The image can be found at: \(String(describing: photoName))"
                    case .gif(let url):
                        docDescription = "The gif can be found at: \(url.absoluteString)"
                    case .text( _, _, let text):
                        docDescription = "The text is: \(text)"
                    case .shape:
                        docDescription = "Just a shape"
                    }
                    db.collection("flagged").addDocument(data: ["stuff":"The user with uid \(currentUser.uid) flagged a post by the user with uid \(self.doc!.uid). Media Type: \(self.doc!.mediaType.string), Name: \(self.doc!.name), Description: \(docDescription)"])
                }
            })
            reportedAlert.addAction(reportAction)
            self.present(reportedAlert, animated: true, completion: nil)
        }
        let shareAction = UIAlertAction(title: "Share", style: .default) { (alert) in
            let activityItems = ["I found this amazing new app called Glome. This is the next big thing!"]
            let activity = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            self.present(activity, animated: true, completion: nil)
        }
        actionSheet.addAction(shareAction)
        actionSheet.addAction(viewAction)
        actionSheet.addAction(directions)
        actionSheet.addAction(flagAction)
        present(actionSheet, animated: true, completion: nil)
    }
    
    
    //MARK: Outlets
    @IBOutlet weak var tableView: UITableView!
    
    var initialTransform: CATransform3D!
    @objc func updateLogoSpin(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began, .possible:
            initialTransform = glomeLogo.layer.transform
        case .changed:
            let translation = sender.translation(in: view).y
            glomeLogo.layer.transform = CATransform3DRotate(initialTransform!, translation/100.0, 0.0, 0.0, 1.0)
        case .cancelled, .ended, .failed:
            let path = #keyPath(CALayer.transform)
            let temp = glomeLogo.layer.transform
            glomeLogo.layer.transform = CATransform3DRotate(temp, CGFloat.pi, 0.0, 0.0, 1.0)
            glomeLogo.layer.animate(path, from: temp, duration: 0.3)
        @unknown default:
            fatalError("Unkown case for sender.state")
        }
    }
    
    @objc func closeComments() {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: viewDidLoad()
    override func viewDidLoad() {
        titleLabel.textColor = .white
        usernameButton.initialize(uid: doc!.uid, parentVC: self)
        usernameButton.setTitleColor(.white, for: .normal)
        
        commentBox.layer.roundCorners()
        commentBox.delegate = self
        commentBox.layer.borderColor = UIColor.darkGray.cgColor
        commentBox.layer.borderWidth = 1
        commentContainerView.movesUpWithKeyboard(vc: self)
        
        profilePic.layer.zPosition = 5
        
        if X() {
            for subview in view.subviews {
                subview.frame.origin.y += 22
            }
            tableView.frame.size.height -= 22
            commentContainerView.frame.origin.y += 82
        }
        //Gestures
        let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(closeComments))
        recognizer.delegate = self
        self.view.addGestureRecognizer(recognizer)
        
        //Load profile pic
        profilePic.layer.roundCorners()
        getUser(uid: doc!.uid, with: { (user) in
            storage.reference().child(user.imageName).getData(maxSize: 10240*10240) { (imageData, err) in
                if let err = err {
                    print(err)
                } else {
                    guard let newImage = UIImage(data: imageData!) else {return}
                    self.profilePic.image = newImage
                }
            }
        })
        
        //Setup description
        navigationItem.title = ""
        usernameButton.setTitle(doc!.username, for: .normal)
        
        //Likes
        likeButton.causesImpact(.light)
        numLikes = doc!.numLikes
        likesLabel.text = "\(numLikes)"
        //See if the current user has already liked the post
        if let currentUser = auth.currentUser {
            if doc!.likes.contains(where: { (like) -> Bool in
                return like.uid == currentUser.uid
            }) {
                self.likeButton.setImage(UIImage(named: "liked"), for: .normal)
                self.liked = true
            }
        }
        
        let loc = CLLocation(latitude: doc!.coordinates.latitude, longitude: doc!.coordinates.longitude)
        
        
        tableView.panGestureRecognizer.addTarget(self, action: #selector(updateLogoSpin(sender:)))
        glomeLogo.layer.zPosition = -200.0
        
        if X() {
            tableView.frame.size.height += 150
            tableView.frame.origin.y += 22
        }
        //Load all comments
        if let doc = doc {
            getDocuments(from: doc.reference.collection("comments"), with: { (querySnap) in
                for queryDoc in querySnap {
                    let comment = Comment(doc: queryDoc.document)
                    self.comments.append(comment)
                }
                self.tableView.reloadData()
                self.navigationItem.title = doc.name
                self.titleLabel.text = doc.name
            })
        }
        //Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CommentsTableViewCell", bundle: nil), forCellReuseIdentifier: "commentsReuseIdentifier")
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 78
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //This is so 'empty' cells aren't transparent
        return comments.count + 18
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentsReuseIdentifier") as! CommentsTableViewCell
        
        if indexPath.row >= comments.count {
            //This is so 'empty' cells aren't transparent
            return UITableViewCell()
        }
        let comment = comments[indexPath.row]
        cell.uid = comment.uid
        cell.contentView.checkBlockStatus(uid: cell.uid!, vc: self)
        cell.commentTextView.text = comment.text
        cell.usernameButton.setTitle(comment.username, for: .normal)
        cell.usernameButton.initialize(uid: comment.uid, parentVC: self)
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //MARK: Functions
    func reloadComments() {
        comments.removeAll()
        getDocuments(from: doc!.reference.collection("comments"), with: { (querySnap) in
            for queryDoc in querySnap {
                let comment = Comment(doc: queryDoc.document)
                self.comments.append(comment)
            }
            self.tableView.reloadData()
        })
    }
}

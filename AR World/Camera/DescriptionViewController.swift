//
//  DescriptionViewController.swift
//  D4
//
//  Created by Nate Sesti on 8/30/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Firebase
import UIKit

class DescriptionViewController: AuthHandlerViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    var doc: DocumentSnapshot?
    var comments = [String]()
    var users = [String]()
    var uids = [String]()
    
    //MARK: Outlets
    @IBAction func flagged(_ sender: UIButton) {
        //Send message to community safety committee
        flag.backgroundColor = .red
        flag.layer.roundCorners()
        if let uid = doc!.data()!["uid"] as? String {
            if let currentUser = auth.currentUser {
                var docDescription = ""
                let name = doc!.data()!["Name"] as? String
                let mediaType = doc!.data()!["Media Type"] as? String
                if let mediaType = mediaType {
                    switch mediaType {
                    case "Photo":
                        docDescription = "The image can be found at: \(String(describing: doc!.data()!["Photo Name"] as? String))"
                    case "Gif":
                        docDescription = "The image can be found at: \(String(describing: doc!.data()!["Photo Name"] as? String))"
                    case "Text":
                        docDescription = "The text is: \(String(describing: doc!.data()!["Text"] as? String))"
                    case "Shape":
                        docDescription = "Just a shape"
                    default:
                        docDescription = "Unknown mediaType"
                    }
                }
                db.collection("flagged").addDocument(data: ["stuff":"The user with uid \(currentUser.uid) flagged a post by the user with uid \(uid). Media Type: \(String(describing: mediaType)), Name: \(String(describing: name)), Description: \(docDescription)"])
            }
        }
    }
    @IBOutlet weak var flag: UIButton!
    @objc func addButtonPressed() {
        //Add a new comment
        let alert = UIAlertController(title: "Comment", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let sendAction = UIAlertAction(title: "Send", style: .default) { (action) in
            if let currentUser = auth.currentUser {
                self.doc!.reference.collection("comments").addDocument(data: ["text": alert.textFields!.first!.text!, "username":currentUser.displayName!, "uid": currentUser.uid])
                //Show comment right away
                self.reloadComments()
            } else {
                let alert = UIAlertController(title: "", message: "You must be signed in to comment.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        alert.addAction(sendAction)
        present(alert, animated: true, completion: nil)
    }
    @IBOutlet weak var tableView: UITableView!
    
    @objc func closeComments() {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: viewDidLoad()
    override func viewDidLoad() {
        //Gestures
        let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(closeComments))
        recognizer.delegate = self
        self.view.addGestureRecognizer(recognizer)
        
        //Setup description
        navigationItem.title = ""
        if let username = doc!.data()!["username"] as? String {
            navigationItem.prompt = username
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(closeComments))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "+", style: .done, target: self, action: #selector(addButtonPressed))
        
        if X() {
            tableView.frame.size.height += 150
            tableView.frame.origin.y += 22
            flag.frame.origin.y += 150
        }
        //Load all comments
        if let doc = doc {
            doc.reference.collection("comments").getDocuments { (querySnap, err) in
                if let err = err {
                    print(err)
                } else {
                    for queryDoc in querySnap!.documents {
                        self.users.append(queryDoc.data()["username"] as! String)
                        self.comments.append(queryDoc.data()["text"] as! String)
                        self.uids.append(queryDoc.data()["uid"] as! String)
                    }
                    self.tableView.reloadData()
                    self.navigationItem.title = doc.data()!["Name"] as? String
                }
            }
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
        return comments.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentsReuseIdentifier") as! CommentsTableViewCell
        
        cell.uid = uids[indexPath.row]
        cell.contentView.checkBlockStatus(uid: cell.uid!, vc: self)
        cell.commentTextView.text = comments[indexPath.row]
        cell.usernameButton.setTitle(users[indexPath.row], for: .normal)
        cell.usernameButton.initialize(uid: uids[indexPath.row], parentVC: self)
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    //MARK: Functions
    func reloadComments() {
        comments = []
        users = []
        uids = []
        doc!.reference.collection("comments").getDocuments { (querySnap, err) in
            if let err = err {
                print(err)
            } else {
                for queryDoc in querySnap!.documents {
                    self.users.append(queryDoc.data()["username"] as! String)
                    self.comments.append(queryDoc.data()["text"] as! String)
                    self.uids.append(queryDoc.data()["uid"] as! String)
                }
                self.tableView.reloadData()
            }
        }
    }
}

//
//  CommentsTableViewCell.swift
//  D4
//
//  Created by Nate Sesti on 8/30/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit

class CommentsTableViewCell: UITableViewCell {

    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var usernameButton: UsernameLinkButton!
    var uid: String?
    @IBOutlet weak var flagButton: UIButton!
    @IBAction func flagged(_ sender: UIButton) {
        //Send message to CSC
        flagButton.layer.backgroundColor = UIColor.red.cgColor
        flagButton.layer.roundCorners()
        if let uid = uid {
            if let currentUser = auth.currentUser {
                let comment = commentTextView.text
                db.collection("flagged").addDocument(data: ["stuff":"The user with uid \(currentUser.uid) flagged a comment by the user with uid \(uid). The comment reads: \(String(describing: comment))"])
            }
        }
    }
    
}

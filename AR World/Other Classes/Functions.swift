//
//  Functions.swift
//  AR World
//
//  Created by Nate Sesti on 10/17/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import FirebaseAuth

func addUserToUserList(user: String, userToAdd: String, list: String) {
    //Takes the uid of two users, then adds one of them to the other's following, followers, or blocked list
    db.collection("users").whereField("uid", isEqualTo: user).getDocuments { (querySnap, err) in
        if let err = err {
            print(err)
        } else {
            let queryDoc = querySnap!.documents.first!
            if var blocked = queryDoc.data()[list] as? [String] {
                //Make sure no user appears twice in the list
                if !blocked.contains(userToAdd) {
                    blocked.append(userToAdd)
                    //Safely add one to the number of followers or following
                    if list == "following" {
                        if let nFo = queryDoc.data()["numberOfFollowing"] as? Int {
                            queryDoc.reference.updateData(["numberOfFollowing":nFo + 1])
                        } else {
                            queryDoc.reference.updateData(["numberOfFollowing":1])
                        }
                    } else if list == "followers" {
                        if let nFo = queryDoc.data()["numberOfFollowers"] as? Int {
                            queryDoc.reference.updateData(["numberOfFollowers":nFo + 1])
                        } else {
                            queryDoc.reference.updateData(["numberOfFollowers":1])
                        }
                    }
                }
                queryDoc.reference.updateData([list: blocked])
            } else {
                //If the list didn't already exist, make it
                queryDoc.reference.updateData([list: [userToAdd]])
            }
        }
        
    }
}

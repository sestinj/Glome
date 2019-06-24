//
//  Functions.swift
//  AR World
//
//  Created by Nate Sesti on 10/17/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

func addUserToUserList(user: String, userToAdd: String, list: String) {
    //Takes the uid of two users, then adds one of them to the other's following, followers, or blocked list
    getUser(uid: user, with: { (userDoc) in
        if var blocked = userDoc.rawData![list] as? [String] {
            //Make sure no user appears twice in the list
            if !blocked.contains(userToAdd) {
                blocked.append(userToAdd)
                //Safely add one to the number of followers or following
                if list == "following" {
                    if let nFo = userDoc.rawData!["numberOfFollowing"] as? Int {
                        userDoc.reference.updateData(["numberOfFollowing":nFo + 1])
                    } else {
                        userDoc.reference.updateData(["numberOfFollowing":1])
                    }
                } else if list == "followers" {
                    if let nFo = userDoc.rawData!["numberOfFollowers"] as? Int {
                        userDoc.reference.updateData(["numberOfFollowers":nFo + 1])
                    } else {
                        userDoc.reference.updateData(["numberOfFollowers":1])
                    }
                }
            }
            userDoc.reference.updateData([list: blocked])
        } else {
            //If the list didn't already exist, make it
            userDoc.reference.updateData([list: [userToAdd]])
        }
    })
}

///Execute a query with any function
public func getDocuments(from query: Query, with completion: @escaping ([FirestoreDocument]) -> Void) {
    query.getDocuments { (querySnap, err) in
        if let err = err {
            print("Error retrieving documents: \(err)")
        } else {
            guard let querySnap = querySnap else {return}
            completion(querySnap.documents.map({ (doc) -> FirestoreDocument in
                return FirestoreDocument(doc: doc)
            }))
        }
    }
}
public func getFirstDocument(from query: Query, with completion: @escaping (FirestoreDocument) -> Void) {
    query.getDocuments { (querySnap, err) in
        if let err = err {
            print("Error retrieving documents: \(err)")
        } else {
            guard let querySnap = querySnap else {return}
            guard let doc = querySnap.documents.first else {return}
            completion(FirestoreDocument(doc: doc))
        }
    }
}
public func getOptionalFirstDocument(from query: Query, with completion: @escaping (FirestoreDocument?) -> Void) {
    query.getDocuments { (querySnap, err) in
        if let err = err {
            print("Error retrieving documents: \(err)")
        } else {
            completion(FirestoreDocument(doc: querySnap?.documents.first))
        }
    }
}
public func getUser(uid: String, with completion: @escaping (User) -> Void) {
    getFirstDocument(from: db.collection(named: .users).whereField("uid", isEqualTo: uid)) { (doc) in
        completion(User(doc: doc.document))
    }
}
public func getOptionalUser(uid: String, with completion: @escaping (User?) -> Void) {
    getOptionalFirstDocument(from: db.collection(named: .users).whereField("uid", isEqualTo: uid)) { (doc) in
        completion(User(doc?.document))
    }
}
public func getDocument(from ref: DocumentReference, with completion: @escaping (FirestoreDocument) -> Void) {
    ref.getDocument { (docSnap, err) in
        if let err = err {
            print("Error retrieving documents: \(err)")
        } else {
            guard let docSnap = docSnap else {return}
            guard let _ = docSnap.data() else {return}
            let doc = docSnap.firestoreDocument
            completion(doc)
        }
    }
}


///⚠️DO NOT USE IN SHIPMENT⚠️ This will change keys for all items in a database
public func changeKeysInDatabase(from originalKey: String, to newKey: String, in collection: DatabaseCollections, _ areYouSureAboutDoingThis: Bool) {
    if !areYouSureAboutDoingThis {return}
    getDocuments(from: db.collection(named: collection)) { (docs) in
        for doc in docs {
            guard let data = doc.rawData else {continue}
            guard let value = data[originalKey] else {continue}
            doc.reference.updateData([originalKey: FieldValue.delete(), newKey: value])
        }
    }
}

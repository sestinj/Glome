//
//  ExplanationEnums.swift
//  AR World
//
//  Created by Nate Sesti on 5/29/19.
//  Copyright © 2019 Nate Sesti. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import FirebaseFirestore

///Contains strongly-typed info on Firebase DB collections
public enum DatabaseCollections: String {
    ///Users
    case users = "users"
    ///User reports and concerns
    case flagged = "flagged"
    ///List of all items - geoquery from here
    case items = "items"
    ///THIS IS FOR TESTING
    case println = "println"
}

///These are the names of all keys that would show up in the Firestore database. All are pure lowercase, no spaces
public enum FirestoreKeys: String {
    ///UID to identify user
    case uid = "uid"
    ///Name of whatever object it is attached to - title for ARItems
    case name = "name"
    ///Username for ARItems
    case username = "username"
    ///Text content on .text ARItem
    case text = "text"
    ///Color of ARItem
    case color = "color"
    ///Location of ARItem
    case coordinates = "coordinates"
    ///Text, shape, gif, photo
    case mediaType = "mediatype"
    ///URL For gif content
    case gifURL = "gifurl"
    ///Font for .text ARItem
    case font = "font"
    ///Storage identifier string
    case photoID = "photoid"
}

///Automatically updating and strongly typed version of FirebaseDocument, so DocumentSnapshot is never used again.
public class FirestoreDocument: NSObject {
    
    public let id: String
    public let rawData: [String: Any]?
    public let metadata: SnapshotMetadata
    public let exists: Bool
    public let reference: DocumentReference
    public let document: DocumentSnapshot
    
    public func delete() {
        reference.delete()
    }
    
    override public func didChangeValue(forKey key: String) {
        super.didChangeValue(forKey: key)
        //Automatically updates database upon any changes to an object !!!!FIX THIS - ALL DATABASE KEYS NEED TO BE IN lowercase SO THEY CAN CORRESPOND TO EACH OF THE CLASS KEYS, so search through the whole project for stuff like this then manually fix the database
        guard let value = self.value(forKey: key) else {return}
        if value is Array<FirestoreDocument> {
            //Don't update for collections because they will automatically be updated through the individual FirestoreDocuments
            return
        }
        if ["id", "rawData", "metadata", "exists", "reference", "document"].contains(key) {
            //These aren't a part of data, so they shouldn't be updated
            return
        }
        self.reference.updateData([key.lowercased().removing(.whitespacesAndNewlines) : value])
        print("Key: \(key)", "Value: \(value)")
    }
    
    public init(doc: DocumentSnapshot) {
        document = doc
        id = doc.documentID
        rawData = doc.data()
        metadata = doc.metadata
        exists = doc.exists
        reference = doc.reference
    }
}
extension DocumentSnapshot {
    ///FirebaseDocument initiated from this DocumentSnapshot
    public var firestoreDocument: FirestoreDocument {
        let a = FirestoreDocument(doc: self)
        return a
    }
}


///Base class for all actions tied to a specific Glome user
public class UserPost: FirestoreDocument {
    ///Firebase User ID
    public let uid: String //This also shouldn't be changed
    
    override public init(doc: DocumentSnapshot) {
        uid = doc.data()![FirestoreKeys.uid.rawValue] as? String ?? ""
        super.init(doc: doc)
    }
}

public class Comment: UserPost {
    public let text: String //By now it should be clear that this pattern means don't change
    public let username: String
    
    override public init(doc: DocumentSnapshot) {
        text = doc.data()![FirestoreKeys.text.rawValue] as? String ?? ""
        username = doc.data()![FirestoreKeys.username.rawValue] as? String ?? ""
        super.init(doc: doc)
    }
}
public class Like: UserPost {
    public let username: String
    
    override public init(doc: DocumentSnapshot) {
        username = doc.data()![FirestoreKeys.username.rawValue] as? String ?? ""
        super.init(doc: doc)
    }
}
public class ARItem: UserPost {
    
    ///Contains media types and media specific info
    public enum MediaTypes {
        case gif(url: URL)
        case shape(color: UIColor)
        case text(font: String, color: UIColor, text: String) //It would be nice to have a fonts enum in SSL
        case photo(storageID: String) //You should use Swift's guarunteed distinct ID feature for this in the future, not just randomly generated numbers. A small chance is a chance.
        
        init(data: [String: Any]) {
            switch data[FirestoreKeys.mediaType.rawValue] as? String ?? "" {
            case "Gif":
                self = .gif(url: URL(string: data[FirestoreKeys.gifURL.rawValue] as? String ?? "")!)
            case "Shape":
                self = .shape(color: data[FirestoreKeys.color.rawValue] as? UIColor ?? vibrantPurple)
            case "Text":
                self = .text(font: data[FirestoreKeys.font.rawValue] as? String ?? "System", color: data[FirestoreKeys.color.rawValue] as? UIColor ?? vibrantPurple, text: data[FirestoreKeys.text.rawValue] as? String ?? "")
            case "Photo":
                self = .photo(storageID: data[FirestoreKeys.photoID.rawValue] as? String ?? "")
            default:
                self = .text(font: "System", color: .black, text: "")
            }
        }
        
        public var string: String {
            switch self {
            case .gif:
                return "Gif"
            case .shape:
                return "Shape"
            case .text:
                return "Text"
            case .photo:
                return "Photo"
            }
        }
    }
    
    override public func didChangeValue(forKey key: String) {
        if key == "nonGeo" {return}
        if key == "mediaType" {
            reference.updateData(["Media Type": mediaType])
            switch mediaType {
            case .gif(let u):
                reference.updateData(["url":u.absoluteString])
            case .photo(let sid):
                reference.updateData(["photoid":sid])
            case .shape(let color):
                reference.updateData(["color":color])
            case .text(let font, let color, let text):
                reference.updateData(["font":font, "color":color, "text":text])
            }
            return
        }
        super.didChangeValue(forKey: key)
    }
    
    ///Name of item
    public var name: String
    ///Comments on this post
    private(set) var comments: [Comment]
    ///Likes on this post
    private(set) var likes: [Like]
    ///Number of likes on this post
    public var numLikes: Int {
        return likes.count
    }
    public let username: String
    ///Date of post
    public let date: Date
    ///Type of post
    public let mediaType: MediaTypes
    ///Coordinates of the post
    public var coordinates: CLLocationCoordinate2D
    public var nonGeo: Bool
    
    override public init(doc: DocumentSnapshot) {
        let data = doc.data()!
        name = data["name"] as? String ?? ""
        comments = [Comment]()
        likes = [Like]()
        date = (data["date"] as? Timestamp ?? Timestamp(date: Date())).dateValue()
        mediaType = MediaTypes(data: data)
        coordinates = (data[FirestoreKeys.coordinates.rawValue] as! GeoPoint).coordinates
        username = data[FirestoreKeys.username.rawValue] as? String ?? ""
        nonGeo = data["nonGeo"] as? Bool ?? false
        super.init(doc: doc)
        getDocuments(from: doc.reference.collection("comments")) { (comments) in
            for comment in comments {
                let newComment = Comment(doc: comment.document)
                self.comments.append(newComment)
            }
        }
        getDocuments(from: doc.reference.collection("likes")) { (likes) in
            for like in likes {
                let newLike = Like(doc: like.document)
                self.likes.append(newLike)
            }
        }
    }
}

public class User: UserPost {
    public var blocked: [String]
    public var followers: [String]
    public var numFollowers: Int {
        return followers.count
    }
    public var following: [String]
    public var numFollowing: Int {
        return following.count
    }
    private(set) var items: [ARItem]
    public func removeItem() {
    }
    public var name: String
    private(set) var imageName: String
    public func changeImage() {
        
    }
    public var bioText: String
    override public init(doc: DocumentSnapshot) {
        let data = doc.data()!
        name = data["username"] as? String ?? ""
        blocked = data["blocked"] as? [String] ?? [String]()
        followers = data["followers"] as? [String] ?? [String]()
        following = data["following"] as? [String] ?? [String]()
        items = [ARItem]()
        name = data["username"] as? String ?? ""
        imageName = data["imageName"] as? String ?? ""
        bioText = data["bioText"] as? String ?? ""
        super.init(doc: doc)
        
        getDocuments(from: doc.reference.collection("items")) { (docs) in
            for doc in docs {
                getDocument(from: db.collection(named: .items).document(doc.rawData![FirestoreKeys.name.rawValue] as! String), with: { (item) in
                    self.items.append(ARItem(doc: item.document))
                })
            }
        }
    }
}

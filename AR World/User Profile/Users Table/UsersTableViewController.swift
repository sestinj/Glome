//
//  UsersTableViewController.swift
//  AR World
//
//  Created by Nate Sesti on 10/24/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import Firebase
//This vc shows a list of all followers or following when the button in the bio is pressed
class UsersTableViewController: UITableViewController {
    var userUID: String!
    
    public var isRootBio = false
    
    public var navVC: UINavigationController!
    //The list type is either 'following' or 'followers'
    var listType: String!
    private var users = [User?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "UsersTableViewCell", bundle: nil), forCellReuseIdentifier: "usersReuseIdentifier")
        
        //Load the users, then reload table view
        getUser(uid: userUID) { (user) in
            var list = [String]()
            switch self.listType {
            case "followers":
                list = user.followers
            default:
                list = user.following
            }
            for uid in list {
                getUser(uid: uid) { (subUser) in
                    self.users.append(subUser)
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "usersReuseIdentifier", for: indexPath) as! UsersTableViewCell

        // Configure the cell...
        guard let user = users[indexPath.row] else {
            cell.usernameLabel.text = "User not found"
            return cell
        }
        
        cell.usernameLabel.text = user.name
        
        storage.reference().child(user.imageName).getData(maxSize: 10240*10240) { (imageData, err) in
            if let err = err {
                print(err)
            } else {
                guard let newImage = UIImage(data: imageData!) else {return}
                cell.profilePic.image = newImage
            }
        }
        
        
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let link = UsernameLinkButton(uid: users[indexPath.row]!.id, parentVC: self)
        link.openUserPage()
    }

    //Can edit to delete followers
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return listType == "following" && isRootBio
     }
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return [UITableViewRowAction(style: .destructive, title: "Unfollow", handler: { (action, path) in
            var newList = self.users.map { (user) -> String in
                return user!.uid
            }
            newList.remove(at: indexPath.row)
            let uid = auth.currentUser!.uid
            self.users.remove(at: indexPath.row)
            getUser(uid: uid) { (user) in
                user.reference.updateData([self.listType: newList])
            }
            self.tableView.deleteRows(at: [path], with: .fade)
        })]
    }
 
    
}

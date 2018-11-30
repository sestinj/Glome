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
    
    public var navVC: UINavigationController!
    //The list type is either 'following' or 'followers'
    var listType: String!
    private var documents = [DocumentSnapshot?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "UsersTableViewCell", bundle: nil), forCellReuseIdentifier: "usersReuseIdentifier")
        
        //Load the users, then reload table view
        db.collection("users").whereField("uid", isEqualTo: userUID).getDocuments { (querySnap1, err) in
            if let err = err {
                print(err)
            } else if querySnap1!.documents.count > 0 {
                if let list = querySnap1!.documents.first!.data()[self.listType] as? [String] {
                    var count = list.count
                    for uid in list {
                        count -= 1
                        db.collection("users").whereField("uid", isEqualTo: uid).getDocuments(completion: { (querySnap, err) in
                            if let err = err {
                                print(err)
                            } else if querySnap!.documents.count > 0 {
                                self.documents.append(querySnap1!.documents.first!)
                                if count < 1 {
                                    self.tableView.reloadData()
                                }
                            }
                        })
                    }
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return documents.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "usersReuseIdentifier", for: indexPath) as! UsersTableViewCell

        // Configure the cell...
        guard let doc  = documents[indexPath.row] else {
            cell.usernameLabel.text = "User not found"
            return cell
        }
        let name = doc.data()!["name"] as! String
        cell.usernameLabel.text = name
        if let imageName = doc.data()!["imageName"] as? String {
            storage.reference().child(imageName).getData(maxSize: 10240*10240) { (imageData, err) in
                if let err = err {
                    print(err)
                } else {
                    guard let newImage = UIImage(data: imageData!) else {return}
                    cell.profilePic.image = newImage
                }
            }
        }
        
        return cell
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
}

//
//  OtherAppsTableViewController.swift
//  PeterMeter
//
//  Created by Nate Sesti on 4/5/18.
//  Copyright © 2018 Apple Inc. All rights reserved.
//

import UIKit

class OtherAppsTableViewController: UITableViewController {
    
    
    func iTunes() {
        let urlString = URL(string: "https://itunes.apple.com/search?term=sam+sesti&entity=software&attribute=softwareDeveloper")
        if let url = urlString {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let usableData = data {
                        let json = try? JSONSerialization.jsonObject(with: usableData, options: [])
                        if let dictionary = json as? [String: Any] {
                            if let results = dictionary["results"] as? [[String:Any]], let resultsCount = dictionary["resultCount"] as? Int {
                                for result in results {
                                    if let name = result["trackName"] as? String, let iconURL = result["artworkUrl100"] as? String, let theURL = result["trackViewUrl"] as? String {
                                        DispatchQueue.main.async {
                                            self.apps.append(App(name: name, iconURL: URL(string: iconURL)!, url: URL(string: theURL)!))
                                            if self.apps.count == resultsCount {
                                                self.tableView.reloadData()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
            task.resume()
        }
    }
    
    var apps = [App]()

    // MARK: - Table view data source
    override func viewDidLoad() {
        self.tableView.register(OtherAppsTableViewCell.self, forCellReuseIdentifier: "otherAppsCellReuseIdentifier")
        iTunes()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return apps.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "otherAppsCellReuseIdentifier", for: indexPath) as! OtherAppsTableViewCell
        
        let app = apps[indexPath.row]
        cell.app = app
        
        cell.logoImageView.downloadedFrom(url: app.iconURL)
        cell.logoImageView.layer.masksToBounds = true
        cell.titleLabel.text = app.name

        // Configure the cell...

        return cell
    }
 
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120.0
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
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

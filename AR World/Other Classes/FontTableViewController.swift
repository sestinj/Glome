//
//  FontTableViewController.swift
//  AR World
//
//  Created by Nate Sesti on 11/28/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit

class FontTableViewController: UITableViewController {
    public var fontName: String = "Futura"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        
        self.navigationItem.title = "Select Font"
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UIFont.familyNames.count
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.navigationItem.leftBarButtonItem!.isEnabled = true
        self.fontName = UIFont.familyNames.sorted()[indexPath.row]
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        // Configure the cell...
        let fonts = UIFont.familyNames.sorted()
        cell.textLabel!.text = fonts[indexPath.row]
        cell.textLabel!.font = UIFont(name: fonts[indexPath.row], size: 20)

        return cell
    }
}

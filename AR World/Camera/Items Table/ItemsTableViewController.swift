//
//  ItemsTableViewController.swift
//  AR World
//
//  Created by Nate Sesti on 6/6/19.
//  Copyright © 2019 Nate Sesti. All rights reserved.
//

import UIKit

class ItemsTableViewController: UITableViewController {
    var nearItems = [ARItem]()
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        impact(style: .heavy)
        super.dismiss(animated: flag, completion: completion)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ItemsTableViewCell.self, forCellReuseIdentifier: "itemsReuseIdentifier")
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(nearItems.count)
        return nearItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemsReuseIdentifier", for: indexPath) as! ItemsTableViewCell
        cell.contentView.roundCorners(.allCorners, radius: 5.0)
        cell.contentView.backgroundColor = .lightGray
        let item = nearItems[indexPath.row]
        cell.item = item
        
//        cell.usernameLabel.text = item.username
//        cell.titleLabel.text = item.name
//        cell.likesButton.setTitle(String(item.numLikes), for: .normal)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let descriptionVC = DescriptionViewController()
        descriptionVC.doc = nearItems[indexPath.row]
        present(descriptionVC, animated: true, completion: nil)
    }

}

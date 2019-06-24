//
//  ItemsTableViewCell.swift
//  AR World
//
//  Created by Nate Sesti on 6/6/19.
//  Copyright © 2019 Nate Sesti. All rights reserved.
//

import UIKit

class ItemsTableViewCell: UITableViewCell {

    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var likesButton: UIButton!
    @IBAction func likesButtonPressed(_ sender: UIButton) {
        
    }
    public var item: ARItem!
    

}

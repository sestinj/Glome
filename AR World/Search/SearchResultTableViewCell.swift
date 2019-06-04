//
//  SearchResultTableViewCell.swift
//  AR World
//
//  Created by Nate Sesti on 12/5/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit

class SearchResultTableViewCell: UITableViewCell {

    @IBOutlet weak var usernameButton: UsernameLinkButton!
    
    @IBOutlet weak var userIcon: UIImageView!
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

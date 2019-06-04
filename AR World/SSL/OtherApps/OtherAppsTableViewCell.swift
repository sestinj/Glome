//
//  OtherAppsTableViewCell.swift
//  PeterMeter
//
//  Created by Nate Sesti on 4/5/18.
//  Copyright © 2018 Apple Inc. All rights reserved.
//

import UIKit

class OtherAppsTableViewCell: UITableViewCell {
    
    var app: App?
    
    var logoImageView: UIImageView!
    var titleLabel: UILabel!
    var appStoreButton: UIButton!
    
    @objc func appStoreButtonPressed() {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(app!.url, options: [:], completionHandler: nil)
        }
    }
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let view = contentView
        self.logoImageView = UIImageView(frame: CGRect(x: 20, y: self.contentView.frame.midY, width: 80, height: 80))
        self.logoImageView.layer.masksToBounds = true
        self.logoImageView.contentMode = .scaleAspectFit
        self.logoImageView.layer.cornerRadius = self.logoImageView.frame.width/4.5
        self.titleLabel = UILabel(frame: CGRect(x: 110, y: self.logoImageView.frame.minY, width: 300, height: 25))
        if !iPad() {
            self.appStoreButton = UIButton(frame: CGRect(x: self.contentView.frame.maxX - 70, y: self.logoImageView.frame.midY, width: 120, height: 47))
        } else {
            self.appStoreButton = UIButton(frame: CGRect(x: self.contentView.frame.maxX - 170, y: self.logoImageView.frame.midY, width: 120, height: 47))
        }
        self.appStoreButton.setImage(#imageLiteral(resourceName: "downloadOnTheAppStore"), for: .normal)
        self.appStoreButton.addTarget(self, action: #selector(appStoreButtonPressed), for: .touchUpInside)
        
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(appStoreButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}

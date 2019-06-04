//
//  CustomCalloutView.swift
//  AR World
//
//  Created by Nate Sesti on 12/1/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import Mapbox
import UIKit

class CustomCalloutView: UIView, MGLCalloutView {
    
    var representedObject: MGLAnnotation
    // Required views but unused for now, they can just relax
    lazy var leftAccessoryView = UIView()
    lazy var rightAccessoryView = UIView()
    
    weak var delegate: MGLCalloutViewDelegate?
    
    //MARK: Subviews -
    let titleLabel:UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 12.0)
        return label
    }()
    
    let subtitleLabel:UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10.0)
        return label
    }()
    
    let imageView:UIImageView = {
        let imageview = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        imageview.translatesAutoresizingMaskIntoConstraints = false
        imageview.contentMode = .scaleAspectFit
        return imageview
    }()
    
    required init(annotation: MGLAnnotation) {
        self.representedObject = annotation
        // init with 75% of width and 120px tall
        super.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: UIScreen.main.bounds.width * 0.4, height: UIScreen.main.bounds.width * 0.2)))
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        
        self.titleLabel.text = self.representedObject.title ?? ""
        self.subtitleLabel.text = self.representedObject.subtitle ?? ""
        setup()
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        // setup this view's properties
        self.backgroundColor = UIColor.white
        
        // And their Subviews
        self.addSubview(titleLabel)
        self.addSubview(subtitleLabel)
        self.addSubview(imageView)
        
        // Add Constraints to subviews
        let spacing:CGFloat = 2.0
        
        imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: spacing).isActive = true
        imageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: spacing).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 25.0).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 25.0).isActive = true
        
        titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: spacing).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: self.imageView.rightAnchor, constant: spacing * 2).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -spacing).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
        
        subtitleLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: spacing).isActive = true
        subtitleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: spacing).isActive = true
        subtitleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -spacing).isActive = true
        subtitleLabel.heightAnchor.constraint(equalToConstant: 10.0).isActive = true
    }
    
    
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        //Always, Slightly above center
        self.center = view.center
        view.addSubview(self)
    }
    
    func dismissCallout(animated: Bool) {
        if (animated){
            //do something cool
            removeFromSuperview()
        } else {
            removeFromSuperview()
        }
        
    }
}
// MGLPointAnnotation subclass
class CustomPointAnnotation: MGLPointAnnotation {
    var willUseImage: Bool = false
}

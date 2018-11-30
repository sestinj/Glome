//
//  itemAnnotation.swift
//  D4
//
//  Created by Nate Sesti on 7/15/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import MapKit

class ItemAnnotation: NSObject, MKAnnotation {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var color: UIColor
    var imageName: String
    
    init(title: String?, coordinate: CLLocationCoordinate2D, color: UIColor, imageName: String, subtitle: String) {
        self.title = title
        self.coordinate = coordinate
        self.color = color
        self.imageName = imageName
        self.subtitle = subtitle
        super.init()
    }
}

class ItemAnnotationView: MKAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let item = newValue as? ItemAnnotation else {return}
            image = UIImage(named: item.imageName)
        }
    }
}

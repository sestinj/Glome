//
//  iTunes.swift
//  Translate
//
//  Created by Nate Sesti on 6/14/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import Foundation

class App {
    var name: String!
    var iconURL: URL!
    var url: URL
    init(name: String, iconURL: URL, url: URL) {
        self.name = name
        self.iconURL = iconURL
        self.url = url
    }
}


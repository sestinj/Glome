//
//  DeviceType.swift
//  Translate
//
//  Created by Nate Sesti on 6/14/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation

func X() -> Bool {
    //Gets exact model of phone
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    
    if identifier.contains("iPhone10") {
        return true
    } else {
        return false
    }
}

func iPad() -> Bool {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    
    if !identifier.contains("iPhone") {
        return true
    } else {
        return false
    }
}

//
//  GeoQuery.swift
//  AR World
//
//  Created by Nate Sesti on 11/28/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import Foundation
import Firebase

func queryInRadius(miles: Double, _ collectionName: String, _ fieldName: String) -> Query? {
    //Radius is measured in miles
    guard let location = location else {return nil}
    let latitude = location.coordinate.latitude
    let longitude = location.coordinate.longitude
    // ~1 mile of lat and lon in degrees
    let lat = 0.0144927536231884
    let lon = 0.0181818181818182
    let distance = 20.0
    let lowerLat = latitude - (lat * distance)
    let lowerLon = longitude - (lon * distance)
    let greaterLat = latitude + (lat * distance)
    let greaterLon = longitude + (lon * distance)
    
    let lesserGeopoint = GeoPoint(latitude: lowerLat, longitude: lowerLon)
    let greaterGeopoint = GeoPoint(latitude: greaterLat, longitude: greaterLon)
    
    let query = db.collection(collectionName).whereField(fieldName, isGreaterThan: lesserGeopoint).whereField(fieldName, isLessThan: greaterGeopoint)
    return query
}

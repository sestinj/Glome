//
//  MapViewController.swift
//  D4
//
//  Created by Nate Sesti on 7/15/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class MapViewController: AuthHandlerViewController, MKMapViewDelegate {
    var nearItems = [CLLocation]()
    var annotationViewsDictionary = [ItemAnnotationView: DocumentSnapshot]()
    var parentVC: ViewController!
    
    
    //MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBAction func arrowButtonPressed(_ sender: UIButton) {
        if let parent = self.parent as? ViewController {
            parent.scrollView.scrollRectToVisible(CGRect(x: view.frame.width, y: 0, width: view.frame.width, height: view.frame.height), animated: true)
            parent.purplePin.setImage(#imageLiteral(resourceName: "clearPin"), for: .normal)
            parent.appTitle.setTitleColor(vibrantPurple, for: .normal)
            parent.userIcon.setImage(#imageLiteral(resourceName: "userIconBlack"), for: .normal)
            parent.lastVC = 2
        }
    }
    @objc private func originalLoadNearItems() {
        self.loadNearItems(inRadius: 20.0)
    }
    @objc private func loadNearItems(inRadius r: Double) {
        nearItems = [CLLocation]()
        
        guard let query = queryInRadius(miles: r, "items", "coordinates") else {let _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(originalLoadNearItems), userInfo: nil, repeats: false);return}
        
        query.getDocuments { (querySnap, err) in
            if let err = err {
                print(err)
            } else {
                //Get all items, then sort through which are close (THIS NEEDS TO BE DONE ON THE SERVER)
                guard let querySnap = querySnap else {return}
                guard let _ = querySnap.documents.first else {return}
                for doc in querySnap.documents {
                    if let coordinates = doc.data()["coordinates"] as? GeoPoint {
                        let clc = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                        self.nearItems.append(clc)
                        
                        //Create annotation for each item
                        let annotion = ItemAnnotation(title: doc.data()["Name"] as? String, coordinate: clc.coordinate, color: .cyan, imageName: "purplePinSmall", subtitle: doc.data()["username"] as? String ?? "")
                        let annotationView = ItemAnnotationView(annotation: annotion, reuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
                        self.mapView.addAnnotation(annotationView.annotation!)
                        self.annotationViewsDictionary[annotationView] = doc
                    }
                }
            }
        }
    }
    
    private var regionSize1 = false
    private var regionSize2 = false
    private var regionSize3 = false
    //69 miles ~= 1 degree of latitude
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        if mapView.region.span.latitudeDelta > 1 {
            if !regionSize3 {
                //Load all items within 69 miles
                loadNearItems(inRadius: 20)
            }
            regionSize3 = true
            regionSize2 = true
        } else if mapView.region.span.latitudeDelta > 5 {
            if !regionSize2 {
                //Load all items within ___ miles
                loadNearItems(inRadius: 5)
            }
            regionSize2 = true
            regionSize1 = true
        } else if mapView.region.span.latitudeDelta > 1 {
            if !regionSize1{
                //Load all items within 69 miles
                loadNearItems(inRadius: 1)
            }
            regionSize1 = true
        }
    }
    //MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        if X() {
            view.frame.size.height += 150
            mapView.frame.size.height += 150
        }
        
        //Map View
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = .satelliteFlyover
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        mapView.isRotateEnabled = true
        mapView.register(ItemAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        loadNearItems(inRadius: 20.0)
    }
}

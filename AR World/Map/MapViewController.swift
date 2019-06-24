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
import Mapbox
import CoreMotion

class MapViewController: AuthHandlerViewController, MGLMapViewDelegate, CardViewControllerDelegate {
    var nearItems = [CLLocation]()
    var annotationViewsDictionary = [CLLocationCoordinate2D: ARItem]()
    
    //Top level UI
    @IBOutlet weak var glomeButton: UIButton!
    @IBAction func glomeButtonPressed(_ sender: UIButton) {
    }
    var vibrantBanner: UIVisualEffectView!
    var topLine: CAShapeLayer!
    //MARK: Outlets
    var mapbox: MGLMapView!
    @objc private func originalLoadNearItems() {
        self.loadNearItems(inRadius: 20.0)
    }
    
    @objc private func loadItems(in bounds: MGLCoordinateBounds) {
        nearItems = [CLLocation]() //You could advance this later. Instead of reloading what you already have, only delete what is no longer in range. And only query for what is not in the old range.
        
        let latDiff = bounds.ne.latitude - bounds.sw.latitude
        let lonDiff = bounds.ne.longitude - bounds.sw.longitude
        let extensionFactor = 0.5
        let sw = GeoPoint(latitude: (bounds.sw.latitude - latDiff*extensionFactor).bounded(-90, 90), longitude: (bounds.sw.longitude - lonDiff*extensionFactor).bounded(-90, 90))
        let ne = GeoPoint(latitude: (bounds.ne.latitude - latDiff*extensionFactor).bounded(-180, 180), longitude: (bounds.ne.longitude - lonDiff*extensionFactor).bounded(-180, 180))
        let query = db.collection(named: .items).whereField(FirestoreKeys.coordinates.rawValue, isGreaterThan: sw).whereField(FirestoreKeys.coordinates.rawValue, isLessThan: ne)
        
        getDocuments(from: query) { (docs) in
            for doc in docs {
                let item = ARItem(doc: doc.document)
                let clc = CLLocation(latitude: item.coordinates.latitude, longitude: item.coordinates.longitude)
                self.nearItems.append(clc)
                
                //Create annotation for each item
                let annotation = CustomPointAnnotation()
                annotation.coordinate = clc.coordinate
                annotation.title = item.name
                annotation.subtitle = item.username
                annotation.willUseImage = true
                self.mapbox.addAnnotation(annotation)
                
                self.annotationViewsDictionary[annotation.coordinate] = item
            }
        }
    }
    @objc private func loadNearItems(inRadius r: Double) {
        nearItems = [CLLocation]()
        
        guard let query = queryInRadius(miles: r, "items", "coordinates") else {let _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(originalLoadNearItems), userInfo: nil, repeats: false);return}
        
        getDocuments(from: query) { (items) in
            for item in items {
                let doc = ARItem(doc: item.document)
                let clc = CLLocation(latitude: doc.coordinates.latitude, longitude: doc.coordinates.longitude)
                self.nearItems.append(clc)
                
                //Create annotation for each item
                let annotation = CustomPointAnnotation()
                annotation.coordinate = clc.coordinate
                annotation.title = doc.name
                annotation.subtitle = doc.username
                annotation.willUseImage = true
                self.mapbox.addAnnotation(annotation)
                
                self.annotationViewsDictionary[annotation.coordinate] = doc
            
            }
        }
    }
    //MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if X() {
            view.frame.size.height += 150
            glomeButton.frame.origin.y += 22
        }
        
        //Map View
        var urlString = "mapbox://styles/sestinj/cjwjkuysu6kyg1cp7vy3kkuaw" //Light URL
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                urlString = "mapbox://styles/sestinj/cjwjkwe4f0oc81coimtdblh0w" //Dark URL
            }
        }
        let url = URL(string: urlString)
        mapbox = MGLMapView(frame: view.bounds, styleURL: url)
        mapbox.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapbox)
        mapbox.delegate = self
        mapbox.showsUserLocation = true
        mapbox.userTrackingMode = .follow
        
        //Top Level UI
        vibrantBanner = UIVisualEffectView(frame: CGRect(x: 0, y: 83-150, width: view.frame.width, height: 150))
        vibrantBanner.layer.zPosition = 4
        vibrantBanner.effect = UIBlurEffect(style: .light)
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                vibrantBanner.effect = UIBlurEffect(style: .dark)
            }
        }
        view.addSubview(vibrantBanner)
        
        
        topLine = CAShapeLayer()
        topLine.path = CGPath(rect: CGRect(x: 0, y: 83, width: view.frame.width, height: 3), transform: nil)
        view.layer.addSublayer(topLine)
        if !X() {
            topLine.frame.origin.y -= 22
            vibrantBanner.frame.origin.y -= 22
        }
        glomeButton.layer.zPosition = 5
        
//        loadItems(in: MGLCoordinateBounds(sw: CLLocationCoordinate2D(latitude: (mapbox.userLocation!.coordinate.latitude - 0.2).bounded(-90.0, 90.0), longitude: (mapbox.userLocation!.coordinate.longitude - 0.2).bounded(-180.0, 180.0)), ne: CLLocationCoordinate2D(latitude: (mapbox.userLocation!.coordinate.latitude + 0.2).bounded(-90.0, 90.0), longitude: (mapbox.userLocation!.coordinate.longitude + 0.2).bounded(-180.0, 180.0))))
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        vibrantBanner.effect = UIBlurEffect(style: .light)
        var urlString = "mapbox://styles/sestinj/cjwjkuysu6kyg1cp7vy3kkuaw" //Light URL
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                vibrantBanner.effect = UIBlurEffect(style: .dark)
                urlString = "mapbox://styles/sestinj/cjwjkwe4f0oc81coimtdblh0w" //Dark URL
            }
        }
        let url = URL(string: urlString)
        mapbox.styleURL = url
        mapbox.reloadStyle(nil)
    }
    override func viewDidLayoutSubviews() {
        mapbox.compassView.frame.origin.y += mapbox.compassView.frame.height
    }
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return nil
    }
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "camera")
        
        // If there is no reusable annotation image available, initialize a new one.
        if(annotationImage == nil) {
            annotationImage = MGLAnnotationImage(image: UIImage(named: "purplePinSmall")!, reuseIdentifier: "camera")
        }
        
        return annotationImage
    }
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        let card = CardViewController()
        card.delegate = self
        view.addSubview(card.view)
        addChild(card)
        
        guard let doc = annotationViewsDictionary[annotation.coordinate] else {return}
        let vc = DescriptionViewController()
        vc.doc = doc
        
        card.view.addSubview(vc.view)
        card.addChild(vc)
    }
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        //Do you want to use regionIsChanging instead for a smoother experience but more loads?
        let bounds = mapbox.visibleCoordinateBounds
        loadItems(in: bounds)
    }
}

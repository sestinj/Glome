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

class MapViewController: AuthHandlerViewController, MGLMapViewDelegate {
    var nearItems = [CLLocation]()
    var annotationViewsDictionary = [CLLocationCoordinate2D: ARItem]()
    var parentVC: ViewController!
    
    
    //MARK: Outlets
    var mapbox: MGLMapView!
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
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        let ne = mapView.visibleCoordinateBounds.ne, sw = mapView.visibleCoordinateBounds.sw
        let latDelta = ne.latitude - sw.latitude
        if latDelta > 1 {
            if !regionSize3 {
                //Load all items within 69 miles
                loadNearItems(inRadius: 20)
            }
            regionSize3 = true
            regionSize2 = true
        } else if latDelta > 5 {
            if !regionSize2 {
                //Load all items within ___ miles
                loadNearItems(inRadius: 5)
            }
            regionSize2 = true
            regionSize1 = true
        } else if latDelta > 1 {
            if !regionSize1{
                //Load all items within 69 miles
                loadNearItems(inRadius: 1)
            }
            regionSize1 = true
        }
    }
    @IBOutlet weak var arrowButton: UIButton!
    //MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if X() {
            view.frame.size.height += 150
        }
        
        //Map View
        let url = URL(string: "mapbox://styles/sestinj/cjw6qpo2905ms1cs5588sqa0q")
        mapbox = MGLMapView(frame: view.bounds, styleURL: url)
        mapbox.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapbox)
        mapbox.delegate = self
        mapbox.showsUserLocation = true
        mapbox.userTrackingMode = .follow

        self.view.bringSubviewToFront(arrowButton)
        loadNearItems(inRadius: 20.0)
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
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        // Optionally handle taps on the callout.
        // Hide the callout.
        mapView.deselectAnnotation(annotation, animated: true)
        guard let doc = annotationViewsDictionary[annotation.coordinate] else {return}
        let vc = DescriptionViewController()
        vc.camVC = self.parentVC.camVC
        vc.doc = doc
        present(vc, animated: true, completion: nil)
        parentVC.scrollView.scrollRectToVisible(parentVC.camVC.view.frame, animated: false)
    }
}

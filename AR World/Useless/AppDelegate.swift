//
//  AppDelegate.swift
//  AR World
//
//  Created by Nate Sesti on 9/8/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import CoreLocation
import GoogleSignIn
import SwiftyGiphy

var applicationDelegate: UIApplicationDelegate!
var location: CLLocation?
//var auth: FUIAuth!
var auth: Auth!
var db: Firestore!
var storage: Storage!
var mainVC: ViewController!
var referralDatabase: Firestore!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {


    var window: UIWindow?
    public var locationManager: CLLocationManager?

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first!
        //SHOULD RELOAD MAP AND NEAR ITEMS HERE
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        SwiftyGiphyAPI.shared.apiKey = "KLqJTmi5nTLVex52N6su5TULWWWjf0vv"
        applicationDelegate = self
        
        //FIREBASE
        FirebaseApp.configure()
        storage = Storage.storage()
        db = Firestore.firestore()
        let settings = db.settings
        db.settings = settings
        
        auth = Auth.auth()
        
        //Authorization
        // You need to adopt a FUIAuthDelegate protocol to receive callback
//        auth = FUIAuth.defaultAuthUI()!
//        auth.delegate = self
//        let providers: [FUIAuthProvider] = [
//            FUIGoogleAuth(scopes: [kGoogleUserInfoEmailScope])
//            ]
//        auth.providers = providers
        
        //Location manager
        locationManager = CLLocationManager()
        locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        locationManager!.headingFilter = 5
        locationManager!.pausesLocationUpdatesAutomatically = false
        locationManager!.distanceFilter = 25
        locationManager!.requestWhenInUseAuthorization()
        locationManager!.delegate = self
        locationManager!.startUpdatingLocation()
        //Authorization
        
        
        //Styling
        let navA = UINavigationBar.appearance()
        navA.tintColor = vibrantPurple
        
        
        
        //Referral Database Setup
        let secondaryOptions = FirebaseOptions(googleAppID: "1:449196890018:ios:33b29ea025479d14", gcmSenderID: "449196890018")
        secondaryOptions.bundleID = "NateSesti.AR-World"
        secondaryOptions.apiKey = "AIzaSyAPpvve05saOWK7N65p59444Zm7FIqV8xA"
        secondaryOptions.clientID = "449196890018-m69ot4ke7akkqfe2i32eqnau22sge9ta.apps.googleusercontent.com"
        secondaryOptions.databaseURL = "https://referral-database.firebaseio.com"
        secondaryOptions.storageBucket = "referral-database.appspot.com"
        // Configure an alternative FIRApp.
        FirebaseApp.configure(name: "referral", options: secondaryOptions)
        // Retrieve a previous created named app.
//        guard let _ = FirebaseApp.app(name: "referral")
//            else { assert(false, "Could not retrieve referral app") }
        // Retrieve a Real Time Database client configured against a specific app.
//        referralDatabase = Firestore.firestore(app: referral)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


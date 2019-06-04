//
//  CameraViewController.swift
//  D4
//
//  Created by Nate Sesti on 7/15/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation
import Firebase
import SwiftyGiphy
import ReplayKit

class CameraViewController: AuthHandlerViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, SwiftyGiphyViewControllerDelegate, RPPreviewViewControllerDelegate {
    
    //MARK: SwiftyGiphyViewControllerDelegate
    func giphyControllerDidSelectGif(controller: SwiftyGiphyViewController, item: GiphyItem) {
        controller.dismiss(animated: true, completion: nil)
        if let url = item.originalImage!.url {
            addItemDocument(data: ["Media Type": "Gif", "Gif URL": url.absoluteString])
        }
    }
    func giphyControllerDidCancel(controller: SwiftyGiphyViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    var parentVC: ViewController!
    var nearItems = [CLLocation]()
    var nodesDictionary = [SCNNode:ARItem]()
    var documents = [ARItem]()
    
    //MARK: Outlets
    @objc func longRecognizer(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began || sender.state == .ended else {return}
        if recordingReady {
            recordingReady = false
            startRecording()
        } else if recording {
            stopRecording()
        }
    }
    @objc func tapRecognizer(_ sender: UITapGestureRecognizer) {
        if !recording && !recordingReady {
            //If content is touched, open its description views
            let position = sender.location(in: arScene)
            guard let first = arScene.hitTest(position, options: nil).first else {return}
            let node = first.node
            guard let document = nodesDictionary[node] else {return}
            
            let descriptionVC = DescriptionViewController()
            descriptionVC.doc = document
            descriptionVC.camVC = self
            present(descriptionVC, animated: true, completion: nil)
        }
        if recordingReady {
            //Take photo
            recordingLabel.alpha = 0.0
            recordingCircle.opacity = 0.0
            
            let img = arScene.snapshot()
            let activity = UIActivityViewController(activityItems: [img], applicationActivities: nil)
            present(activity, animated: true, completion: nil)
            
            let flash = CAShapeLayer()
            flash.path = CGPath(rect: UIApplication.shared.keyWindow!.layer.frame, transform: nil)
            flash.fillColor = UIColor.white.cgColor
            UIApplication.shared.keyWindow!.layer.addSublayer(flash)
            let _ = Timer.scheduledTimer(timeInterval: 0.25, target: flash, selector: #selector(flash.remove), userInfo: nil, repeats: false)
            
            recordingReady = false
            recording = false
            showButtonsAfterRecording()
        }
    }
    var long: UILongPressGestureRecognizer!
    var short: UITapGestureRecognizer!
    @IBOutlet weak var arScene: ARSCNView!
    @IBOutlet weak var fxViewReset: UIVisualEffectView!
    @IBOutlet weak var fxViewPlus: UIVisualEffectView!
    @IBOutlet weak var fxViewEye: UIVisualEffectView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var eyeButton: UIButton!
    var buttonsAreVisible = true
    @IBAction func eyePressed(_ sender: UIButton) {
        hideButtonsForRecording()
    }
    @IBOutlet weak var cameraButton: UIButton!
    @IBAction func resetButtonPressed(_ sender: UIButton) {
//        let s = SearchViewController()
//        let nav = UINavigationController(rootViewController: s)
//        nav.delegate = self
//        present(nav, animated: true, completion: nil)
        if !(sender == cameraButton) {
            loadNearItems()
        }
    }
    //Camera Button (Toolbar for posting)
    private func extendCameraButton() {
        guard defaults.bool(forKey: "eula") else {
            parentVC.showPopUpView(type: .eula)
            return
        }
        
        
        let height: CGFloat = 250.0
        cameraButton.setTitle("-", for: .normal)
        fxViewPlus.frame.size.height += height
        fxViewPlus.frame.origin.y -= height
        var frame = cameraButton.frame
        frame.size.width -= 16
        frame.size.height -= 16
        frame.origin.x += 8
        frame.origin.y += 8
        
        let buttons = ["image": #selector(selectPhoto), "giphy": #selector(selectGif), "text": #selector(selectText), "cube": #selector(selectShape), "paintBrush":#selector(selectDrawing)]
        for button in buttons {
            frame.origin.y += frame.height
            let newButton = UIButton(frame: frame)
            newButton.setBackgroundImage(UIImage(named: button.key), for: .normal)
            newButton.contentMode = .scaleAspectFit
            newButton.addTarget(self, action: button.value, for: .touchUpInside)
            fxViewPlus.contentView.addSubview(newButton)
        }
    }
    private func shortenCameraButton() {
        let height: CGFloat = 250.0
        fxViewPlus.frame.size.height -= height
        fxViewPlus.frame.origin.y += height
        for button in fxViewPlus.contentView.subviews {
            if let button = button as? UIButton {
                if button.title(for: .normal) != "+" && button.title(for: .normal) != "-" {
                    button.removeFromSuperview()
                }
            }
        }
        cameraButton.setTitle("+", for: .normal)
    }
    @IBAction func cameraButtonPressed(_ sender: UIButton) {
        if sender == cameraButton {
            
            if sender.title(for: .normal) == "+" {
                extendCameraButton()
            } else {
                shortenCameraButton()
            }
        }
    }
    
    
    public var gifVC: SwiftyGiphyViewController!
    @objc func selectGif() {
        shortenCameraButton()
        gifVC = SwiftyGiphyViewController()
        gifVC.delegate = self
        
        
        let navVC = UINavigationController(rootViewController: gifVC)
        navVC.delegate = self
        self.present(navVC, animated: true, completion: nil)
    }
    @objc func selectShape() {
        shortenCameraButton()
        parentVC.showPopUpView(type: .colorPicker)
    }
    @objc func selectDrawing() {
        shortenCameraButton()
        drawVC = DrawingViewController()
        drawVC.navigationItem.title = "DRAW"
        drawVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(addDrawing))
        let navVC = UINavigationController(rootViewController: drawVC)
        present(navVC, animated: true, completion: nil)
    }
    @objc func addShape() {
        addItemDocument(data: ["Media Type": "Shape", "Color": [Int(addTextParamColor.r()*255), Int(addTextParamColor.g()*255), Int(addTextParamColor.b()*255)]])
    }
    @objc func selectText() {
        shortenCameraButton()
        parentVC.showPopUpView(type: .textProperties)
    }
    var addTextParamText: String!
    var addTextParamColor: UIColor!
    var addTextParamFont: String!
    var drawVC: DrawingViewController!
    @objc func addText() {
        self.addItemDocument(data: ["Media Type": "Text", "Text": addTextParamText as Any, "Color": [Int(addTextParamColor.r()*255), Int(addTextParamColor.g()*255), Int(addTextParamColor.b()*255)], "Font": addTextParamFont as Any])
    }
    @objc func addDrawing() {
        guard let image = drawVC.getImage() else {drawVC.dismiss(animated: true, completion: nil);return}
        //Add image to Firebase/Storage
        let root = storage.reference()
        let name = "\(CGFloat(low: 0.0, high: 100000.0))"
        let newRef = root.child(name)
        guard let png = image.pngData() else {return}
        newRef.putData(png, metadata: nil) { (metaData, err) in
            if let err = err {
                print(err)
            }
        }
        
        dismiss(animated: true, completion: nil)
        //Add document to Firebase/Firestore
        addItemDocument(data: ["photoid": name, "Media Type": "Photo"])
    }
    
    
    //Mark: Image Picker Controller Delegate
    @objc func selectPhoto() {
        shortenCameraButton()
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        guard let selectedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            return
        }
        
        //Add image to Firebase/Storage
        let root = storage.reference()
        let name = "\(CGFloat(low: 0.0, high: 100000.0))"
        let newRef = root.child(name)
        guard let png = selectedImage.pngData() else {return}
        newRef.putData(png, metadata: nil) { (metaData, err) in
            if let err = err {
                print(err)
            }
        }
        
        dismiss(animated: true, completion: nil)
        //Add document to Firebase/Firestore
        addItemDocument(data: ["photoid": name, "Media Type": "Photo"])
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeKeysInDatabase(from: "bioText", to: "biotext", in: .users, true)
        changeKeysInDatabase(from: "imageName", to: "photoid", in: .users, true)
        
        recordingLabel = UILabel(frame: CGRect(x: view.frame.midX - 125, y: view.frame.midY - 50, width: 250, height: 100))
        recordingLabel.text = "Hold anywhere to record. Tap for a picture."
        recordingLabel.font = UIFont.systemFont(ofSize: 20)
        recordingLabel.textColor = .white
        recordingLabel.numberOfLines = 2
        recordingLabel.textAlignment = .center
        recordingLabel.alpha = 0.0
        view.addSubview(recordingLabel)
        
        recordingCircle = CAShapeLayer()
        recordingCircle.fillColor = UIColor.red.cgColor
        recordingCircle.path = CGPath(ellipseIn: CGRect(origin: CGPoint(x: view.frame.maxX - 25, y: view.frame.minY + 25), size: CGSize(20)), transform: nil)
        recordingCircle.opacity = 0.0
        view.layer.addSublayer(recordingCircle)
        
        if X() {
            view.frame.size.height += 150
            arScene.frame.size.height += 150
            fxViewReset.frame.origin.y += 150
            fxViewPlus.frame.origin.y += 150
            fxViewEye.frame.origin.y += 150
        }
        
        arScene.delegate = self
        loadNearItems()
        
        eyeButton.causesImpact(.light)
        resetButton.causesImpact(.light)
        
        fxViewPlus.layer.roundCorners()
        fxViewEye.layer.roundCorners()
        cameraButton.tintColor = .white
        cameraButton.causesImpact(.medium)
        resetButton.tintColor = .white
        eyeButton.tintColor = .white
        fxViewPlus.layer.borderColor = UIColor.white.cgColor
        fxViewEye.layer.borderWidth = 2
        fxViewEye.layer.borderColor = UIColor.white.cgColor
        fxViewReset.layer.borderColor = UIColor.white.cgColor
        fxViewReset.layer.borderWidth = 2
        fxViewPlus.layer.borderWidth = 2
        fxViewReset.layer.roundCorners()
        
        
        //Gestures
        long = UILongPressGestureRecognizer(target: self, action: #selector(longRecognizer(_:)))
        long.delegate = self
        view.addGestureRecognizer(long)
        short = UITapGestureRecognizer(target: self, action: #selector(tapRecognizer(_:)))
        short.delegate = self
        view.addGestureRecognizer(short)
    }
    
    
    //MARK: Functions
    func cleanItems() {
        //Removes all items that have been present for more than 24 hours - THIS SHOULD BE HAPPENING SERVERSIDE!!
        if arc4random_uniform(50) > 0 {
            getDocuments(from: db.collection("items")) { (docs) in
                for doc in docs {
                    let item = ARItem(doc: doc.document)
                    let date = Date()
                    let inter = date.timeIntervalSince(item.date)
                    if inter > 60*60*24 {
                        doc.reference.delete()
                    }
                }
            }
        }
    }
    
    func decidePosition(fromCoordinates loc: CLLocation) -> SCNVector3? {
        guard let location = location else {return nil}
        
        let baseLocation = CLLocation(latitude: location.coordinate.latitude, longitude: loc.coordinate.longitude)
        //the distance function is absolute value, so signs must be determined manually
        var dxSign = 1.0
        var dzSign = 1.0
        var dx = loc.coordinate.longitude - location.coordinate.longitude
        if dx < 0 {
            dxSign = -1.0
        }
        dx = baseLocation.distance(from: location)*dxSign
        var dz = loc.coordinate.latitude - location.coordinate.latitude
        if dz < 0 {
            dzSign = -1.0
        }
        dz = baseLocation.distance(from: loc)*dzSign
        var vec = SCNVector3(dx, 0, dz * -1)
        //At this point, the vector is correct, assuming the user was facing North
        let tvec = SCNVector3(vec.x, vec.y, vec.z)
        var bearing = location.course
        bearing = 90 + bearing
        let by = GLKMathDegreesToRadians(Float(bearing))
        vec.x = cos(by * tvec.x) - sin(by * tvec.z)
        vec.z = sin(by * tvec.x) + cos(by * tvec.z)
        
        return vec
    }
    
    
    
    func addItemDocument(data: [String:Any]) {
        var newData = data
        guard let currentUser = auth.currentUser else {
            //Cannot post unless the user is signed in
            let alert = UIAlertController(title: nil, message: "You must be signed in to post", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            alert.view.tintColor = vibrantPurple
            present(alert, animated: true, completion: nil)
            return
        }
        newData["uid"] = currentUser.uid
        newData["username"] = currentUser.displayName ?? "?"
        guard let location = location else {return}
        newData["coordinates"] = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        let alert = UIAlertController(title: "New Item", message: "Name your item.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.view.tintColor = vibrantPurple
        alert.addTextField(configurationHandler: nil)
        let addAction = UIAlertAction(title: "Next", style: .default) { (action) in
            guard let field = alert.textFields!.first else {return}
            newData["name"] = field.text!
            //Add doc id to user
            let newID = db.collection("items").addDocument(data: newData).documentID
            getUser(uid: currentUser.uid, with: { (user) in
                user.reference.collection("items").document(newID).setData(["name":field.text!])
            })
        }
        alert.addAction(addAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func showIntro() {
//        let wData: [String:Any] = ["Media Type":"Photo", "uid": "VlgVcTvcUfW2PdGp17xS1O8z2vG2", "Name": "Glome", "Photo Name": "iTunesArtwork@1x.png", "coordinates": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)]
        getFirstDocument(from: db.collection(named: .items).whereField("photoid", isEqualTo: "iTunesArtwork@1x.png"), with: { (doc) in
            let item = ARItem(doc: doc.document)
            item.coordinates = location!.coordinate
            let newNode = self.createNewNode(item: item)
            self.nodesDictionary[newNode] = item
        })
        defaults.set(false, forKey: "intro")
    }
    
    @objc func loadNearItems() {
        nodesDictionary = [SCNNode:ARItem]()
        cleanItems()
        if defaults.bool(forKey: "intro") {
            showIntro()
        }
        
        guard let query = queryInRadius(miles: 1.0/32.0, "items", "coordinates") else {let _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(loadNearItems), userInfo: nil, repeats: false);return}
        getDocuments(from: query) { (querySnap) in
            for doc in querySnap {
                let item = ARItem(doc: doc.document)
                let loc = CLLocation(latitude: item.coordinates.latitude, longitude: item.coordinates.longitude)
                //THIS SHOULDN"T NEED TO BE HERE> FIND THE WAY TO USE THAT QUERY IN RADIUS THING _ ITS VITAL WHEN DATA GETS BIG
                if location!.distance(from: loc) < 100 {
                    let newNode = self.createNewNode(item: item)
                    self.nodesDictionary[newNode] = item
                }
            }
            self.resetTracking()
        }
//        query.getDocuments { (querySnap, err) in
//            if let err = err {
//                print(err)
//            } else {
//                //Is this returning from the function or the closure? Might want to make this an if let statement.
//                guard let querySnap = querySnap else {return}
//                guard let _ = querySnap.documents.first else {return}
//                for doc in querySnap.documents {
//                    let geoPoint = doc.data()["coordinates"] as! GeoPoint
//                    let loc = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
//                    //THIS SHOULDN"T NEED TO BE HERE> FIND THE WAY TO USE THAT QUERY IN RADIUS THING _ ITS VITAL WHEN DATA GETS BIG
//                    if location!.distance(from: loc) < 100 {
//                        let newNode = self.createNewNode(data: doc.data())
//                        self.nodesDictionary[newNode] = doc
//                    }
//                }
//                self.resetTracking()
//            }
//        }
    }
    
    
    func createNewNode(item: ARItem) -> SCNNode {
        
        var node: SCNNode!
        
        switch item.mediaType {
        case .text(let font, let color, let text):
            let geo = SCNText(string: text, extrusionDepth: 0.25)
            geo.font = UIFont(name: font, size: 14)
            //Ask for text's font
            
            let mat = SCNMaterial()
            mat.diffuse.contents = color
            
            mat.isDoubleSided = true
            geo.firstMaterial = mat
            node = SCNNode(geometry: geo)
            node.scale = SCNVector3(x: 0.2, y: 0.2, z: 0.2)
        case .gif(let url):
            let gifImage = UIImage.gif(url: url.absoluteString)
            let gifImageView = UIImageView(image: gifImage)
            let gifPlane = SCNPlane(width: 1.0, height: 1.0)
            let material = SCNMaterial()
            material.diffuse.contents = gifImageView.layer
            material.isDoubleSided = true
            gifPlane.firstMaterial = material
            node = SCNNode(geometry: gifPlane)
            
        case .photo(let photoName):
            let geo = SCNPlane(width: 1.0, height: 1.0)
            let mat = SCNMaterial()
            mat.diffuse.contents = vibrantPurple
            mat.isDoubleSided = true
            geo.firstMaterial = mat
            node = SCNNode(geometry: geo)
            //Load photo from Firebase/Storage
            storage.reference().child(photoName).getData(maxSize: 10240*10240) { (imageData, err) in
                if let err = err {
                    print(err)
                } else {
                    guard let newImage = UIImage(data: imageData!) else {return}
                    node.geometry!.materials.first!.diffuse.contents = newImage
                }
            }
        case .shape(let color):
            let geo = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            let mat1 = SCNMaterial()
            mat1.diffuse.contents = color
                
            geo.firstMaterial = mat1
            node = SCNNode(geometry: geo)
        }
        
        let position: SCNVector3!
        if item.nonGeo {
            //For single items and introductory items
            position = SCNVector3(0, 0, -1)
        } else {
            position = decidePosition(fromCoordinates: CLLocation(latitude: item.coordinates.latitude, longitude: item.coordinates.longitude))
        }
        node.position = position!
        switch item.mediaType {
        case .text:
            node.position.y -= 0.5
        default:
            break
        }
        
        return node
    }
    
    func resetTracking() {
        print("Reset Tracking")
        arScene.session = ARSession()
        let config = ARWorldTrackingConfiguration()
        arScene.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        for node in arScene.scene.rootNode.childNodes {
            node.removeFromParentNode()
        }
        
        for item in nodesDictionary.keys {
            arScene.scene.rootNode.addChildNode(item)
        }
    }
    
    //MARK:BETA ZONE: __________________________________________
    @objc func loadItemStatic() {
        nodesDictionary = [SCNNode:ARItem]()
        //For previewing new content
        //Adds item directly in front of the camera, no matter how it moves or rotates
    }
    public var singleDocToLoad: ARItem!
    @objc func loadItemNonGeo() {
        nodesDictionary = [SCNNode:ARItem]()
        singleDocToLoad.nonGeo = true
        let node = createNewNode(item: singleDocToLoad)
        self.nodesDictionary[node] = singleDocToLoad
        parentVC.scrollView.scrollRectToVisible(parentVC.camVC.view.frame, animated: false)
        resetTracking()
        //For viewing remotely from bio, etc...
        //Adds item in front of camera, not based on geography, but it stays in that spot when phone moves (normal AR mode)
    }
    //MARK: Recording
    var recordingCircle: CAShapeLayer!
    var recordingLabel: UILabel!
    var recording = false
    var recordingReady = false
    let recorder = RPScreenRecorder.shared()
    func hideButtonsForRecording() {
        recordingReady = true
        //Opacities
        recordingLabel.alpha = 1.0
        parentVC.scrollView.isScrollEnabled = false
        fxViewEye.alpha = 0.0
        fxViewReset.alpha = 0.0
        fxViewPlus.alpha = 0.0
        buttonsAreVisible = false
        recordingCircle.opacity = 1.0
        parentVC.topBackground.opacity = 0.0
        parentVC.topLine.opacity = 0.0
        parentVC.appTitle.alpha = 0.0
        parentVC.purplePin.alpha = 0.0
        parentVC.userIcon.alpha = 0.0
        
        
    }
    
    func showButtonsAfterRecording() {
        recordingCircle.removeAnimation(forKey: "recording")
        recordingLabel.alpha = 0.0
        //Opacities
        parentVC.scrollView.isScrollEnabled = true
        fxViewEye.alpha = 1.0
        fxViewReset.alpha = 1.0
        fxViewPlus.alpha = 1.0
        buttonsAreVisible = true
        recordingCircle.opacity = 0.0
        parentVC.topBackground.opacity = 0.5
        parentVC.topLine.opacity = 1.0
        parentVC.appTitle.alpha = 1.0
        parentVC.purplePin.alpha = 1.0
        parentVC.userIcon.alpha = 1.0
    }
    @objc func startRecording() {
        recording = true
        recordingLabel.alpha = 0.0
        let recordingAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        recordingAnimation.fromValue = 1.0
        recordingAnimation.toValue = 0.0
        recordingAnimation.duration = 0.75
        recordingAnimation.autoreverses = true
        recordingAnimation.repeatCount = Float.infinity
        recordingCircle.add(recordingAnimation, forKey: "recording")
        guard recorder.isAvailable else {
            print("Recording is not available at this time.")
            return
        }
        recorder.startRecording{ [] (error) in
            guard error == nil else {
                print("There was an error starting the recording.")
                return
            }
            print("Started Recording Successfully")
        }
    }
    
    @objc func stopRecording() {
        recording = false
        showButtonsAfterRecording()
        recorder.stopRecording { [unowned self] (preview, error) in
            print("Stopped recording")
            guard preview != nil else {
                print("Preview controller is not available.")
                return
            }
            let alert = UIAlertController(title: "Recording Finished", message: "Would you like to edit or delete your recording?", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
                self.recorder.discardRecording(handler: { () -> Void in
                    print("Recording suffessfully deleted.")
                })
            })
            let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
                preview?.previewControllerDelegate = self
                self.present(preview!, animated: true, completion: nil)
            })
            alert.addAction(editAction)
            alert.addAction(deleteAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

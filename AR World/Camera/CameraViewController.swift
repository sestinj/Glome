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

class CameraViewController: AuthHandlerViewController, ARSCNViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, SwiftyGiphyViewControllerDelegate {
    
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
    var nodesDictionary = [SCNNode:DocumentSnapshot]()
    var documents = [DocumentSnapshot]()
    
    //MARK: Outlets
    @IBOutlet var doubleTapRecognizer: UITapGestureRecognizer!
    @IBAction func doubleTap(_ sender: UITapGestureRecognizer) {
        if !buttonsAreVisible {
            fxViewEye.alpha = 1.0
            fxViewReset.alpha = 1.0
            fxViewPlus.alpha = 1.0
            buttonsAreVisible = true
        }
    }
    @IBOutlet weak var arScene: ARSCNView!
    @IBOutlet weak var fxViewReset: UIVisualEffectView!
    @IBOutlet weak var fxViewPlus: UIVisualEffectView!
    @IBOutlet weak var fxViewEye: UIVisualEffectView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var eyeButton: UIButton!
    var buttonsAreVisible = true
    @IBAction func eyePressed(_ sender: UIButton) {
        fxViewEye.alpha = 0.0
        fxViewReset.alpha = 0.0
        fxViewPlus.alpha = 0.0
        buttonsAreVisible = false
    }
    @IBOutlet weak var cameraButton: UIButton!
    @IBAction func resetButtonPressed(_ sender: UIButton) {
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
    @objc func selectGif() {
        shortenCameraButton()
        let gifVC = SwiftyGiphyViewController()
        gifVC.delegate = self
        let navVC = UINavigationController()
        navVC.viewControllers = [gifVC]
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
        self.addItemDocument(data: ["Media Type": "Text", "Text": addTextParamText, "Color": [Int(addTextParamColor.r()*255), Int(addTextParamColor.g()*255), Int(addTextParamColor.b()*255)], "Font": addTextParamFont])
    }
    @objc func addDrawing() {
        guard let image = drawVC.getImage() else {drawVC.dismiss(animated: true, completion: nil);return}
        //Add image to Firebase/Storage
        let root = storage.reference()
        let name = "\(CGFloat(low: 0.0, high: 100000.0))"
        let newRef = root.child(name)
        guard let png = UIImagePNGRepresentation(image) else {return}
        newRef.putData(png, metadata: nil) { (metaData, err) in
            if let err = err {
                print(err)
            }
        }
        
        dismiss(animated: true, completion: nil)
        //Add document to Firebase/Firestore
        addItemDocument(data: ["Photo Name": name, "Media Type": "Photo"])
    }
    
    
    //Mark: Image Picker Controller Delegate
    @objc func selectPhoto() {
        shortenCameraButton()
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        //Add image to Firebase/Storage
        let root = storage.reference()
        let name = "\(CGFloat(low: 0.0, high: 100000.0))"
        let newRef = root.child(name)
        guard let png = UIImagePNGRepresentation(selectedImage) else {return}
        newRef.putData(png, metadata: nil) { (metaData, err) in
            if let err = err {
                print(err)
            }
        }
        
        dismiss(animated: true, completion: nil)
        //Add document to Firebase/Firestore
        addItemDocument(data: ["Photo Name": name, "Media Type": "Photo"])
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if X() {
            view.frame.size.height += 150
            arScene.frame.size.height += 150
            fxViewReset.frame.origin.y += 150
            fxViewPlus.frame.origin.y += 150
            fxViewEye.frame.origin.y += 150
        }
        
        arScene.delegate = self
        loadNearItems()
        
        fxViewPlus.layer.roundCorners()
        fxViewEye.layer.roundCorners()
        cameraButton.tintColor = .white
        resetButton.tintColor = .white
        eyeButton.tintColor = .white
        fxViewPlus.layer.borderColor = UIColor.white.cgColor
        fxViewEye.layer.borderWidth = 2
        fxViewEye.layer.borderColor = UIColor.white.cgColor
        fxViewReset.layer.borderColor = UIColor.white.cgColor
        fxViewReset.layer.borderWidth = 2
        fxViewPlus.layer.borderWidth = 2
        fxViewReset.layer.roundCorners()
        
        //Gesture recognizer
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delegate = self
    }
    
    
    //MARK: Functions
    func cleanItems() {
        //Removes all items that have been present for more than 24 hours
        if arc4random_uniform(50) > 0 {
            db.collection("items").getDocuments { (querySnap, err) in
                if let err = err {
                    print(err)
                } else {
                    guard let querySnap = querySnap else {return}
                    guard let _ = querySnap.documents.first else {return}
                    for doc in querySnap.documents {
                        if let time = doc.data()["time"] as? Timestamp{
                            let date = Date()
                            let inter = date.timeIntervalSince(time.dateValue())
                            if inter > 60*60*24 {
                                doc.reference.delete()
                            }
                        }
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //If content is touched, open its description views
        let position = touches.first!.location(in: arScene)
        guard let first = arScene.hitTest(position, options: nil).first else {return}
        let node = first.node
        guard let document = nodesDictionary[node] else {return}
        
        let descriptionVC = DescriptionViewController()
        descriptionVC.doc = document
        
        let navVC = UINavigationController(rootViewController: descriptionVC)
        navVC.delegate = self
        present(navVC, animated: true, completion: nil)
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
            newData["Name"] = field.text!
            //Add doc id to user
            let newID = db.collection("items").addDocument(data: newData).documentID
            db.collection("users").whereField("uid", isEqualTo: currentUser.uid).getDocuments(completion: { (querySnap, err) in
                if let err = err {
                    print(err)
                } else {
                    if querySnap!.documents.count > 0 {
                        let ref = querySnap!.documents[0].reference
                        ref.collection("items").document(newID).setData(["name":field.text!])
                    }
                    self.loadNearItems()
                }
            })
        }
        alert.addAction(addAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func showIntro() {
//        let wData: [String:Any] = ["Media Type":"Photo", "uid": "VlgVcTvcUfW2PdGp17xS1O8z2vG2", "Name": "Glome", "Photo Name": "iTunesArtwork@1x.png", "coordinates": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)]
        db.collection("items").whereField("Photo Name", isEqualTo: "iTunesArtwork@1x.png").getDocuments { (querySnap, err) in
            if let err = err {
                print(err)
            } else {
                guard let querySnap = querySnap else {return}
                guard let doc = querySnap.documents.first else {return}
                var data = doc.data()
                data["coordinates"] = GeoPoint(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
                let newNode = self.createNewNode(data: data)
                self.nodesDictionary[newNode] = doc
            }
        }
        defaults.set(false, forKey: "intro")
    }
    @objc func loadNearItems() {
        nodesDictionary = [SCNNode:DocumentSnapshot]()
        cleanItems()
        if defaults.bool(forKey: "intro") {
            showIntro()
        }
        
        guard let query = queryInRadius(miles: 1.0/32.0, "items", "coordinates") else {let _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(loadNearItems), userInfo: nil, repeats: false);return}
        query.getDocuments { (querySnap, err) in
            if let err = err {
                print(err)
            } else {
                //Is this returning from the function or the closure? Might want to make this an if let statement.
                guard let querySnap = querySnap else {return}
                guard let _ = querySnap.documents.first else {return}
                for doc in querySnap.documents {
                    let geoPoint = doc.data()["coordinates"] as! GeoPoint
                    let loc = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                    
//                    if location.distance(from: loc) < 100 {
                        let newNode = self.createNewNode(data: doc.data())
                        self.nodesDictionary[newNode] = doc
//                    }
                }
                self.resetTracking()
            }
        }
    }
    
    
    func createNewNode(data: [String:Any]?) -> SCNNode {
        //Creates a test cube and decides its position based on the user's location
        guard let data = data else {return SCNNode()}
        //Is it safe to just return empty SCNNodes()?
        guard let mediaType = data["Media Type"] as? String else {return SCNNode()}
        
        var item: SCNNode!
        
        switch mediaType {
        case "Text":
            let geo = SCNText(string: data["Text"] as? String, extrusionDepth: 0.25)
            if let font = data["Font"] as? String {
                geo.font = UIFont(name: font, size: 20)
            }
            //Ask for text's font
            
            let mat = SCNMaterial()
            if let colorArray = data["Color"] as? [Int] {
                mat.diffuse.contents = UIColor(r: colorArray[0], g: colorArray[1], b: colorArray[2])
            } else {
                mat.diffuse.contents = UIColor.black
            }
            mat.isDoubleSided = true
            geo.firstMaterial = mat
            item = SCNNode(geometry: geo)
            item.scale = SCNVector3(x: 0.2, y: 0.2, z: 0.2)
        case "Gif":
            let gifImage = UIImage.gif(url: data["Gif URL"] as! String)
            let gifImageView = UIImageView(image: gifImage)
            let gifPlane = SCNPlane(width: 1.0, height: 1.0)
            let material = SCNMaterial()
            material.diffuse.contents = gifImageView.layer
            material.isDoubleSided = true
            gifPlane.firstMaterial = material
            item = SCNNode(geometry: gifPlane)
            
        case "Photo":
            let geo = SCNPlane(width: 1.0, height: 1.0)
            let mat = SCNMaterial()
            mat.diffuse.contents = vibrantPurple
            mat.isDoubleSided = true
            geo.firstMaterial = mat
            item = SCNNode(geometry: geo)
            //Load photo from Firebase/Storage
            storage.reference().child(data["Photo Name"] as! String).getData(maxSize: 10240*10240) { (imageData, err) in
                if let err = err {
                    print(err)
                } else {
                    guard let newImage = UIImage(data: imageData!) else {return}
                    item.geometry!.materials.first!.diffuse.contents = newImage
                }
            }
        case "Shape":
            let geo = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            let mat1 = SCNMaterial()
            if let colorArray = data["Color"] as? [Int] {
                mat1.diffuse.contents = UIColor(r: colorArray[0], g: colorArray[1], b: colorArray[2])
            } else {
                mat1.diffuse.contents = vibrantPurple
            }
            geo.firstMaterial = mat1
            item = SCNNode(geometry: geo)
        default:
            let geo = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
            let mat1 = SCNMaterial()
            mat1.diffuse.contents = vibrantPurple
            geo.firstMaterial = mat1
            item = SCNNode(geometry: geo)
        }
        
        
        guard let coordinates = data["coordinates"] as? GeoPoint else {return SCNNode()}
        let position = decidePosition(fromCoordinates: CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude))
        item.position = position!
        if mediaType == "Text" {
            item.position.y -= 0.5
        }
        
        return item
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
        //For previewing new content
        //Adds item directly in front of the camera, no matter how it moves or rotates
    }
    @objc func loadItemNonGeo() {
        //For viewing remotely from bio, etc...
        //Adds item in front of camera, not based on geography, but it stays in that spot when phone moves (normal AR mode)
    }
    //MARK: Recording
}

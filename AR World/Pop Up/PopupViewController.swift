//
//  PopupViewController.swift
//  AR World
//
//  Created by Nate Sesti on 10/20/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import EFColorPicker
import UIFontComplete

class PopupViewController: AuthHandlerViewController, UIPickerViewDelegate, UIPickerViewDataSource, EFColorSelectionViewControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, UITextFieldDelegate {
    
    //MARK: EFColorSelectionViewControllerDelegate
    func colorViewController(_ colorViewCntroller: EFColorSelectionViewController, didChangeColor color: UIColor) {
        
    }
    
    //MARK: UIPickerViewDelegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if self.popUpType == PopUpType.colorPicker {
            return 1
        } else {
            return 2
        }
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "Test"
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.frame.origin.y += 1000
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        view.frame.origin.y -= 1000
    }
    
    
    
    var popUpType: PopUpType!
    var parentVC: ViewController!
    
    func load() {
        self.view.layer.zPosition = 100
        popUpType.load(vc: self)
    }
    @objc func showWebsite() {
        //Go to zstudios website
        let webVC = WebViewController()
        webVC.url = "https://sites.google.com/view/zstudios/glome"
        present(webVC, animated: true, completion: nil)
    }
    @objc func hide() {
        self.parentVC.hidePopUpView()
    }
    @objc func agreeToEULA() {
        defaults.set(true, forKey: "eula")
        self.hide()
    }
    @objc func addText() {
        guard let oColor = colorButton!.layer.backgroundColor else {self.hide();return}
        guard let color = oColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: CGColorRenderingIntent.defaultIntent, options: nil) else {self.hide();return}
        guard let text = textField!.text, text != "" else {self.hide();return}
        self.parentVC.camVC.addTextParamColor = UIColor(cgColor: color)
        self.parentVC.camVC.addTextParamFont = fontButton!.titleLabel!.font.familyName
        self.parentVC.camVC.addTextParamText = text
        self.parentVC.camVC.addText()
        self.hide()
    }
    @objc func addShape() {
        guard let color = colorButton!.layer.backgroundColor else {return}
        self.parentVC.camVC.addTextParamColor = UIColor(cgColor: color)
        self.parentVC.camVC.addShape()
        self.hide()
    }
    var colorPicker: EFColorSelectionViewController?
    var colorButton: UIButton?
    var fontButton: UIButton?
    var fontPicker: FontTableViewController?
    var textField: UITextField?
    @objc func dismissColorPicker() {
        colorButton!.layer.backgroundColor = colorPicker!.color.cgColor
        colorPicker!.dismiss(animated: true, completion: nil)
    }
    @objc func dismissFontPicker() {
        fontButton!.titleLabel!.font = UIFont(name: fontPicker!.fontName, size: 25)
        fontPicker!.dismiss(animated: true, completion: nil)
    }
    @objc func showFontSelector() {
        let fontVC = FontTableViewController()
        self.fontPicker = fontVC
        fontVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissFontPicker))
        fontVC.navigationItem.leftBarButtonItem!.isEnabled = false
        let navVC = UINavigationController(rootViewController: fontVC)
        navVC.delegate = self
        self.present(navVC, animated: true, completion: nil)
    }
    @objc func showColorPicker() {
        let colorSelectionController = EFColorSelectionViewController()
        self.colorPicker = colorSelectionController
        let navCtrl = UINavigationController(rootViewController: colorSelectionController)
        navCtrl.navigationBar.backgroundColor = .white
        navCtrl.navigationBar.isTranslucent = false
        navCtrl.modalPresentationStyle = UIModalPresentationStyle.popover
        navCtrl.popoverPresentationController?.delegate = self
        navCtrl.popoverPresentationController?.sourceView = view
        navCtrl.popoverPresentationController?.sourceRect = view.bounds
        navCtrl.preferredContentSize = colorSelectionController.view.systemLayoutSizeFitting(
            UILayoutFittingCompressedSize
        )
        
        colorSelectionController.delegate = self
        colorSelectionController.color = UIColor(cgColor: colorButton!.layer.backgroundColor!)
        
        if UIUserInterfaceSizeClass.compact == self.traitCollection.horizontalSizeClass {
            let doneBtn: UIBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("Done", comment: ""),
                style: UIBarButtonItemStyle.done,
                target: self,
                action: #selector(dismissColorPicker)
            )
            colorSelectionController.navigationItem.rightBarButtonItem = doneBtn
        }
        self.present(navCtrl, animated: true, completion: nil)
    }
}


enum PopUpType {
    case info, textProperties, colorPicker, message, eula
}
extension PopUpType {
    func load(vc: PopupViewController) {
        //Clear the view
        for subview in vc.view.subviews {
            subview.removeFromSuperview()
        }
        //Add the done button for all types
        let doneButton = UIButton(frame: CGRect(x: vc.view.frame.midX - 50, y: 10, width: 100, height: 20))
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.black, for: .normal)
        doneButton.layer.roundCorners()
        doneButton.layer.backgroundColor = UIColor.white.cgColor
        vc.view.addSubview(doneButton)
        switch self {
        case .info:
            doneButton.addTarget(vc, action: #selector(vc.hide), for: .touchUpInside)
            
            let otherApps = OtherAppsButton()
            otherApps.setUp(parentVC: vc)
            otherApps.layer.backgroundColor = UIColor.white.cgColor
            otherApps.layer.roundCorners()
            vc.view.addSubview(otherApps)
            otherApps.frame.origin = CGPoint(x: vc.view.frame.midX + 50 - otherApps.frame.width/2, y: 150-otherApps.frame.height/2)
            let info = UIButton()
            info.setTitleColor(.white, for:.normal)
            info.setTitle("Website", for: .normal)
            info.frame.size = CGSize(100)
            info.addTarget(vc, action: #selector(vc.showWebsite), for: .touchUpInside)
            vc.view.addSubview(info)
            info.frame.origin = CGPoint(x: vc.view.frame.midX - 50 - info.frame.width/2, y: 150-info.frame.height/2)
        
        case .colorPicker:
            doneButton.addTarget(vc, action: #selector(vc.addShape), for: .touchUpInside)
            let color = UIButton(frame: CGRect(x: vc.view.frame.midX - 50, y: vc.view.frame.midY/2, width: 100, height: 100))
            color.layer.roundCorners()
            vc.colorButton = color
            color.setTitle("Color", for: .normal)
            color.setTitleColor(.white, for: .normal)
            color.layer.borderColor = UIColor.white.cgColor
            color.layer.borderWidth = 5
            color.layer.backgroundColor = UIColor.black.cgColor
            color.addTarget(vc, action: #selector(vc.showColorPicker), for: .touchUpInside)
            vc.view.addSubview(color)
        case .textProperties:
            doneButton.addTarget(vc, action: #selector(vc.addText), for: .touchUpInside)
            
            let color = UIButton(frame: CGRect(x: vc.view.frame.midX - 100, y: vc.view.frame.midY/2 + 25, width: 100, height: 100))
            color.layer.roundCorners()
            vc.colorButton = color
            color.setTitle("Color", for: .normal)
            color.setTitleColor(.white, for: .normal)
            color.layer.borderColor = UIColor.white.cgColor
            color.layer.borderWidth = 5
            color.layer.backgroundColor = UIColor.black.cgColor
            color.addTarget(vc, action: #selector(vc.showColorPicker), for: .touchUpInside)
            vc.view.addSubview(color)
            
            let field = UITextField(frame: CGRect(x: vc.view.frame.midX - 100, y: vc.view.frame.midY/3, width: 200, height: 30))
            vc.textField = field
            field.layer.borderColor = UIColor.lightGray.cgColor
            field.layer.borderWidth = 1
            field.textAlignment = .center
            field.backgroundColor = .white
            field.layer.cornerRadius = 5
            field.layer.masksToBounds = true
            field.returnKeyType = .done
            field.delegate = vc
            field.placeholder = "Type Words To Display"
            vc.view.addSubview(field)
            
            //Font Styles
            let fontButton = UIButton(frame: CGRect(x: vc.view.frame.midX + 20, y: vc.view.frame.midY/2 + 50, width: 100, height: 50))
            vc.fontButton = fontButton
            fontButton.layer.roundCorners()
            fontButton.layer.backgroundColor = UIColor.black.cgColor
            fontButton.layer.borderColor = UIColor.white.cgColor
            fontButton.layer.borderWidth = 5
            fontButton.setTitle("Font", for: .normal)
            fontButton.setTitleColor(.white, for: .normal)
            fontButton.addTarget(vc, action: #selector(vc.showFontSelector), for: .touchUpInside)
            vc.view.addSubview(fontButton)
            
        case .eula:
            doneButton.setTitle("Disagree", for: .normal)
            doneButton.setTitleColor(.red, for: .normal)
            doneButton.frame.origin.x += 70
            let agreeButton = UIButton(frame: CGRect(x: vc.view.frame.midX - 120, y: -15, width: 100, height: 100))
            agreeButton.setTitle("Agree", for:  .normal)
            agreeButton.setTitleColor(.white, for: .normal)
            agreeButton.addTarget(vc, action: #selector(vc.agreeToEULA), for: .touchUpInside)
            vc.view.addSubview(agreeButton)
            
            let textView = UITextView(frame: CGRect(width: 300, height: 150, centerOn: vc.view.frame.mid() +| -30.0))
            textView.text = """
Terms of Use (EULA)

Thanks for joining Glome!

In order to maintain a high quality, safe, and friendly environment, it is important that all users adhere to the guidelines that we have put in place. Under no circumstances will offenders of these guidelines be tolerated. Once ejected from Glome, there is no second chance. Inappropriate content may be automatically blocked or flagged by users. Both indicators will lead to review by our Community Safety Committee, which will swiftly remove any inappropriate content, as well as the user responsible for the posting of said content. Inappropriate content includes, but is not limited to profanity, bullying, nudity, stolen content, promotion of illegal activities, hate speech, and graphical images. Ultimately, the discretion is in the hands of our Committee, which will make decisions with the community’s best interest in mind. All content should be fitting for a diverse community of many ages, beliefs, and cultures.
"""
            vc.view.addSubview(textView)
            
        default:
            print("default")
        }
    }
}

//
//  DrawingViewController.swift
//  AR World
//
//  Created by Nate Sesti on 11/30/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import EFColorPicker

class DrawingViewController: UIViewController, UINavigationControllerDelegate, EFColorSelectionViewControllerDelegate {
    func colorViewController(_ colorViewCntroller: EFColorSelectionViewController, didChangeColor color: UIColor) {
        drawingView.drawColor = color
        colorButton.layer.backgroundColor = color.cgColor
    }
    
    private var sizeSlider: UISlider!
    public var drawingView: DrawingView!
    private var colorButton: UIButton!
    private var eraserButton: UIButton!
    override func viewDidLoad() {
        drawingView = DrawingView(frame: view.frame)
        view.addSubview(drawingView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: drawingView, action: #selector(drawingView.clear))
        
        colorButton = UIButton(frame: CGRect(x: view.frame.maxX - 60, y: view.frame.maxY - 60, width: 50, height: 50))
        colorButton.layer.backgroundColor = drawingView.drawColor.cgColor
        colorButton.layer.roundCorners()
        colorButton.layer.borderColor = UIColor.black.cgColor
        colorButton.layer.borderWidth = 3
        colorButton.addTarget(self, action: #selector(showColorPicker), for: .touchUpInside)
        view.addSubview(colorButton)
        
        eraserButton = UIButton(frame: CGRect(x: view.frame.minX + 10, y: view.frame.maxY - 60, width: 50, height: 50))
        eraserButton.layer.backgroundColor = UIColor.white.cgColor
        eraserButton.setTitle("erase", for: .normal)
        eraserButton.layer.roundCorners()
        eraserButton.layer.borderColor = UIColor.black.cgColor
        eraserButton.layer.borderWidth = 3
        eraserButton.addTarget(self, action: #selector(setEraser), for: .touchUpInside)
//        view.addSubview(eraserButton)
        
        sizeSlider = UISlider(frame: CGRect(x: view.frame.midX - 75, y: view.frame.maxY - 100, width: 150, height: 50))
        sizeSlider.minimumValue = 1
        sizeSlider.maximumValue = 100
        sizeSlider.addTarget(self, action: #selector(sizeChanged), for: .valueChanged)
        view.addSubview(sizeSlider)
    }
    private var usingEraser = false
    @objc private func setEraser() {
        if usingEraser {
            eraserButton.layer.backgroundColor = UIColor.white.cgColor
            drawingView.drawColor = UIColor(cgColor: colorButton.layer.backgroundColor!)
        } else {
            eraserButton.layer.backgroundColor = UIColor.lightGray.cgColor
            drawingView.drawColor = .white
        }
        usingEraser = !usingEraser
    }
    @objc private func sizeChanged() {
        drawingView.lineWidth = CGFloat(sizeSlider.value)
    }
    @objc public func getImage() -> UIImage? {
        return drawingView.getImage()
    }
    @objc private func showColorPicker() {
        let colorPicker = EFColorSelectionViewController()
        colorPicker.delegate = self
        let navVC = UINavigationController(rootViewController: colorPicker)
        navVC.delegate = self
        colorPicker.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: colorPicker, action: #selector(done))
        present(navVC, animated: true, completion: nil)
    }
}

//
//  WebViewController.swift
//  KNO Test
//
//  Created by Nate Sesti on 8/24/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIGestureRecognizerDelegate {
    var webView: UIWebView!
    var url: String!
    private let action = #selector(exit)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = UIWebView(frame: view.frame)
        view.addSubview(webView)
        let request = URLRequest(url: URL(string: url)!)
        webView.loadRequest(request)
        
        var num: CGFloat = 22.0
        if X() {
            num += 22.0
        }
        
        let effect = UIBlurEffect(style: .dark)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.frame = CGRect(x: view.frame.minX + 5, y: view.frame.minY + num, width: 30, height: 30)
        effectView.layer.masksToBounds = true
        effectView.layer.cornerRadius = effectView.frame.height/2.0
        effectView.alpha = 0.7
        view.addSubview(effectView)
        
        let exitButton = UIButton(frame: CGRect(x: 0, y: 0, width: effectView.frame.width, height: effectView.frame.height))
        exitButton.setTitle("X", for: .normal)
        exitButton.setTitleColor(.white, for: .normal)
        exitButton.backgroundColor = .clear
        exitButton.addTarget(self, action: action, for: .touchUpInside)
        effectView.contentView.addSubview(exitButton)
        
        let directions: [UISwipeGestureRecognizerDirection] = [.left]
        for dir in directions {
            let recognizer = UISwipeGestureRecognizer(target: self, action: action)
            recognizer.direction = dir
            view.addGestureRecognizer(recognizer)
        }
    }
    @objc func exit() {
        dismiss(animated: true, completion: nil)
    }
}

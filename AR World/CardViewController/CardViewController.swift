//
//  CardViewController.swift
//  AR World
//
//  Created by Nate Sesti on 6/20/19.
//  Copyright © 2019 Nate Sesti. All rights reserved.
//

import UIKit

protocol CardViewControllerDelegate: UIViewController {}

class CardViewController: UIViewController {
    @IBAction func pan(_ sender: UIPanGestureRecognizer) {
        handleCardPan(sender)
    }
    
    static let handleSize: CGSize = CGSize(width: 40, height: 5)
    
    public var delegate: CardViewControllerDelegate!
    
    // Enum for card states
    enum CardState {
        case collapsed
        case expanded
    }
    
    // Variable determines the next state of the card expressing that the card starts and collapased
    var nextState:CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    // Starting and end card heights will be determined later
    var endCardHeight:CGFloat = 0
    var startCardHeight:CGFloat = 0
    
    // Current visible state of the card
    var cardVisible = false
    
    // Empty property animator array
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted:CGFloat = 0
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        let temp = view.layer.position
        view.layer.position.y = screen.height + endCardHeight
        view.layer.animate(#keyPath(CALayer.position), from: temp, duration: 0.4, autoreverses: false, timingFunction: .easeOut) {
            self.view.removeFromSuperview()
            self.removeFromParent()
            super.dismiss(animated: flag, completion: completion)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupCard()
    }
    @objc func handleCardTap(_ sender: UITapGestureRecognizer) {
        guard sender.location(in: self.view).x < 20 else {return}
        switch sender.state {
        // Animate card when tap finishes
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    
    @objc func handleCardPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            // Start animation if pan begins
            startInteractiveTransition(state: nextState, duration: 0.9)
            
        case .changed:
            // Update the translation according to the percentage completed
            let translation = sender.translation(in: self.vibrancy)
            var fractionComplete = translation.y / (endCardHeight - startCardHeight)
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
            
            if !cardVisible && translation.y > 40.0 {
                for animation in runningAnimations {
                    animation.stopAnimation(true)
                }
                dismiss(animated: true, completion: nil)
            }
        case .ended:
            // End animation when pan ends
            let translation = sender.translation(in: self.vibrancy)
            var fractionComplete = translation.y / (endCardHeight - startCardHeight)
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            if fractionComplete >= 0.5 {
                continueInteractiveTransition()
            } else {
                //Should reverse
                continueInteractiveTransition()
            }
        default:
            break
        }
    }
    
    func setupCard() {
        assert(delegate != nil, "CardViewControllerDelegate not set before view was loaded.")
        
        //Remove any other cards on the delegate
        for child in delegate.children {
            if child is CardViewController && !child.isEqual(self) {
                child.removeFromParent()
                child.view.removeFromSuperview()
            }
        }
        
        // Setup starting and ending card height
        endCardHeight = delegate.view.frame.height * 0.95
        startCardHeight = delegate.view.frame.height * 0.35
        
        // Clip bounds so that the corners can be rounded
        delegate.view.addSubview(view)
        view.frame = CGRect(x: 0, y: delegate.view.frame.height - startCardHeight, width: screen.width, height: endCardHeight)
        view.clipsToBounds = true
        view.roundCorners(.allCorners, radius: 30)
        view.layer.zPosition = 100
        
        
        handle = UIView(frame: CGRect(x: screen.width/2.0 - CardViewController.handleSize.width/2.0, y: 10.0, width: CardViewController.handleSize.width, height: CardViewController.handleSize.height))
        handle.backgroundColor = .lightGray
        handle.layer.zPosition = 101
        handle.roundCorners(.allCorners, radius: handle.frame.height/2.0)
        view.addSubview(handle)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleCardTap(_:))))
    }
    
    
    // Animate transistion function
    func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {
        // Check if frame animator is empty
        if runningAnimations.isEmpty {
            // Create a UIViewPropertyAnimator depending on the state of the popover view
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    // If expanding set popover y to the ending height and blur background
                    self.view.frame.origin.y = self.delegate.view.frame.height - self.endCardHeight
                    
                case .collapsed:
                    // If collapsed set popover y to the starting height and remove background blur
                    self.view.frame.origin.y = self.delegate.view.frame.height - self.startCardHeight
                }
            }
            
            // Complete animation frame
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            // Start animation
            frameAnimator.startAnimation()
            
            // Append animation to running animations
            runningAnimations.append(frameAnimator)
            
            // Create UIViewPropertyAnimator to round the popover view corners depending on the state of the popover
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    // If the view is expanded set the corner radius to 30
                    self.view.layer.cornerRadius = 10
                    
                case .collapsed:
                    // If the view is collapsed set the corner radius to 0
                    self.view.layer.cornerRadius = 30
                }
            }
            
            // Start the corner radius animation
            cornerRadiusAnimator.startAnimation()
            
            // Append animation to running animations
            runningAnimations.append(cornerRadiusAnimator)
            
        }
    }
    
    // Function to start interactive animations when view is dragged
    func startInteractiveTransition(state:CardState, duration:TimeInterval) {
        
        // If animation is empty start new animation
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        
        // For each animation in runningAnimations
        for animator in runningAnimations {
            // Pause animation and update the progress to the fraction complete percentage
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    // Funtion to update transition when view is dragged
    func updateInteractiveTransition(fractionCompleted:CGFloat) {
        // For each animation in runningAnimations
        for animator in runningAnimations {
            // Update the fraction complete value to the current progress
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    // Function to continue an interactive transisiton
    func continueInteractiveTransition (){
        // For each animation in runningAnimations
        for animator in runningAnimations {
            // Continue the animation forwards or backwards
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    func reverseInteractiveTransition() {
        for animator in runningAnimations {
            animator.isReversed = true
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    var vibrancy: UIVisualEffectView!
    var handle: UIView!
}

//
//  DraggablePresentationController.swift
//  CardVC
//
//  Created by Salman Fakhri on 8/6/18.
//  Copyright © 2018 Salman Fakhri. All rights reserved.
//

import UIKit

enum DragDirection {
    case up
    case down
}

enum DraggablePosition {
    case collapsed
    case open
    case middle
    
    var heightmultiplier: CGFloat {
        switch self {
        case .collapsed:
            return 0.1
        case .middle:
            return 0.48
        case .open:
            return 0.9
        }
    }
    
    var downBoundary: CGFloat {
        switch self {
        case .collapsed: return 0.0
        case .middle: return 0.35
        case .open: return 0.8
        }
    }
    
    var upBoundary: CGFloat {
        switch self {
        case .collapsed: return 0.0
        case .middle: return 0.27
        case .open: return 0.65
        }
    }
    
    var dimAlpha: CGFloat {
        switch self {
        case .collapsed, .middle: return 0.0
        case .open: return 0.45
        }
    }
    
    func yOrigin(for maxHeight: CGFloat) -> CGFloat {
        return maxHeight - (maxHeight*heightmultiplier)
    }
    
    func nextPostion(for dragDirection: DragDirection) -> DraggablePosition {
        switch (self, dragDirection) {
        case (.collapsed, .up): return .middle
        case (.collapsed, .down): return .collapsed
        case (.middle, .up): return .open
        case (.middle, .down): return .collapsed
        case (.open, .up): return .open
        case (.open, .down): return .middle
        }
    }
}

class DraggablePresentationController: UIPresentationController {
    
    
    private lazy var touchForwardingView: TouchForwardingView? = {
        guard let containerView = containerView else { return nil }
        return TouchForwardingView(frame: containerView.bounds)
    }()
    
    private var dimmingView = UIView()
    
    private var position: DraggablePosition = .middle
    private var dragDirection: DragDirection = .up
    private var maxFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    
    private var animator: UIViewPropertyAnimator?
    private let springTiming = UISpringTimingParameters(dampingRatio: 0.7, initialVelocity: CGVector(dx: 0, dy: 10))
    private var panGesture = UIGestureRecognizer()
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let origin = CGPoint(x: 0, y: position.yOrigin(for: maxFrame.height))
        let size = CGSize(width: maxFrame.width, height: maxFrame.height + 40)
        let frame = CGRect(origin: origin, size: size)
        return frame
    }
    
    override func presentationTransitionWillBegin() {
        //insert dimming view
        guard let containerView = containerView else { return }
        
        touchForwardingView!.passthroughViews = [presentingViewController.view]
        containerView.insertSubview(touchForwardingView!, at: 0)
        
        containerView.insertSubview(dimmingView, at: 1)
        dimmingView.alpha = 0
        dimmingView.backgroundColor = .black
        dimmingView.frame = containerView.frame
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        //set up touch gestures
        animator = UIViewPropertyAnimator(duration: 0.6, timingParameters: springTiming)
        animator?.isInterruptible = false
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(userDidPan(panRecognizer:)))
        presentedView?.addGestureRecognizer(panGesture)
        
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    @objc private func userDidPan(panRecognizer: UIPanGestureRecognizer) {
        let translationPoint = panRecognizer.translation(in: presentedView)
        let velocity = panRecognizer.velocity(in: presentedView)
        let currentOriginY = position.yOrigin(for: maxFrame.height)
        let newOffset = currentOriginY + translationPoint.y
        
        dragDirection = newOffset > currentOriginY ? .down : .up
        
        let canDragInProposedDirection = dragDirection == .up && position == .open ? false : true
        
        if canDragInProposedDirection {
            presentedView?.frame.origin.y = newOffset
            let nextOriginY = position.nextPostion(for: dragDirection).yOrigin(for: maxFrame.height)
            let area = dragDirection == .up ? frameOfPresentedViewInContainerView.origin.y - maxFrame.origin.y : -(frameOfPresentedViewInContainerView.origin.y - nextOriginY)
            if newOffset != area && position == .open || position.nextPostion(for: dragDirection) == .open {
                let onePercent = area / 100
                let percentage = (area-newOffset) / onePercent / 100
                dimmingView.alpha = percentage * DraggablePosition.open.dimAlpha
            }
        }
        
        if panRecognizer.state == .ended {
            if velocity.y < -1000 {
                animate(to: position.nextPostion(for: .up))
            } else if velocity.y > 1000 {
                animate(to: position.nextPostion(for: .down))
            } else {
                animate(newOffset)
            }
        }
    }

    private func animate(_ dragOffset: CGFloat) {
        
        let distanceFromBottom = maxFrame.height - dragOffset
        
        switch dragDirection {
        case .up:
            if (distanceFromBottom > maxFrame.height * DraggablePosition.open.upBoundary) {
                animate(to: .open)
                position = .open
            } else if (distanceFromBottom > maxFrame.height * DraggablePosition.middle.upBoundary ) {
                animate(to: .middle)
                position = .middle
            } else {
                animate(to: .collapsed)
                position = .collapsed
            }
            
        case .down:
            if (distanceFromBottom > maxFrame.height * DraggablePosition.open.downBoundary) {
                animate(to: .open)
                position = .open
            } else if (distanceFromBottom > maxFrame.height * DraggablePosition.middle.downBoundary ) {
                animate(to: .middle)
                position = .middle
            } else {
                animate(to: .collapsed)
                position = .collapsed
            }
        }
    }
    
    private func animate(to position: DraggablePosition) {
        
        guard let animator = animator else { return }
        
        animator.addAnimations {
            self.presentedView?.frame.origin.y = position.yOrigin(for: self.maxFrame.height)
            self.dimmingView.alpha = position.dimAlpha
        }
        
        
        self.position = position
        
        
        
        animator.startAnimation()
    }
}
    
    
    
    


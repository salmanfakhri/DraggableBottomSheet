//
//  TouchForwardingView.swift
//  CardVC
//
//  Created by Salman Fakhri on 8/7/18.
//  Copyright © 2018 Salman Fakhri. All rights reserved.
//

import Foundation
import UIKit

final class TouchForwardingView: UIView {
    
    final var passthroughViews: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        guard hitView == self else { return hitView }
        
        for passthroughView in passthroughViews {
            let point = convert(point, to: passthroughView)
            if let passthroughHitView = passthroughView.hitTest(point, with: event) {
                return passthroughHitView
            }
        }
        
        return self
    }
}

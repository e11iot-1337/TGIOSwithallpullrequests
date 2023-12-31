import Foundation
import UIKit
import AsyncDisplayKit
import Display

private class LegacyTracingLayerView: UITracingLayerView {
    var isSparse = false
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if result === self && self.isSparse {
            return nil
        }
        return result
    }
}

final class LegacyControllerNode: ASDisplayNode {
    private var containerLayout: ContainerViewLayout?
    
    var controllerView: UIView? {
        didSet {
            if let controllerView = self.controllerView, let layout = self.containerLayout {
                let size = CGSize(width: layout.size.width - layout.intrinsicInsets.left - layout.intrinsicInsets.right, height: layout.size.height)
                controllerView.frame = CGRect(origin: CGPoint(x: layout.intrinsicInsets.left, y: 0.0), size: size)
            }
        }
    }
    
    public var hasSparseContainerView = false {
        didSet {
            if self.isNodeLoaded {
                (self.view as? LegacyTracingLayerView)?.isSparse = self.hasSparseContainerView
            }
        }
    }
    
    override init() {
        super.init()
        
        self.setViewBlock({
            return LegacyTracingLayerView()
        })
        
//        self.clipsToBounds = true
    }
    
    override func didLoad() {
        super.didLoad()
        
        (self.view as? LegacyTracingLayerView)?.isSparse = self.hasSparseContainerView
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        self.containerLayout = layout
        let size = CGSize(width: layout.size.width - layout.intrinsicInsets.left - layout.intrinsicInsets.right, height: layout.size.height)
        if let controllerView = self.controllerView {
            controllerView.frame = CGRect(origin: CGPoint(x: layout.intrinsicInsets.left, y: 0.0), size: size)
        }
    }
    
    func animateModalIn(completion: @escaping () -> Void) {
        self.layer.animatePosition(from: CGPoint(x: 0.0, y: self.layer.bounds.size.height), to: CGPoint(), duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring, additive: true, completion: { _ in
            completion()
        })
    }
    
    func animateModalOut(completion: @escaping () -> Void) {
        self.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: self.layer.bounds.size.height), duration: 0.2, timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, removeOnCompletion: false, additive: true, completion: { _ in
            completion()
        })
    }
}

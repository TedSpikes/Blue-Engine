//
//  ViewController.swift
//  Demo Engine v2
//
//  Created by Ted Kostylev on 1/28/22.
//

import Cocoa

class ViewController: NSViewController {
    var renderer: Renderer!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        view = MainView(frame: NSRect(origin: CGPoint.zero, size: CGSize(width: 1920.0, height: 1080.0)))
        renderer = Renderer(targeting: view.layer as! CAMetalLayer)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        renderer.camera.aspect = Float(view.bounds.width/view.bounds.height)
        
        let pan = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        view.addGestureRecognizer(pan)
        
        NotificationCenter.default.addObserver(self, selector: #selector(respondToViewSizeChange(_:)), name: NSView.frameDidChangeNotification, object: view)
    }
    
    @objc func respondToViewSizeChange(_ notification: Notification) {
//        renderer.camera.aspect = Float(view.bounds.width/view.bounds.height)
    }
    
    @objc func handlePan(gesture: NSPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let delta = SIMD2<Float>(Float(translation.x), Float(translation.y))
//        renderer.camera.rotate(delta: delta)
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    override func scrollWheel(with event: NSEvent) {
//        renderer.camera.zoom(delta: Float(event.deltaY))
    }
}

class MainView: NSView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.postsFrameChangedNotifications = true
    }
    
    override func makeBackingLayer() -> CALayer {
        let metalLayer = CAMetalLayer()
        metalLayer.frame = frame
        metalLayer.backgroundColor = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        return metalLayer
    }
}

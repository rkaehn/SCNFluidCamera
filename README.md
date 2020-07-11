# SCNFluidCamera

[![swift version](https://img.shields.io/badge/swift-5.2+-brightgreen.svg)](https://swift.org/download)
[![platforms](https://img.shields.io/badge/platforms-%20iOS%20-brightgreen.svg)](#)

SCNFluidCamera provides a smooth, multi-touch enabled camera controller for SceneKit. 
It works on iOS and macOS using Mac Catalyst and can be easily customized for your use case.

### 💻 Installing

Just add the SCNFluidCamera.swift file to your project and set it up in the view controller of your SCNView like this:

```swift
class SceneViewController: UIViewController {
    private(set) lazy var sceneView = SCNView(frame: view.frame)
    
    private let camera = SCNFluidCamera()
    
    override func viewDidLoad() {
        self.view = sceneView
        
        // Set self as the SCNSceneRendererDelegate of the SCNView to be notified about
        // the state of the render cycle
        sceneView.delegate = self
        
        // Prevent SceneKit from interrupting the smooth movements
        sceneView.isPlaying = true
        
        setupCamera()
    }
    
    private func setupCamera() {
        sceneView.scene?.rootNode.addChildNode(camera.orbitNode)
        
        // To allow SCNFluidCamera to add gesture recognizers to the view
        camera.attachView(sceneView)
        
        // Set self as the UIGestureRecognizerDelegate of the UIGestureRecognizers to enable
        // simultaneous gestures, allowing you to smoothly transition from zooming to panning etc.
        camera.panGesture.delegate = self
        camera.pinchGesture.delegate = self
    }
}

extension SceneViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        camera.updateTransform(updateAtTime: time)
    }
}

extension SceneViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
```

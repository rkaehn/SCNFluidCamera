//
//  SCNFluidCamera.swift
//  supergraph
//
//  Created by Raffael Kaehn on 23.06.20.
//  Copyright © 2020 Raffael Kaehn. All rights reserved.
//

// The smooth motion is created with the following steps:
// 1. Apply the target transformations to targetOrbitNode and targetCameraNode. (Done in gesture actions)
// 2. With each render cycle, calculate the delta between the current transformations and the target transformations.
//    Use the frame time to slowly bring the current and target transformations together.
//
// The constants in this class are being used to control the sensitivity of the gestures.

import SceneKit

class SCNFluidCamera {
    private(set) lazy var panGesture = FastUIPanGestureRecognizer(target: self, action: #selector(handlePan))
    private(set) lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
    private(set) lazy var doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
    
    public let orbitNode = SCNNode()
    public let cameraNode = SCNNode()
    public let camera = SCNCamera()
    
    // These are just "dummy nodes". They are not added to the scene graph and are only used as
    // containers for the target / reset transformations of the nodes they are named after.
    private let targetOrbitNode = SCNNode()
    private let targetCameraNode = SCNNode()
    
    private let resetOrbitNode = SCNNode()
    private let resetCameraNode = SCNNode()
    
    private var sceneView: SCNView?
    
    public var allowsOrbit = true
    public var allowsPan = true
    public var allowsZoom = true
    public var allowsReset = false
    
    // MARK: Setup
    
    init() {
        cameraNode.camera = camera
        cameraNode.simdPosition.z = 10
        orbitNode.addChildNode(cameraNode)
        orbitNode.simdEulerAngles = simd_float3(-Float.pi / 4, -Float.pi / 4, 0)
        
        targetOrbitNode.simdTransform = orbitNode.simdTransform
        targetCameraNode.simdTransform = cameraNode.simdTransform
        
        resetOrbitNode.simdTransform = orbitNode.simdTransform
        resetCameraNode.simdTransform = cameraNode.simdTransform
        
        setupCamera()
    }
    
    private func setupCamera() {
        camera.zNear = 0.01
        camera.zFar = 100.0
    }
    
    public func attachView(_ view: SCNView) {
        sceneView = view
        setupGestures()
    }
    
    private func setupGestures() {
        panGesture.maximumNumberOfTouches = 2
        panGesture.allowedScrollTypesMask = .all
        doubleTapGesture.numberOfTapsRequired = 2
        
        sceneView?.addGestureRecognizer(panGesture)
        sceneView?.addGestureRecognizer(pinchGesture)
        sceneView?.addGestureRecognizer(doubleTapGesture)
    }
    
    // MARK: Pan gesture
    
    // Transformation at the beginning of the gesture
    private var startRotation: simd_float3?
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        switch sender.numberOfTouches {
        case 1:
            if startRotation == nil {
                startRotation = targetOrbitNode.simdEulerAngles
                sender.setTranslation(CGPoint.zero, in: sceneView)
            }
            
            let translation = sender.translation(in: sceneView)

            targetOrbitNode.simdEulerAngles = startRotation! - simd_float3(Float(translation.y / 400),
                                                                           Float(translation.x / 400),
                                                                           0)
        case 2, 0:
            if startRotation != nil {
                startRotation = nil
                sender.setTranslation(CGPoint.zero, in: sceneView)
            }

            let translation = sender.translation(in: sceneView)
            let scale = cameraNode.simdPosition.z
            
            targetOrbitNode.simdLocalTranslate(by: simd_float3(Float(-translation.x) * scale / 600,
                                                               Float(translation.y) * scale / 600,
                                                               0))
            
            sender.setTranslation(CGPoint.zero, in: sceneView)
        default:
            return
        }
    }
    
    // MARK: Scale gesture
    
    // Transformation at the beginning of the gesture
    private var startScale = Float.zero
    
    @objc private func handlePinch(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .began:
            startScale = cameraNode.simdPosition.z
        case .changed:
            targetCameraNode.simdPosition.z = startScale / Float(sender.scale)
        default:
            return
        }
    }
    
    // MARK: Double tap gesture
    
    @objc private func handleDoubleTap() {
        guard allowsReset else { return }
        
        targetOrbitNode.simdTransform = resetOrbitNode.simdTransform
        targetCameraNode.simdTransform = resetCameraNode.simdTransform
    }
    
    // MARK: Update transformations
    
    private var lastTime = TimeInterval.zero
    
    public func updateTransform(updateAtTime time: TimeInterval) {
        let deltaTime = Float(time - lastTime)
        lastTime = time
        
        if allowsOrbit {
            let deltaAnglesOverall = (targetOrbitNode.simdEulerAngles - orbitNode.simdEulerAngles)
            let deltaAnglesFrame = deltaAnglesOverall * min(deltaTime * 10, 1)
            orbitNode.simdEulerAngles += deltaAnglesFrame
        }
        
        if allowsPan {
            let deltaPositionOverall = (targetOrbitNode.simdPosition - orbitNode.simdPosition)
            let deltaPositionFrame = deltaPositionOverall * min(deltaTime * 10, 1)
            orbitNode.simdPosition += deltaPositionFrame
        }
        
        if allowsZoom {
            let deltaScaleOverall = (targetCameraNode.simdPosition.z - cameraNode.simdPosition.z)
            let deltaScaleFrame = deltaScaleOverall * min(deltaTime * 10, 1)
            cameraNode.simdPosition.z += deltaScaleFrame
        }
    }
    
    // MARK: Manual settings
    
    public func setPivot(_ position: simd_float3) {
        targetOrbitNode.simdPosition = position
    }
    
    public func setScale(_ scale: Float) {
        targetCameraNode.simdPosition.z = scale
    }
    
    public func setOrbitPosition(_ orbitPosition: simd_float3) {
        targetOrbitNode.simdEulerAngles = orbitPosition
    }
}

// Customized UIPanGestureRecognizer that starts the gesture immediately after a finger has touched the screen
public class FastUIPanGestureRecognizer: UIPanGestureRecognizer {
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        state = .began
    }
}

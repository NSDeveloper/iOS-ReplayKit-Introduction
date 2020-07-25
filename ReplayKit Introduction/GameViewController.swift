//
//  GameViewController.swift
//  ReplayKit Introduction
//
//  Created by Davis Allie on 6/12/2015.
//  Copyright (c) 2015 tutsplus. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import ReplayKit

class GameViewController: UIViewController {
    
    var particleSystem: SCNParticleSystem!
    var buttonWindow: UIWindow!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene()
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLight.LightType.omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        self.particleSystem = SCNParticleSystem(named: "Fire", inDirectory: nil)!
        self.particleSystem.birthRate = 0
        let node = SCNNode()
        node.addParticleSystem(self.particleSystem)
        scene.rootNode.addChildNode(node)
        
        let scnView = self.view as! SCNView
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.backgroundColor = UIColor.black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let recordingButton = UIButton(type: .system)
        recordingButton.setTitle("Start Recording", for: .normal)
        var recordingY: CGFloat = 0
        var fireY = self.view.frame.height - 78
        if #available(iOS 11.0, *) {
            recordingY = self.view.safeAreaInsets.top
            fireY -= self.view.safeAreaInsets.bottom
        }
        recordingButton.frame = CGRect(x: 0, y: recordingY, width: self.view.frame.width, height: 50)
        recordingButton.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        
        let fireButton = UIButton(type: .custom)
        fireButton.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        fireButton.backgroundColor = UIColor.green
        fireButton.clipsToBounds = true
        fireButton.layer.cornerRadius = 35.0
        fireButton.addTarget(self, action: #selector(fireButtonTouchedDown), for: .touchDown)
        fireButton.addTarget(self, action: #selector(fireButtonTouchedUp), for: .touchUpInside)
        fireButton.addTarget(self, action: #selector(fireButtonTouchedUp), for: .touchUpOutside)
        fireButton.frame.origin.y = fireY
        fireButton.center.x = self.view.center.x
        
        self.addButtons(buttons: [recordingButton, fireButton])
    }
    
    func addButtons(buttons: [UIButton]) {
        self.buttonWindow = UIWindow(frame: self.view.frame)
        self.buttonWindow.rootViewController = HiddenStatusBarViewController()
        for button in buttons {
            self.buttonWindow.rootViewController?.view.addSubview(button)
        }
        
        self.buttonWindow.makeKeyAndVisible()
    }
    
    @objc func startRecording(sender: UIButton) {
        if RPScreenRecorder.shared().isAvailable {
            RPScreenRecorder.shared().startRecording(withMicrophoneEnabled: true) { (error: Error?) -> Void in
                if error == nil { // Recording has started
                    DispatchQueue.main.async {
                        sender.removeTarget(self, action: #selector(self.startRecording), for: .touchUpInside)
                        sender.addTarget(self, action: #selector(self.stopRecording), for: .touchUpInside)
                        sender.setTitle("Stop Recording", for: .normal)
                        sender.setTitleColor(UIColor.red, for: .normal)
                    }

                } else {
                    // Handle error
                    print(error!)
                }
            }
        } else {
            // Hide UI used for recording
        }
    }
    
    @objc func stopRecording(sender: UIButton) {
        RPScreenRecorder.shared().stopRecording { (previewController: RPPreviewViewController?, error: Error?) -> Void in
            if previewController != nil {
                DispatchQueue.main.async {
                    
                    let alertController = UIAlertController(title: "Recording", message: "Do you wish to discard or view your gameplay recording?", preferredStyle: .alert)
                    
                    let discardAction = UIAlertAction(title: "Discard", style: .default) { (action: UIAlertAction) in
                        RPScreenRecorder.shared().discardRecording(handler: { () -> Void in
                            // Executed once recording has successfully been discarded
                        })
                    }
                    
                    let viewAction = UIAlertAction(title: "View", style: .default, handler: { (action: UIAlertAction) -> Void in
                        previewController?.previewControllerDelegate = self
                        previewController?.modalPresentationStyle = .fullScreen
                        self.buttonWindow.rootViewController?.present(previewController!, animated: true, completion: nil)
                    })
                    
                    alertController.addAction(discardAction)
                    alertController.addAction(viewAction)
                    
                    print(self.buttonWindow.rootViewController as Any)
                    self.buttonWindow.rootViewController?.present(alertController, animated: true, completion: nil)
                    
                    sender.removeTarget(self, action: #selector(self.stopRecording), for: .touchUpInside)
                    sender.addTarget(self, action: #selector(self.startRecording), for: .touchUpInside)
                    sender.setTitle("Start Recording", for: .normal)
                    sender.setTitleColor(UIColor.blue, for: .normal)
                }
            } else {
                // Handle error
                print(error as Any)
            }
        }
    }
    
    @objc func fireButtonTouchedDown(sender: UIButton) {
        self.particleSystem.birthRate = 455
    }
    
    @objc func fireButtonTouchedUp(sender: UIButton) {
        self.particleSystem.birthRate = 0
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}

extension GameViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.previewControllerDelegate = nil
        previewController.dismiss(animated: true, completion: nil)
    }
    
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        print(activityTypes)
    }
}

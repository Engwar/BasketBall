//
//  ViewController.swift
//  BasketBall
//
//  Created by Igor Shelginskiy on 21/10/2018.
//  Copyright © 2018 Igor Shelginskiy. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var hoopAdded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = true
        
        // Create a new scene
        let scene = SCNScene()
        
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else {return}
        
        node.addChildNode(createWall(anchor: anchor))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor,
            let node = node.childNodes.first,
            let plane = node.geometry as? SCNPlane else {return}
        
        plane.width = CGFloat(anchor.extent.x)
        plane.height = CGFloat(anchor.extent.z)
        
        node.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
    }
    
    func createWall(anchor: ARPlaneAnchor) -> SCNNode {
        let width = CGFloat(anchor.extent.x)
        let height = CGFloat(anchor.extent.z)
        let node = SCNNode(geometry: SCNPlane(width: width, height: height))
        node.name = "wall"
        node.eulerAngles.x = -.pi/2
        node.opacity = 0.25
        return node
    }
    
    func stopPlaneDetection() {
        let configuration = sceneView.session.configuration as! ARWorldTrackingConfiguration
        configuration.planeDetection = []
        sceneView.session.run(configuration)
       
    }
    
    func hidewalls() {
        stopPlaneDetection()
        hoopAdded = true
        sceneView.scene.rootNode.enumerateChildNodes { node,_ in
            if node.name == "wall" {
                node.removeFromParentNode()
            }
        }
    }
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    //добавляем в сцену кольцо со щитом для взаимодействия с мячом
    func addHoop(result: ARHitTestResult) {
        let scene = SCNScene(named: "art.scnassets/Hoop.scn")
        
        guard let node = scene?.rootNode.childNode(withName: "Hoop", recursively: true) else {return}
        
        // поворот объекта согласно определенной программой сцены (поверхности)
        node.simdTransform = result.worldTransform
        node.eulerAngles.x -= .pi/2
        
        //создаем физику щита
        node.physicsBody = SCNPhysicsBody(
            type: .static,
            shape: SCNPhysicsShape(node: node, options: [
                SCNPhysicsShape.Option.type:
                    SCNPhysicsShape.ShapeType.concavePolyhedron])) // проталкиваем мяч в кольцо
        
        sceneView.scene.rootNode.addChildNode(node)
        hidewalls()
    }
    
//создаем мяч
    func createBasketballs (){
        guard let frame = sceneView.session.currentFrame else {return}
        
        let node = SCNNode(geometry: SCNSphere(radius: 0.25))
        node.simdTransform = frame.camera.transform
        
// добавляем текстуру мяча
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "art.scnassets/limestonemarked2-albedo")
        material.ambientOcclusion.contents = UIImage(named: "art.scnassets/limestonemarked2-ao")
        material.metalness.contents = UIImage(named: "art.scnassets/limestonemarked2-metallic")
        material.normal.contents = UIImage(named: "art.scnassets/limestonemarked2-normal-dx")
        material.roughness.contents = UIImage(named: "art.scnassets/limestonemarked2-rough")
        node.geometry?.firstMaterial = material
        
//создаем физическое тело мяча чтобы придать физические свойства (сила тяжести, столкновения и т.д.)
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: node))
        node.physicsBody = body
        
        let power = Float(10)
        
// создаем бросок (полет мяча) по напрявлению от нас, иначе он будет просто падать
        let transform = SCNMatrix4(frame.camera.transform)
        let force = SCNVector3(
            -transform.m31 * power,
            -transform.m32 * power,
            -transform.m33 * power
        )
        node.physicsBody?.applyForce(force, asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    //добавляем бросок мяча по нажатию на экран
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        if !hoopAdded {
            let location = sender.location(in: sceneView)
            let result = sceneView.hitTest(location, types: [.existingPlaneUsingExtent])
            
            if let result = result.first {
                addHoop(result: result)
            }
        } else {
            createBasketballs()
        }
    }
}

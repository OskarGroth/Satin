//
//  Renderer.swift
//  3D-macOS
//
//  Created by Reza Ali on 2/9/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class ShippingShadersRenderer: BaseRenderer {
    #if os(macOS) || os(iOS)
    lazy var raycaster: Raycaster = {
        Raycaster(device: device)
    }()
    #endif
    
    var shippingMaterial: Material = Material(shader: Shader("Test", "normalColorVertex", "normalColorFragment"))
    
    lazy var mesh: Mesh = {
        let mesh = Mesh(geometry: IcoSphereGeometry(radius: 1.0, res: 0), material: shippingMaterial)
        mesh.cullMode = .none
        return mesh
    }()
    
    lazy var scene: Object = {
        Object("Scene", [mesh])
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.fov = 30
        camera.near = 0.01
        camera.far = 100.0
        camera.position = simd_make_float3(0.0, 0.0, 5.0)
        return camera
    }()
    
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
    
    lazy var renderer: Satin.Renderer = {
        Satin.Renderer(context: context, scene: scene, camera: camera)
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 60
    }
    
    override func setup() {
        shippingMaterial.depthWriteEnabled = true
        shippingMaterial.blending = .alpha
        shippingMaterial.set("Color", [1.0, 1.0, 1.0, 1.0])
        shippingMaterial.set("Absolute", false)
    }
    
    override func update() {
        cameraController.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }
    
    #if !targetEnvironment(simulator)
    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        let pt = normalizePoint(mtkView.convert(event.locationInWindow, from: nil), mtkView.frame.size)
        raycaster.setFromCamera(camera, pt)
        let results = raycaster.intersect(scene)
        for result in results {
            print(result.object.label)
            print(result.position)
        }
    }
    
    #elseif os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let first = touches.first {
            let point = first.location(in: mtkView)
            let size = mtkView.frame.size
            let pt = normalizePoint(point, size)
            raycaster.setFromCamera(camera, pt)
            let results = raycaster.intersect(scene, true)
            for result in results {
                print(result.object.label)
                print(result.position)
            }
        }
    }
    #endif
    #endif
    
    func normalizePoint(_ point: CGPoint, _ size: CGSize) -> simd_float2 {
        #if os(macOS)
        return 2.0 * simd_make_float2(Float(point.x / size.width), Float(point.y / size.height)) - 1.0
        #else
        return 2.0 * simd_make_float2(Float(point.x / size.width), 1.0 - Float(point.y / size.height)) - 1.0
        #endif
    }
}


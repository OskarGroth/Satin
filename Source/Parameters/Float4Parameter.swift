//
//  Float4Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/4/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

open class Float4Parameter: NSObject, Parameter {
    public static var type = ParameterType.float4
    public var controlType: ControlType
    public let label: String
    public var string: String { return "float4" }
    public var size: Int { return MemoryLayout<simd_float4>.size }
    public var stride: Int { return MemoryLayout<simd_float4>.stride }
    public var alignment: Int { return MemoryLayout<simd_float4>.alignment }
    public var count: Int { return 4 }
    public var actions: [(simd_float4) -> Void] = []
    public subscript<Float>(index: Int) -> Float {
        get {
            return value[index % count] as! Float
        }
        set {
            value[index % count] = newValue as! Swift.Float
        }
    }
    
    public func dataType<Float>() -> Float.Type {
        return Float.self
    }
    
    var observers: [NSKeyValueObservation] = []
    
    @objc public dynamic var x: Float
    @objc public dynamic var y: Float
    @objc public dynamic var z: Float
    @objc public dynamic var w: Float
    
    @objc public dynamic var minX: Float
    @objc public dynamic var maxX: Float
    
    @objc public dynamic var minY: Float
    @objc public dynamic var maxY: Float
    
    @objc public dynamic var minZ: Float
    @objc public dynamic var maxZ: Float
    
    @objc public dynamic var minW: Float
    @objc public dynamic var maxW: Float
    
    public var value: simd_float4 {
        get {
            return simd_make_float4(x, y, z, w)
        }
        set(newValue) {
            x = newValue.x
            y = newValue.y
            z = newValue.z
            w = newValue.w
        }
    }
    
    public var min: simd_float4 {
        get {
            return simd_make_float4(minX, minY, minZ, minW)
        }
        set(newValue) {
            minX = newValue.x
            minY = newValue.y
            minZ = newValue.z
            minW = newValue.w
        }
    }
    
    public var max: simd_float4 {
        get {
            return simd_make_float4(maxX, maxY, maxZ, maxW)
        }
        set(newValue) {
            maxX = newValue.x
            maxY = newValue.y
            maxZ = newValue.z
            maxW = newValue.w
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case x
        case y
        case z
        case w
        case minX
        case maxX
        case minY
        case maxY
        case minZ
        case maxZ
        case minW
        case maxW
    }
    
    public init(_ label: String, _ value: simd_float4, _ min: simd_float4, _ max: simd_float4, _ controlType: ControlType = .unknown, _ action: ((simd_float4) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.z = value.z
        self.w = value.w
        
        self.minX = min.x
        self.maxX = max.x
        
        self.minY = min.y
        self.maxY = max.y
        
        self.minZ = min.z
        self.maxZ = max.z
        
        self.minW = min.w
        self.maxW = max.w
        
        if let a = action {
            actions.append(a)
        }
        super.init()
        setup()
    }
    
    public init(_ label: String, _ value: simd_float4 = simd_make_float4(0.0), _ controlType: ControlType = .unknown, _ action: ((simd_float4) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.z = value.z
        self.w = value.w
        
        self.minX = 0.0
        self.maxX = 1.0
        
        self.minY = 0.0
        self.maxY = 1.0
        
        self.minZ = 0.0
        self.maxZ = 1.0
        
        self.minW = 0.0
        self.maxW = 1.0
        
        if let a = action {
            actions.append(a)
        }
        super.init()
        setup()
    }
    
    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((simd_float4) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0
        self.w = 0.0
        
        self.minX = 0.0
        self.maxX = 1.0
        
        self.minY = 0.0
        self.maxY = 1.0
        
        self.minZ = 0.0
        self.maxZ = 1.0
        
        self.minW = 0.0
        self.maxW = 1.0
        
        if let a = action {
            actions.append(a)
        }
        super.init()
        setup()
    }
    
    func setup() {
        observers.append(observe(\.x) { [unowned self] _, _ in
            for action in self.actions {
                action(self.value)
            }
        })
        observers.append(observe(\.y) { [unowned self] _, _ in
            for action in self.actions {
                action(self.value)
            }
        })
        observers.append(observe(\.z) { [unowned self] _, _ in
            for action in self.actions {
                action(self.value)
            }
        })
        observers.append(observe(\.w) { [unowned self] _, _ in
            for action in self.actions {
                action(self.value)
            }
        })
    }
    
    deinit {
        observers = []
        actions = []
    }
}

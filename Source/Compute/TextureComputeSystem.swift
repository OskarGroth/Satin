//
//  TextureComputeSystem.swift
//  Satin
//
//  Created by Reza Ali on 7/22/20.
//

import Metal

public protocol TextureComputeSystemDelegate: AnyObject {
    func updated(textureComputeSystem: TextureComputeSystem)
}

open class TextureComputeSystem {
    public var label: String = "Satin Texture Compute Encoder"
    public var textureDescriptors: [MTLTextureDescriptor] {
        didSet {
            _reset = true
            _setupTextures = true
            checkDescriptor()
        }
    }

    public weak var delegate: TextureComputeSystemDelegate?
    
    public var feedback: Bool {
        didSet {
            _reset = true
            _setupTextures = true
        }
    }

    public var index: Int {
        return pong()
    }

    public var count: Int {
        return feedback ? 2 : 1
    }

    public var texture: [MTLTexture] {
        var results: [MTLTexture] = []
        var textureIndex = 0
        for _ in textureDescriptors {
            results.append(textures[textureIndex + _index])
            textureIndex += count
        }
        return results
    }

    public var textures: [MTLTexture] = []
        
    public var resetPipeline: MTLComputePipelineState? {
        didSet {
            if resetPipeline != nil {
                _reset = true
            }
        }
    }
    
    public var updatePipeline: MTLComputePipelineState?

    public var preUpdate: ((_ computeEncoder: MTLComputeCommandEncoder, _ offset: Int) -> ())?
    public var preReset: ((_ computeEncoder: MTLComputeCommandEncoder, _ offset: Int) -> ())?
    public var preCompute: ((_ computeEncoder: MTLComputeCommandEncoder, _ offset: Int) -> ())?

    private var _reset: Bool = true
    private var _setupTextures: Bool = true
    private var _index: Int = 0
    private var _useDispatchThreads: Bool = false

    public var context: Context

    public init(context: Context,
                textureDescriptors: [MTLTextureDescriptor],
                updatePipeline: MTLComputePipelineState?,
                resetPipeline: MTLComputePipelineState?,
                feedback: Bool = false) {
        self.context = context
        self.textureDescriptors = textureDescriptors
        self.updatePipeline = updatePipeline
        self.resetPipeline = resetPipeline
        self.feedback = feedback
        setup()
    }

    public init(context: Context,
                textureDescriptors: [MTLTextureDescriptor],
                updatePipeline: MTLComputePipelineState?,
                feedback: Bool = false) {
        self.context = context
        self.textureDescriptors = textureDescriptors
        self.updatePipeline = updatePipeline
        self.feedback = feedback
        setup()
    }

    public init(context: Context,
                textureDescriptors: [MTLTextureDescriptor],
                feedback: Bool = false) {
        self.context = context
        self.textureDescriptors = textureDescriptors
        self.feedback = feedback
        setup()
    }

    open func setup() {
        checkFeatures()
        checkDescriptor()
        setupTextures()
    }

    deinit {
        textures = []
        resetPipeline = nil
        updatePipeline = nil
    }

    private func checkDescriptor() {
        for textureDescriptor in textureDescriptors {
            if !textureDescriptor.usage.contains(.shaderWrite) {
                textureDescriptor.usage = [textureDescriptor.usage, .shaderWrite]
            }
            if feedback, !textureDescriptor.usage.contains(.shaderRead) {
                textureDescriptor.usage = [textureDescriptor.usage, .shaderRead]
            }
        }
    }

    private func checkFeatures() {
        _useDispatchThreads = false
        let device = context.device
        if #available(macOS 10.15, iOS 13, tvOS 13, *) {
            if device.supportsFamily(.common3) || device.supportsFamily(.apple4) || device.supportsFamily(.apple5) || device.supportsFamily(.mac1) || device.supportsFamily(.mac2) {
                _useDispatchThreads = true
            }
        } else {
            #if os(macOS)
            if device.supportsFeatureSet(.macOS_GPUFamily1_v1) || device.supportsFeatureSet(.macOS_GPUFamily2_v1) {
                _useDispatchThreads = true
            }
            #elseif os(iOS)
            if device.supportsFeatureSet(.iOS_GPUFamily4_v1) || device.supportsFeatureSet(.iOS_GPUFamily5_v1) {
                _useDispatchThreads = true
            }
            #endif
        }
    }

    private func setupTextures() {
        textures = []
        let count = feedback ? 2 : 1
        for textureDescriptor in textureDescriptors {
            for _ in 0..<count {
                if let texture = context.device.makeTexture(descriptor: textureDescriptor) {
                    textures.append(texture)
                }
            }
        }
    }

    public func reset() {
        _reset = true
    }

    public func resetTextures() {
        _setupTextures = true
    }

    public func update(_ commandBuffer: MTLCommandBuffer) {
        if _setupTextures {
            setupTextures()
            _index = 0
            _setupTextures = false
        }
        
        if textureDescriptors.count > 0, resetPipeline != nil || updatePipeline != nil, let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            computeEncoder.label = label

            if _reset, let pipeline = self.resetPipeline {
                computeEncoder.setComputePipelineState(pipeline)
                let count = feedback ? 2 : 1
                for i in 0..<count {
                    let offset = setTextures(computeEncoder, i)
                    preReset?(computeEncoder, offset)
                    preCompute?(computeEncoder, offset)
                    dispatch(computeEncoder, pipeline)
                    pingPong()
                }
                _reset = false
            }

            if let pipeline = self.updatePipeline {
                computeEncoder.setComputePipelineState(pipeline)
                let offset = setTextures(computeEncoder, _index)
                preUpdate?(computeEncoder, offset)
                preCompute?(computeEncoder, offset)
                dispatch(computeEncoder, pipeline)
                pingPong()
            }

            computeEncoder.endEncoding()
        }
    }

    private func setTextures(_ computeEncoder: MTLComputeCommandEncoder, _ index: Int) -> Int {
        var index = 0
        if feedback {
            var textureIndex = 0
            for _ in textureDescriptors {
                computeEncoder.setTexture(textures[textureIndex + ping()], index: index)
                index += 1
                computeEncoder.setTexture(textures[textureIndex + pong()], index: index)
                index += 1
                textureIndex += 2
            }
        } else {
            var textureIndex = 0
            for _ in textureDescriptors {
                computeEncoder.setTexture(textures[textureIndex], index: index)
                textureIndex += 1
                index += 1
            }            
        }

        return index
    }

    func dispatch(_ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        guard let texture = self.texture.first else { return }
        #if os(iOS) || os(macOS)
        if _useDispatchThreads {
            _dispatchThreads(texture, computeEncoder, pipeline)
        } else {
            _dispatchThreadgroups(texture, computeEncoder, pipeline)
        }
        #elseif os(tvOS)
        _dispatchThreadgroups(texture, computeEncoder, pipeline)
        #endif
    }

    #if os(iOS) || os(macOS)
    private func _dispatchThreads(_ texture: MTLTexture, _ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        let threadExecutionWidth = pipeline.threadExecutionWidth
        let maxTotalThreadsPerThreadgroup = pipeline.maxTotalThreadsPerThreadgroup

        let threadsPerGrid = MTLSize(width: texture.width, height: texture.height, depth: texture.depth)

        let threadsPerThreadgroup = MTLSizeMake(threadExecutionWidth, maxTotalThreadsPerThreadgroup / threadExecutionWidth, 1)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }
    #endif

    private func _dispatchThreadgroups(_ texture: MTLTexture, _ computeEncoder: MTLComputeCommandEncoder, _ pipeline: MTLComputePipelineState) {
        let threadExecutionWidth = pipeline.threadExecutionWidth
        let maxTotalThreadsPerThreadgroup = pipeline.maxTotalThreadsPerThreadgroup

        if texture.depth > 1 {
            var w = Int(pow(Float(maxTotalThreadsPerThreadgroup), 1.0 / 3.0))
            if w > threadExecutionWidth {
                w = threadExecutionWidth
            }
            let threadsPerThreadgroup = MTLSizeMake(w, w, w)
            let threadgroupsPerGrid = MTLSize(width: (texture.width + w - 1) / w,
                                              height: (texture.height + w - 1) / w,
                                              depth: (texture.depth + w - 1) / w)

            computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        } else {
            let w = threadExecutionWidth
            let h = maxTotalThreadsPerThreadgroup / w
            let threadsPerThreadgroup = MTLSizeMake(w, h, 1)

            let threadgroupsPerGrid = MTLSize(width: (texture.width + w - 1) / w,
                                              height: (texture.height + h - 1) / h,
                                              depth: 1)

            computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        }
    }

    private func ping() -> Int {
        return _index
    }

    private func pong() -> Int {
        return ((_index + 1) % count)
    }

    private func pingPong() {
        _index = (_index + 1) % count
    }
}

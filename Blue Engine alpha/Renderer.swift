//
//  Renderer.swift
//  Demo Engine v2
//
//  Created by Ted Kostylev on 1/28/22.
//

import Foundation
import MetalKit

class Renderer {
    let colorPixelFormat: MTLPixelFormat = .bgra8Unorm
    let targetLayer: CAMetalLayer
    let fov: Float = 70.0 // TODO: Expose to UI
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    
    var displayLink: CVDisplayLink!
    
    lazy var depthTexture: MTLTexture = {
        let size = targetLayer.drawableSize
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: DEPTH_TEXTURE_FORMAT,
            width: Int(size.width), height: Int(size.height), mipmapped: false)
        desc.storageMode = .private
        desc.usage = .renderTarget
        return Renderer.device.makeTexture(descriptor: desc)!
    }()
    
    lazy var depthStencilState: MTLDepthStencilState? = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }()
    
    init(targeting layer: CAMetalLayer) {
        // MARK: Metal setup
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
                  fatalError("GPU not available")
              }
        
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        Renderer.library = device.makeDefaultLibrary()
        
        targetLayer = layer
        targetLayer.device = Renderer.device
        targetLayer.pixelFormat = colorPixelFormat
        targetLayer.framebufferOnly = true
        
        // MARK: Display link setup
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {(displayLink: CVDisplayLink, inNow: UnsafePointer<CVTimeStamp>, inOutputTime: UnsafePointer<CVTimeStamp>, flagsIn: CVOptionFlags, flagsOut: UnsafeMutablePointer<CVOptionFlags>, displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in
            unsafeBitCast(displayLinkContext, to: Renderer.self).renderLoop()
            return kCVReturnSuccess
        }
        CVDisplayLinkSetOutputCallback(displayLink, displayLinkOutputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        CVDisplayLinkStart(displayLink)
    }
    
    deinit {
        CVDisplayLinkStop(displayLink)
    }
    
    @objc func renderLoop() {
        autoreleasepool(invoking: {
            render()
        })
    }
    
    func render() {
        guard let drawable = targetLayer.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        renderPassDescriptor.colorAttachments[0].texture    = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        
        renderPassDescriptor.depthAttachment.texture     = depthTexture
        renderPassDescriptor.depthAttachment.clearDepth  = 1.0
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        
        let commandBuffer = Renderer.commandQueue.makeCommandBuffer()!
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderEncoder.setDepthStencilState(depthStencilState)
    }
}

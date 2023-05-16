import Foundation
import Metal
import MetalKit
import SnapKit
import DazeFoundation
import Combine
import ComposableArchitecture

public class PreviewView: MTKView {
  private var commandQueue: MTLCommandQueue!
  //private var imageToRender: CIImage?
  private let context: CIContext
  
  //public let newImageSizePublisher = PassthroughSubject<CGSize, Never>()
  //private var newImageSizeCallback: ((CGSize) -> Void)?
  //private var currentImageSize: CGSize?
  //public let drawPublisher = PassthroughSubject<Void, Never>()
  private var imageToRender: CIImage?
  //private let imageToRender: () -> CIImage
  private let renderScheduler: AnySchedulerOf<DispatchQueue>
  private let mainScheduler: AnySchedulerOf<DispatchQueue>
  private var rendering = false
  
  public let layoutSubviewsPublisher = PassthroughSubject<PreviewView, Never>()
  
  public init(
    device: MTLDevice,
    context: CIContext,
    renderScheduler: AnySchedulerOf<DispatchQueue>,
    mainScheduler: AnySchedulerOf<DispatchQueue>
  ) {
    self.context = context
    self.renderScheduler = renderScheduler
    self.mainScheduler = mainScheduler
    //self.imageToRender = imageToRende
    super.init(frame: .zero, device: device)
    autoResizeDrawable = true
    framebufferOnly = false
    isPaused = true
    //preferredFramesPerSecond = 1
    initMetal()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    layoutSubviewsPublisher.send(self)
  }
  
  private func initMetal() {
    commandQueue = device!.makeCommandQueue()
  }

  public func add(frame: CIImage) {
    //guard drawableSize != .zero else { return }
    imageToRender = frame
    draw()
  }
  
  private func render(image: CIImage, drawable: CAMetalDrawable) {
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let bounds = CGRect(origin: .zero, size: drawableSize)

    let dest = CIRenderDestination(
      width: Int(bounds.width),
      height: Int(bounds.height),
      pixelFormat: MTLPixelFormat.rgba8Unorm,
      commandBuffer: commandBuffer
    ) { drawable.texture }
    dest.isDithered = true
    
    let fitImage = image.filter {
      //passthrough()
      size(.fittingAspect(bounds.size))
    }
//
//    let task = try? context.startTask(toRender: fitImage, to: dest)
//    commandBuffer.present(drawable)
//    commandBuffer.commit()
//    rendering = true
//    renderQueue.async {
//      let _ = try? task?.waitUntilCompleted()
//      DispatchQueue.main.async { self.rendering = false }
//      self.context.clearCaches()
//    }
    
    rendering = true
    renderScheduler.schedule {
      let _ = try? self.context.startTask(toRender: fitImage, to: dest)
      self.mainScheduler.schedule {
        self.rendering = false
        commandBuffer.present(drawable)
        commandBuffer.commit()
      }
      self.context.clearCaches()
    }
  }
  
  public override func draw(_ rect: CGRect) {
    //drawPublisher.send()
    guard
      drawableSize != .zero,
      !rendering,
      let imageToRender = imageToRender,
      //let currentDrawable = (layer as? CAMetalLayer)?.nextDrawable(),
      let currentDrawable = currentDrawable
    else { return }
    self.imageToRender = nil

    autoreleasepool {
      self.render(image: imageToRender, drawable: currentDrawable)
    }
  }
}

//extension PreviewView: MTKViewDelegate {
//  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
//
//  public func draw(in view: MTKView) {
//    drawPublisher.send()
//    guard
//      drawableSize != .zero,
//      !rendering,
//      let imageToRender = imageToRender,
//      //let currentDrawable = (layer as? CAMetalLayer)?.nextDrawable(),
//      let currentDrawable = currentDrawable
//    else { return }
//    self.imageToRender = nil
//
//    autoreleasepool {
//      self.render(image: imageToRender, drawable: currentDrawable)
//    }
//  }
//}

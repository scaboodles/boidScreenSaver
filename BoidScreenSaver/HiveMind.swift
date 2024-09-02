//
//  HiveMind.swift
//  BoidScreenSaver
//
//  Created by Owen Wolff on 8/27/24.
//

import Foundation
import Metal
import simd

class HiveMind{
	public var boids: [Boid] = []
	var scaleFactor: CGFloat
	var frame: NSRect

	private let device: MTLDevice
	private let commandQueue: MTLCommandQueue
	private var computePipelineState: MTLComputePipelineState?

	init(frame : NSRect){
		self.scaleFactor = sqrt( ((frame.width * frame.height) / 8192) / .pi)
		self.frame = frame

		guard let metalDevice = MTLCreateSystemDefaultDevice() else {
			fatalError("metal not supported")
		}
		self.device = metalDevice
		
		guard let metalCommandQueue = device.makeCommandQueue() else {
			fatalError("command queue init failed")
		}
		self.commandQueue = metalCommandQueue

		initMtlPipeline()
	}

	public func mixDaBoids(){
		for boid in boids{
			boid.mixUp()
		}
	}

	private func initMtlPipeline(){
		guard let defaultLibrary = device.makeDefaultLibrary(), let computeFunction = defaultLibrary.makeFunction(name: "flockingKernel") else {
			fatalError("shader failed to load")
		}

		do {
			computePipelineState = try device.makeComputePipelineState(function: computeFunction)
		} catch {
			fatalError("compute pipeline state init failed: \(error.localizedDescription)")
		}
	}

	func populateBoids(numBoids: Int){
		for i in 0..<numBoids {
			boids.append(initRandomBoid(frame: frame, scaleFac : scaleFactor, id:i))
		}
	}


	struct BoidStruct {
		var position: SIMD2<Float>
		var velocity: SIMD2<Float>
		
		var viewRadius: Float
		var avoidRadius: Float

		var avgFlockHeading: SIMD2<Float>
		var centerOfFlockmates: SIMD2<Float>
		var avgAvoidanceHeading: SIMD2<Float>
		var numPerceivedFlockmates: UInt32
	}

	func boidToGpu(boid : Boid) -> BoidStruct{
		let simd2Zero: SIMD2<Float> = SIMD2(0,0)
		let boidStruct : BoidStruct = BoidStruct(position: SIMD2<Float>(Float(boid.pos.x), Float(boid.pos.y)),
												velocity: SIMD2<Float>(Float(boid.velocity.x), Float(boid.velocity.y)),
												viewRadius: Float(boid.viewRadius),
												avoidRadius: Float(boid.avoidRadius),
												avgFlockHeading: simd2Zero,
												centerOfFlockmates: simd2Zero,
												avgAvoidanceHeading: simd2Zero,
												numPerceivedFlockmates: UInt32(0))

		return boidStruct
	}

	func createBoidBuffer(device: MTLDevice) -> MTLBuffer? {
		let boidStructs : [BoidStruct] = boids.map{boidToGpu(boid: $0)}
		let bufferSize = MemoryLayout<BoidStruct>.stride * boidStructs.count
		let boidBuffer = device.makeBuffer(bytes: boidStructs, length: bufferSize, options: .storageModeShared)

		return boidBuffer
	}

func flock(){
	guard let commandBuffer = commandQueue.makeCommandBuffer(),
		  let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
		  let computePipelineState = computePipelineState
	else {
		fatalError("Failed to set up Metal command buffer or compute encoder")
	}
	
	guard let boidBuffer = createBoidBuffer(device: device) else {
		fatalError("Boid buffer init failed")
	}

	computeEncoder.setComputePipelineState(computePipelineState)
	computeEncoder.setBuffer(boidBuffer, offset: 0, index: 0)

	var scaleFactorFloat: Float = Float(boids[0].radius)
	var numBoids: UInt32 = UInt32(boids.count)

	computeEncoder.setBytes(&scaleFactorFloat, length: MemoryLayout<Float>.size, index: 1)
	computeEncoder.setBytes(&numBoids, length: MemoryLayout<UInt32>.size, index: 2)

	let threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)
	let threadgroupsPerGrid = MTLSize(width: boids.count, height: 1, depth: 1)

	computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
	computeEncoder.endEncoding()

	commandBuffer.commit()
	commandBuffer.waitUntilCompleted()

	let boidPointer = boidBuffer.contents().bindMemory(to: BoidStruct.self, capacity: boids.count)
	let updatedBoids = Array(UnsafeBufferPointer(start: boidPointer, count: boids.count))

	// Update the boids with computed data
	for (index, boidStruct) in updatedBoids.enumerated() {
		boids[index].avgFlockHeading = Vector2(x: CGFloat(boidStruct.avgFlockHeading.x), y: CGFloat(boidStruct.avgFlockHeading.y))
		boids[index].avgAvoidanceHeading = Vector2(x: CGFloat(boidStruct.avgAvoidanceHeading.x), y: CGFloat(boidStruct.avgAvoidanceHeading.y))
		boids[index].centerOfFlockmates = Vector2(x: CGFloat(boidStruct.centerOfFlockmates.x), y: CGFloat(boidStruct.centerOfFlockmates.y))
		boids[index].numPerceivedFlockmates = Int(boidStruct.numPerceivedFlockmates)
	}
}


	func drawBoids(){
		for boid in boids {
			boid.draw()
		}
	}

	func updateBoids(bounds : NSRect, deltaTime : CFTimeInterval){
		flock()
		for boid in boids {
			boid.update(bounds: bounds, deltaTime: deltaTime)
		}
	}

	private func randomCGFloat(bound: UInt32) -> CGFloat {
		return CGFloat(arc4random_uniform(bound))
	}

	private func initRandomBoid(frame : NSRect, scaleFac : CGFloat, id: Int) -> Boid {
		let randomPos = CGPoint(x: randomCGFloat(bound : UInt32(frame.width)), y: randomCGFloat(bound : UInt32(frame.height)))

		let randomD = {() -> CGFloat in
			return self.randomCGFloat(bound: UInt32(Boid.maxSpeed)) - CGFloat(Boid.maxSpeed / 2)
		}

		let randomVelocity = Vector2(x: randomD(), y: randomD())

		let newBoid = Boid(position: randomPos, velocity: randomVelocity, scaleFactor: scaleFac, id : id)

		return newBoid
	}
}

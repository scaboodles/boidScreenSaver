//
//  MetalLib.swift
//  BoidScreenSaver
//
//  Created by Owen Wolff on 8/27/24.
//
import Metal
import simd

class MetalManager {
	var device: MTLDevice!
	var commandQueue: MTLCommandQueue!
	var computePipelineState: MTLComputePipelineState!

	init() {
		initializeMetal()
	}

	func getDevice() -> MTLDevice{
		return device
	}

	private func initializeMetal() {
		// Set up Metal
		device = MTLCreateSystemDefaultDevice()
		commandQueue = device.makeCommandQueue()

		// Load the compute shader
		let library = device.makeDefaultLibrary()
		let computeFunction = library?.makeFunction(name: "BoidThink")
		computePipelineState = try? device.makeComputePipelineState(function: computeFunction!)
	}

	func performBoidSimulation(boidBuffer: MTLBuffer, numBoids: UInt32, viewRadius: Float, avoidRadius: Float, boidStructStride : Int) {
		var numBoidsVar = numBoids
		var viewRadiusVar = viewRadius
		var avoidRadiusVar = avoidRadius

		let commandBuffer = commandQueue.makeCommandBuffer()
		let computeEncoder = commandBuffer?.makeComputeCommandEncoder()

		computeEncoder?.setComputePipelineState(computePipelineState)
		computeEncoder?.setBuffer(boidBuffer, offset: 0, index: 0)
		computeEncoder?.setBytes(&numBoidsVar, length: MemoryLayout<UInt32>.size, index: 1)
		computeEncoder?.setBytes(&viewRadiusVar, length: MemoryLayout<Float>.size, index: 2)
		computeEncoder?.setBytes(&avoidRadiusVar, length: MemoryLayout<Float>.size, index: 3)

		let threadGroupSize = MTLSize(width: 32, height: 1, depth: 1)
		let threadGroups = MTLSize(width: (boidBuffer.length / boidStructStride + 31) / 32, height: 1, depth: 1)
		computeEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)

		computeEncoder?.endEncoding()
		commandBuffer?.commit()
		commandBuffer?.waitUntilCompleted()
	}

	public static func getUpdatedBoids(from buffer: MTLBuffer, numBoids: Int) -> [HiveMind.BoidStructGPU] {
		let boidsPointer = buffer.contents().bindMemory(to: HiveMind.BoidStructGPU.self, capacity: numBoids)
		let boidsArray = Array(UnsafeBufferPointer(start: boidsPointer, count: numBoids))
		return boidsArray
	}
}

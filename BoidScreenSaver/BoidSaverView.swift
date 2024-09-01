import ScreenSaver
import Foundation
import Cocoa

class BoidScreenSaverView : ScreenSaverView {
    var hivemind : HiveMind
    private var lastUpdateTime : CFTimeInterval 

    override init?(frame: NSRect, isPreview: Bool) {
        self.hivemind = HiveMind(frame: frame)
		self.lastUpdateTime = CACurrentMediaTime()
		
		super.init(frame : frame, isPreview : isPreview)

        self.animationTimeInterval = 1/30.0

        hivemind.populateBoids(numBoids : 100)

    }

    required init?(coder: NSCoder) {
        let defaultFrame = NSRect(x: 0, y: 0, width: 100, height: 100)
        self.hivemind = HiveMind(frame: defaultFrame)
		self.lastUpdateTime = CACurrentMediaTime()
		
        super.init(coder: coder)

        hivemind.populateBoids(numBoids : 100)

    }

    override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        rect.fill()

        hivemind.drawBoids()
    }

    override func animateOneFrame() {
        let currTime = CACurrentMediaTime()
        let deltaTime = currTime - lastUpdateTime
        lastUpdateTime = currTime

        hivemind.updateBoids(bounds : self.bounds, deltaTime: deltaTime)
        self.setNeedsDisplay(self.bounds)
    }

}

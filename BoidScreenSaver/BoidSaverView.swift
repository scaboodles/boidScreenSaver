import ScreenSaver
import Foundation
import Cocoa

class BoidScreenSaverView : ScreenSaverView {
    var hivemind : HiveMind
    private var lastUpdateTime : CFTimeInterval 
    private var frames = 0

    override init?(frame: NSRect, isPreview: Bool) {
        self.hivemind = HiveMind(frame: frame)
		self.lastUpdateTime = CACurrentMediaTime()
		
		super.init(frame : frame, isPreview : isPreview)

        self.animationTimeInterval = 1/8.0

        hivemind.populateBoids(numBoids : 100)

    }

    required init?(coder: NSCoder) {
        let defaultFrame = NSRect(x: 0, y: 0, width: 100, height: 100)
        self.hivemind = HiveMind(frame: defaultFrame)
		self.lastUpdateTime = CACurrentMediaTime()
		
        super.init(coder: coder)

        hivemind.populateBoids(numBoids : 100)
        super.startAnimation()
    }

    override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        rect.fill()

        hivemind.drawBoids()
        drawCurrentTime()

        super.startAnimation()
    }

    override func animateOneFrame() {
        frames += 1
        if( frames % 60 == 0){
            hivemind.mixDaBoids()
        }

        let currTime = CACurrentMediaTime()
        let deltaTime = currTime - lastUpdateTime
        lastUpdateTime = currTime

        hivemind.updateBoids(bounds : self.bounds, deltaTime: deltaTime)
        self.setNeedsDisplay(self.bounds)
    }
    
    private func drawCurrentTime() {
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.dateFormat = "hh:mm"
            let currentTime = formatter.string(from: Date())

            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: NSColor.black
            ]

            let attributedString = NSAttributedString(string: currentTime, attributes: attributes)

            let size = attributedString.size()
            let xPos = (self.bounds.width - size.width) / 2
            let yPos = (self.bounds.height - size.height) / 2
            let textRect = CGRect(x: xPos, y: yPos, width: size.width, height: size.height)

            attributedString.draw(in: textRect)
        }
}

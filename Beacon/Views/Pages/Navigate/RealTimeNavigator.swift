import Foundation
import Combine
import MapKit

class RealTimeNavigator: NSObject, ObservableObject {
    var cancellables = Set<AnyCancellable>()
    
    // 外部提供路线
    var route: MKRoute? {
        didSet {
            // 一旦新路线被设置，需要把 steps 存起来
            if let r = route {
                steps = r.steps
                currentStepIndex = 0
            }
        }
    }
    
    // 当前在第几个 step
    private var currentStepIndex = 0
    private var steps: [MKRoute.Step] = []

    @Published var instruction: String = "No instruction"
    
    // 距离下一个转弯多少米时更新提示，阈值可以根据需求调整
    private let updateThreshold: CLLocationDistance = 5.0
    
    // 定义距离格式化
    private let distanceFormatter: MKDistanceFormatter = {
        let df = MKDistanceFormatter()
        df.unitStyle = .abbreviated // 设置下样式
        return df
    }()
    
    // 你可以在这里计算 “距离下一个转弯还有多少米”
    func updateLocation(_ location: CLLocation) {
        guard currentStepIndex < steps.count else {
            instruction = "Arrived"
            return
        }
        
        let step = steps[currentStepIndex]
        let stepEndLocation = step.polyline.coordinate // 大多数情况取 polyline 的最后一个坐标或 step.instructions 里的 maneuver point
        let stepEndCLLocation = CLLocation(latitude: stepEndLocation.latitude,
                                           longitude: stepEndLocation.longitude)
        
        let distanceToEnd = location.distance(from: stepEndCLLocation)
        
        if distanceToEnd <= updateThreshold {
            // 说明快到或已经到转弯点了
            instruction = "Now " + (step.notice ?? step.instructions)
            // 准备切换到下一个 step
            currentStepIndex += 1
            
            if currentStepIndex < steps.count {
                instruction += "\nNext Step：\(steps[currentStepIndex].notice ?? steps[currentStepIndex].instructions)"
            } else {
                instruction = "Arrived"
            }
        } else {
            // 还没有到转弯点
            let distanceStr = distanceFormatter.string(fromDistance: distanceToEnd)
            instruction = "Move forward \(distanceStr), then \(step.instructions)"
        }
    }
}


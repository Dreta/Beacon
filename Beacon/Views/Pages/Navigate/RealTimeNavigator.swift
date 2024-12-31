import Foundation
import Combine
import MapKit

class RealTimeNavigator: NSObject, ObservableObject {
    // 外部设置：用于存储当前要进行导航的整条路线
    var route: MKRoute? {
        didSet {
            // 一旦新路线被设置，就把所有 steps 拿出来，回到第 0 步
            if let r = route {
                steps = r.steps
                currentStepIndex = 0
                instruction = steps.isEmpty ? "No route steps" : "Route loaded"
            } else {
                steps = []
                currentStepIndex = 0
                instruction = "No route"
            }
        }
    }
    
    // 用于输出当前的导航语句，由 SwiftUI 或者其他 UI 进行绑定显示
    @Published var instruction: String = "No instruction"
    
    // 内部变量：所有导航步长（每一步对应地图上一次转弯或直行等操作）
    private var steps: [MKRoute.Step] = []
    // 当前正在执行第几个 step
    private var currentStepIndex: Int = 0
    
    // 自定义一个阈值，用于判断 “距离下一步转弯点” 多少米时，就切到下一步
    // 你可以根据实际需要来调整这个数值
    private let updateThreshold: CLLocationDistance = 5.0
    
    // 距离格式化器，用于把“米”转换成更易读的字符串，比如 "20 m", "0.02 km" 等
    private let distanceFormatter: MKDistanceFormatter = {
        let df = MKDistanceFormatter()
        df.unitStyle = .abbreviated // "km", "m", "ft", "mi" 等简写
        return df
    }()
    
    /// 当用户位置信息更新时，外部可以调用这个方法。
    /// 内部会根据用户当前位置与下一步转弯点距离，动态更新 `instruction`.
    func updateLocation(_ location: CLLocation) {
        // 如果已经超过了最后一个 step，说明导航结束
        guard currentStepIndex < steps.count else {
            instruction = "Arrived"
            return
        }
        
        let step = steps[currentStepIndex]
        
        // 获取当前 step 的终点坐标。
        // 注意：一般来说，如果想更精确，可以拿 polyline 的最后一个坐标作为终点。
        let count = step.polyline.pointCount
        guard count > 0 else {
            instruction = "Arrived"
            return
        }
        
        let stepPoints = step.polyline.points()
        let lastCoord = stepPoints[count - 1].coordinate
        let stepEndCLLocation = CLLocation(latitude: lastCoord.latitude,
                                           longitude: lastCoord.longitude)
        
        // 计算用户当前位置到该 step 终点的直线距离
        let distanceToEnd = location.distance(from: stepEndCLLocation)
        
        // 如果已经接近或到达下一个转弯点
        if distanceToEnd <= updateThreshold {
            // 把当前 step 的指令输出，比如“Now Turn Right”
            instruction = "Now " + (step.notice ?? step.instructions)
            
            // 准备切换到下一个 step
            currentStepIndex += 1
            
            if currentStepIndex < steps.count {
                // 告诉用户下一步要做的事
                instruction += "\nNext Step: \(steps[currentStepIndex].notice ?? steps[currentStepIndex].instructions)"
            } else {
                // 导航结束
                instruction = "Arrived"
            }
        } else {
            // 尚未到转弯点
            // 展示当前到下一步转弯还有多远，以及转弯/直行等下一步动作
            let distanceStr = distanceFormatter.string(fromDistance: distanceToEnd)
            instruction = "Move forward \(distanceStr), then \(step.instructions)"
        }
    }
}

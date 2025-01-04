import Foundation
import Combine
import MapKit

class RealTimeNavigator: NSObject, ObservableObject {
    var route: MKRoute? {
        didSet {
            // Reset steps and calculate totals
            if let r = route {
                steps = r.steps
                currentStepIndex = 0
                instruction = steps.isEmpty ? "No route steps" : "Route loaded"
                
                // Calculate total distance and time
                totalDistance = r.distance
                totalTime = r.expectedTravelTime
                distanceRemaining = r.distance
                timeRemaining = r.expectedTravelTime
            } else {
                steps = []
                currentStepIndex = 0
                instruction = "No route"
                totalDistance = 0.0
                totalTime = 0.0
                distanceRemaining = 0.0
                timeRemaining = 0.0
            }
        }
    }
    
    @Published var instruction: String = "No instruction"
    @Published var displayTitle: String = ""
    @Published var displaySubtitle: String = ""
    @Published var steps: [MKRoute.Step] = []
    @Published var currentStepIndex: Int = 0
    
    @Published var totalDistance: Double = 0.0 // in meters
    @Published var totalTime: TimeInterval = 0.0 // in seconds
    @Published var distanceRemaining: Double = 0.0 // in meters
    @Published var timeRemaining: TimeInterval = 0.0 // in seconds
    
    var currentStep: MKRoute.Step? {
        guard currentStepIndex < steps.count else {
            return nil
        }
        return steps[currentStepIndex]
    }
    
    // A threshold to determine when to switch to the next step
    private let updateThreshold: CLLocationDistance = 5.0
    
    private let distanceFormatter: MKDistanceFormatter = {
        let df = MKDistanceFormatter()
        df.unitStyle = .abbreviated
        return df
    }()
    
    var lastKnownLocation: CLLocation?
    
    // Update the instruction to speak and remaining metrics
    func updateLocation(_ location: CLLocation) {
        // Update distanceRemaining based on movement
        if let lastLocation = lastKnownLocation {
            let distanceTraveled = location.distance(from: lastLocation)
            distanceRemaining = max(distanceRemaining - distanceTraveled, 0)
            // Recalculate timeRemaining based on new distanceRemaining
            if totalDistance > 0 {
                timeRemaining = (distanceRemaining / totalDistance) * totalTime
            } else {
                timeRemaining = 0.0
            }
        }
        
        lastKnownLocation = location
        
        // If we've exhausted all steps, the user has arrived.
        guard currentStepIndex < steps.count else {
            instruction = "Arrived at your destination."
            displaySubtitle = ""
            displayTitle = "Arrived"
            distanceRemaining = 0.0
            timeRemaining = 0.0
            return
        }
        
        guard let step = currentStep else {
            instruction = "Arrived at your destination."
            displaySubtitle = ""
            displayTitle = "Arrived"
            distanceRemaining = 0.0
            timeRemaining = 0.0
            return
        }
        
        // Distance from current location to the end of the step
        let stepPoints = step.polyline.points()
        let count = step.polyline.pointCount
        guard count > 0 else {
            instruction = "Arrived at your destination."
            displaySubtitle = ""
            displayTitle = "Arrived"
            distanceRemaining = 0.0
            timeRemaining = 0.0
            return
        }
        
        let lastCoord = stepPoints[count - 1].coordinate
        let stepEndCLLocation = CLLocation(latitude: lastCoord.latitude,
                                           longitude: lastCoord.longitude)
        let distanceToEnd = location.distance(from: stepEndCLLocation)
        
        // If we're within a small threshold of the step’s end, advance to the next step.
        if distanceToEnd <= updateThreshold {
            currentStepIndex += 1
            if currentStepIndex >= steps.count {
                instruction = "Arrived at your destination."
                displaySubtitle = ""
                displayTitle = "Arrived"
                distanceRemaining = 0.0
                timeRemaining = 0.0
            } else {
                // Announce the new step’s instruction right after switching
                let nextStep = steps[currentStepIndex]
                if nextStep.instructions.isEmpty {
                    instruction = "Continue following the route."
                    displaySubtitle = ""
                    displayTitle = "Continue along the route."
                } else {
                    instruction = nextStep.instructions
                    displaySubtitle = ""
                    displayTitle = instruction
                }
                
                // Recalculate distanceRemaining for remaining steps
                distanceRemaining = calculateRemainingDistance(from: currentStepIndex)
                // Recalculate timeRemaining based on new distanceRemaining
                if totalDistance > 0 {
                    timeRemaining = (distanceRemaining / totalDistance) * totalTime
                } else {
                    timeRemaining = 0.0
                }
            }
            return
        }
        
        // Otherwise, provide an in-progress instruction: "In xx m, [turn left]."
        let distanceStr = distanceFormatter.string(fromDistance: distanceToEnd)
        if step.instructions.isEmpty {
            instruction = "Continue straight for \(distanceStr)"
            displaySubtitle = "For \(distanceStr)"
            displayTitle = "Continue straight"
        } else {
            instruction = "In \(distanceStr), \(step.instructions)"
            displaySubtitle = "In \(distanceStr)"
            displayTitle = step.instructions
        }
    }
    
    // Helper method to calculate remaining distance from current step onwards
    private func calculateRemainingDistance(from index: Int) -> Double {
        guard index < steps.count else { return 0.0 }
        let remainingSteps = steps[index...]
        let remainingDistance = remainingSteps.reduce(0.0) { $0 + $1.distance }
        return remainingDistance
    }
}

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
    
    // The current step, if any
    var currentStep: MKRoute.Step? {
        guard currentStepIndex < steps.count else {
            return nil
        }
        return steps[currentStepIndex]
    }
    
    // Old threshold to decide if user is "close enough" to the step's endpoint
    private let updateThreshold: CLLocationDistance = 5.0
    
    private let distanceFormatter: MKDistanceFormatter = {
        let df = MKDistanceFormatter()
        df.unitStyle = .abbreviated
        return df
    }()
    
    // Keep track of the user’s last known location
    var lastKnownLocation: CLLocation?
    
    // MARK: - Core Update Logic
    func updateLocation(_ location: CLLocation) {
        // 1) Update distanceRemaining/timeRemaining
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
        
        // 2) If we've used up all steps, user is presumably at destination.
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
        
        // 3) Distance from current location to the end of the current step
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
        
        // MARK: - NEW LOGIC BELOW (Solutions #1 and #3)
        // ---------------------------------------------------------
        //  A) If there's a "next step," check whether we're effectively *beyond* this step
        //     by comparing distance to next step's start OR measuring which polyline
        //     we're closer to. If it looks like we've transitioned, advance the step now.
        
        if currentStepIndex + 1 < steps.count {
            let nextStep = steps[currentStepIndex + 1]
            
            // A1) Compare distance to next step's start vs. current step's end
            let distanceToNextStart = distanceToStartOfStep(from: location, step: nextStep)
            // If you're clearly closer to next step's start than you are to the current step's end,
            // it's likely you've passed the turn.
            if distanceToNextStart + 5.0 < distanceToEnd {
                // Advance to next step
                advanceToNextStep()
                return
            }
            
            // A2) Check if user is "off" the current step's polyline and "onto" the next step's
            let distCurrentPolyline = minDistanceToPolyline(location, polyline: step.polyline)
            let distNextPolyline    = minDistanceToPolyline(location, polyline: nextStep.polyline)
            
            // If you're significantly closer to the next step geometry, we assume you've turned.
            if distNextPolyline + 20.0 < distCurrentPolyline {
                advanceToNextStep()
                return
            }
        }
        // ---------------------------------------------------------
        
        // 4) Old logic: if within 'updateThreshold' of the step’s end, we move on.
        if distanceToEnd <= updateThreshold {
            advanceToNextStep()
            return
        }
        
        // 5) Otherwise, provide an "in-progress" instruction
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
    
    // MARK: - Advance to Next Step
    private func advanceToNextStep() {
        currentStepIndex += 1
        if currentStepIndex >= steps.count {
            // We’ve completed the route
            instruction = "Arrived at your destination."
            displaySubtitle = ""
            displayTitle = "Arrived"
            distanceRemaining = 0.0
            timeRemaining = 0.0
        } else {
            // Announce the next step
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
            // Recalculate distance/time remaining
            distanceRemaining = calculateRemainingDistance(from: currentStepIndex)
            if totalDistance > 0 {
                timeRemaining = (distanceRemaining / totalDistance) * totalTime
            } else {
                timeRemaining = 0.0
            }
        }
    }
    
    // MARK: - Calculate Distance from the Current Step to the End
    private func calculateRemainingDistance(from index: Int) -> Double {
        guard index < steps.count else { return 0.0 }
        let remainingSteps = steps[index...]
        return remainingSteps.reduce(0.0) { $0 + $1.distance }
    }
    
    // MARK: - NEW HELPERS (Solution #1 & #3) ------------------
    /// Distance from the user’s location to the first coordinate (start) of a step.
    private func distanceToStartOfStep(from location: CLLocation, step: MKRoute.Step) -> CLLocationDistance {
        guard step.polyline.pointCount > 0 else {
            return Double.greatestFiniteMagnitude
        }
        let firstCoord = step.polyline.points()[0].coordinate
        let firstCL = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        return location.distance(from: firstCL)
    }
    
    /// Minimum distance from user’s location to any segment in the polyline.
    private func minDistanceToPolyline(_ location: CLLocation, polyline: MKPolyline) -> CLLocationDistance {
        let points = polyline.points()
        let count = polyline.pointCount
        guard count > 1 else {
            // If zero points, can’t measure
            if count == 1 {
                let coord = points[0].coordinate
                return location.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
            }
            return Double.greatestFiniteMagnitude
        }
        
        var minDistance = Double.greatestFiniteMagnitude
        for i in 0..<(count - 1) {
            let startCoord = points[i].coordinate
            let endCoord   = points[i + 1].coordinate
            let segmentDistance = distanceFromLocationToLineSegment(
                location: location,
                start: startCoord,
                end: endCoord
            )
            minDistance = min(minDistance, segmentDistance)
        }
        
        return minDistance
    }
    
    /// Distance from the user’s location to a single line segment [start, end].
    private func distanceFromLocationToLineSegment(location: CLLocation,
                                                   start: CLLocationCoordinate2D,
                                                   end: CLLocationCoordinate2D) -> CLLocationDistance {
        let locPoint   = MKMapPoint(location.coordinate)
        let startPoint = MKMapPoint(start)
        let endPoint   = MKMapPoint(end)
        
        let lineLenSquared = (startPoint.x - endPoint.x)*(startPoint.x - endPoint.x)
                           + (startPoint.y - endPoint.y)*(startPoint.y - endPoint.y)
        if lineLenSquared == 0 {
            // start & end are the same point
            return location.distance(from: CLLocation(latitude: start.latitude, longitude: start.longitude))
        }
        
        // Dot product to find the projection of loc onto the segment
        let t = max(0, min(
            1,
            ((locPoint.x - startPoint.x)*(endPoint.x - startPoint.x)
             + (locPoint.y - startPoint.y)*(endPoint.y - startPoint.y))
             / lineLenSquared
        ))
        
        // Projection point
        let projX = startPoint.x + t * (endPoint.x - startPoint.x)
        let projY = startPoint.y + t * (endPoint.y - startPoint.y)
        let projPoint = MKMapPoint(x: projX, y: projY)
        
        let projCoord = projPoint.coordinate
        return location.distance(from: CLLocation(latitude: projCoord.latitude, longitude: projCoord.longitude))
    }
}

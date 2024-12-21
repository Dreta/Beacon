import MapKit
import Combine

class RouteHelper: NSObject, ObservableObject {
    @Published var routeStr = ""
    let distanceFormatter = MKDistanceFormatter()
    private var cancellables = Set<AnyCancellable>()

    func calculateRoute(from start: String, to end: String) {
        
        self.routeStr = "Searching...\n"
        
        //搜索地理坐标
        searchLocation(query: start)
            .zip(searchLocation(query: end))
            .sink { completion in
                //错误处理
                if case .failure(let error) = completion {
                    self.routeStr = "Location Search Error：\(error.localizedDescription)"
                }
            } receiveValue: { startItem, endItem in
                self.route(from: startItem, to: endItem)
            }
            .store(in: &cancellables)
    }

    private func route(from startItem: MKMapItem, to endItem: MKMapItem) {
        let request = MKDirections.Request()
        request.source = startItem
        request.destination = endItem
        request.requestsAlternateRoutes = true
        
        //先定义为automobile之后在改别的
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            //报错信息
            guard let mapRoute = response?.routes.first else {
                self.routeStr = "Cannot find route：\(error?.localizedDescription ?? "Unknown Error")"
                return
            }
            
            var rs = "Route Result:\n"
            rs += "Distances: \(mapRoute.distance)m\n"
            rs += "Estimated Time: \(mapRoute.expectedTravelTime)seconds\n"
            
            var i = 0
            for step in mapRoute.steps {
                i += 1
                rs += "\(i): \(step.notice ?? step.instructions)\n"
                rs += "    \(self.distanceFormatter.string(fromDistance: step.distance))\n"
            }
            
            //主线程刷新
            DispatchQueue.main.async {
                self.routeStr = rs
            }
        }
    }

    private func searchLocation(query: String) -> Future<MKMapItem, Error> {
        return Future { promise in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let mapItem = response?.mapItems.first else {
                    promise(.failure(NSError(domain: "NoResult", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Result for \(query)"])))
                    return
                }
                promise(.success(mapItem))
            }
        }
    }
}

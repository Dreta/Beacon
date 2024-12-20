import SwiftUI

let routerHelper = RouteHelper()
struct ContentView: View {
    @ObservedObject var model = routerHelper
    var body: some View {
        
        Text("起点:苹果园（39.983603，116.411707）")
        Text("终点:古城（39.913414，116.197072）")
        Divider()
        Button("计算"){
            model.route()
            
        }
        Divider()
        ScrollView{
            Text(self.model.routeStr)
            
        }
    }
}

#Preview {
    ContentView()
}

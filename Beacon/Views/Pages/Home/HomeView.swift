import SwiftUI

struct HomeView: View {
    var body: some View {
        TabView {
            InitiateNavigateView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Navigate")
                }

            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
    }
}

#Preview {
    HomeView()
}

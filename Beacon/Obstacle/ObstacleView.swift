//
//  ContentView.swift
//  Beacon
//
//  Created by Dreta ​ on 12/3/24.
//

import SwiftUI

struct ObstacleView: View {
    @StateObject private var model = FrameHandler()
    
    var body: some View {
        FrameView(image: model.frame)
            .ignoresSafeArea()
    }
}

#Preview {
    ObstacleView()
}

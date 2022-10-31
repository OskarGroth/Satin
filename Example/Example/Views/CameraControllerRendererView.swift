//
//  Renderer2DView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct CameraControllerRendererView: View {
    var body: some View {
        ForgeView(renderer: CameraControllerRenderer())
            .ignoresSafeArea()
            .navigationTitle("Camera Controller")
    }
}

struct CameraControllerRendererView_Previews: PreviewProvider {
    static var previews: some View {
        CameraControllerRendererView()
    }
}

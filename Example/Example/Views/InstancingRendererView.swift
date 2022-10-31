//
//  InstancingRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/17/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct CustomInstancingRendererView: View {
    var body: some View {
        ForgeView(renderer: CustomInstancingRenderer())
            .ignoresSafeArea()
            .navigationTitle("Custom Instancing")
    }
}

struct CustomInstancingRendererView_Previews: PreviewProvider {
    static var previews: some View {
        CustomInstancingRendererView()
    }
}

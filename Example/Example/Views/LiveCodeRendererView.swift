//
//  LiveCodeRendererView.swift
//  Example
//
//  Created by Reza Ali on 8/12/22.
//  Copyright © 2022 Hi-Rez. All rights reserved.
//

import SwiftUI
import Forge

struct LiveCodeRendererView: View {
    var body: some View {
        ForgeView(renderer: LiveCodeRenderer())
            .ignoresSafeArea()
            .navigationTitle("Live Code")
    }
}

struct LiveCodeRendererView_Previews: PreviewProvider {
    static var previews: some View {
        LiveCodeRendererView()
    }
}


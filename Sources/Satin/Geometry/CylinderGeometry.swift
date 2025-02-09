//
//  CylinderGeometry.swift
//  Satin
//
//  Created by Reza Ali on 9/8/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import simd

open class CylinderGeometry: Geometry {
    override public init() {
        super.init()
        self.setupData(size: (1, 2), res: (60, 1, 1))
    }

    public init(size: (radius: Float, height: Float), res: (angular: Int, radial: Int, vertical: Int)) {
        super.init()
        self.setupData(size: size, res: res)
    }

    func setupData(size: (radius: Float, height: Float), res: (angular: Int, radial: Int, vertical: Int)) {
        var geometryData = generateCylinderGeometryData(size.radius, size.height, Int32(res.angular), Int32(res.radial), Int32(res.vertical))
        setFrom(&geometryData)
        freeGeometryData(&geometryData)
    }
}

//
//  GOLRule.swift
//  LifeSentence
//
//  Created by David House on 5/23/15.
//  Copyright (c) 2015 David House. All rights reserved.
//

import UIKit

class GOLRule {

    var existing:Set<GOLPoint>
    var width:Int
    var height:Int
    
    var alive:Bool
    var deadNeighbors:Set<GOLPoint>
    
    init(existing:Set<GOLPoint>,width:Int,height:Int) {
        self.existing = existing
        self.width = width
        self.height = height
        self.alive = false
        self.deadNeighbors = Set<GOLPoint>()
    }
    
    func processPoint(checkPoint:GOLPoint) {

        deadNeighbors.removeAll(keepingCapacity: false)

        // count the alive neighbors
        var aliveCount = aliveNeighborsForPoint(point: checkPoint)
        
        // Are we alive or dead? The rules are different for each
        if existing.contains(checkPoint) {
        
            if (aliveCount == 2) || (aliveCount == 3) {
                self.alive = true
            }
            else {
                self.alive = false
            }
            
            // Now check our neighbors to see if any are dead but might
            // come alive...
            for direction:GOLPointNeighborDirection in GOLPointNeighborDirection.allDirections {
                if let deadPoint:GOLPoint = deadValidNeighbor(point: checkPoint.neighbor(direction)) {
                    deadNeighbors.insert(deadPoint)
                }
            }
        }
        else {
            
            if aliveCount == 3 {
                self.alive = true
            }
            else {
                self.alive = false
            }
        }
    }
    
    private func aliveNeighborsForPoint(point:GOLPoint) -> Int {
        var aliveCount = 0
        
        if existing.contains(point.neighbor(.TopLeft)) {
            aliveCount += 1
        }
        
        if existing.contains(point.neighbor(.Top)) {
            aliveCount += 1
        }
        
        if existing.contains(point.neighbor(.TopRight)) {
            aliveCount += 1
        }
        
        if existing.contains(point.neighbor(.Left)) {
            aliveCount += 1
        }
        
        if existing.contains(point.neighbor(.Right)) {
            aliveCount += 1
        }
        
        if existing.contains(point.neighbor(.BottomLeft)) {
            aliveCount += 1
        }
        
        if existing.contains(point.neighbor(.Bottom)) {
            aliveCount += 1
        }
        
        if existing.contains(point.neighbor(.BottomRight)) {
            aliveCount += 1
        }
        
        
        return aliveCount
    }
    
    private func deadValidNeighbor(point:GOLPoint) -> GOLPoint? {
        
        if point.x > 0 && point.x <= self.width && point.y > 0 && point.y <= self.height {
            
            if existing.contains(point) {
                return nil
            }
            else {
                return point
            }
        }
        else {
            return nil
        }
    }

}

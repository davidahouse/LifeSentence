//
//  LifeOperation.swift
//  LifeSentence
//
//  Created by David House on 5/23/15.
//  Copyright (c) 2015 David House. All rights reserved.
//

import UIKit

class LifeOperation: Operation {

    var existingSet:Set<GOLPoint>
    var checkPoint:GOLPoint
    var width:Int
    var height:Int
    var alive:Bool
    var deadNeighbors:Set<GOLPoint>
    
    init(existingSet:Set<GOLPoint>,checkPoint:GOLPoint,width:Int,height:Int) {
        self.existingSet = existingSet
        self.checkPoint = checkPoint
        self.width = width
        self.height = height
        self.alive = false
        self.deadNeighbors = Set<GOLPoint>()
    }
    
    override func main() {

        if self.isCancelled {
            return
        }

        let rule = GOLRule(existing: existingSet, width:width, height: height)
        rule.processPoint(checkPoint: checkPoint)
        self.alive = rule.alive
        self.deadNeighbors = rule.deadNeighbors
    }
}

//
//  GOL.swift
//  LifeSentence
//
//  Created by David House on 5/23/15.
//  Copyright (c) 2015 David House. All rights reserved.
//

import UIKit

enum GOLPointNeighborDirection {
    case TopLeft
    case Top
    case TopRight
    case Left
    case Right
    case BottomLeft
    case Bottom
    case BottomRight
    
    static let allDirections = [TopLeft,Top,TopRight,Left,Right,BottomLeft,Bottom,BottomRight]
}

class GOLPoint : Hashable, Equatable {
    var x:Int
    var y:Int
    
    init(x:Int,y:Int) {
        self.x = x
        self.y = y
    }
    
    var hashValue: Int {
        return "\(x),\(y)".hashValue
    }

    func neighbor(_ direction: GOLPointNeighborDirection) -> GOLPoint {
        switch direction {
        case .TopLeft:
            return GOLPoint(x:x-1,y:y-1)
        case .Top:
            return GOLPoint(x:x,y:y-1)
        case .TopRight:
            return GOLPoint(x:x+1,y:y-1)
        case .Left:
            return GOLPoint(x:x-1,y:y)
        case .Right:
            return GOLPoint(x:x+1,y:y)
        case .BottomLeft:
            return GOLPoint(x:x-1,y:y+1)
        case .Bottom:
            return GOLPoint(x:x,y:y+1)
        case .BottomRight:
            return GOLPoint(x:x+1,y:y+1)
        }
    }    
}

func ==(lhs:GOLPoint,rhs:GOLPoint) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

class GOL {
    
    var width:Int
    var height:Int
    var alive = Set<GOLPoint>()
    var blackBitmapData:UnsafeMutablePointer<UInt32>
    var bitmapData:UnsafeMutablePointer<UInt32>
    var bytesPerRow:Int
    var byteCount:Int
    var colorSpace:CGColorSpace
    var bitmapInfo:CGBitmapInfo
    var processingQueue: OperationQueue
    var operations: Set<LifeOperation>
    
    init(width:Int,height:Int) {
        self.width = width
        self.height = height
        self.bytesPerRow = width * 4
        self.byteCount = bytesPerRow * height
        self.bitmapData = UnsafeMutablePointer<UInt32>.allocate(capacity: byteCount)
        self.colorSpace = CGColorSpaceCreateDeviceRGB()
        self.bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        self.blackBitmapData = UnsafeMutablePointer<UInt32>.allocate(capacity: byteCount)
        for i in 0...((width*height)-1) {
            // BGRA
            self.blackBitmapData[i] = 0x000000FF
        }
        
        self.processingQueue = OperationQueue()
        self.operations = Set<LifeOperation>()
    }
    
    func randomInitialState() {
        
        alive.removeAll(keepingCapacity: true)
        
        print("randomInitialState...\(width*height) possible points\n")
        let startTime: Date = Date()
        for i in 0...((width*height)-1) {
            if arc4random_uniform(100) > 80 {
                let point:GOLPoint = GOLPoint(x: (i % width), y: (i / width))
                alive.insert(point)
            }
        }
        let setupTime: TimeInterval = Date().timeIntervalSince(startTime)
        print("randomInitialState done... \(setupTime)s \(alive.count) points\n")
    }
    
    func initialState(start:Int) {

        // just a simple pattern to test the basic logic
        if start == 1 {
            
            alive.removeAll(keepingCapacity: true)
            alive.insert(GOLPoint(x: 2, y: 1))
            alive.insert(GOLPoint(x: 2, y: 2))
            alive.insert(GOLPoint(x: 2, y: 3))
        }
    }
    
    func tick() {
        
        let startTime = Date()
        print("sim start... \(alive.count) points\n")

        // Perform the simulation. Note there is also a parallelSimulation that uses NSOperations to perform the work.
        // It is still an experiment and isn't much faster than the linearSimuation, but I think it can be further
        // improved.
        linearSimulation()
        
        let simTime: TimeInterval = Date().timeIntervalSince(startTime)
        print("sim end... simTime:\(simTime)s \(alive.count) points\n")
        
    }
    
    func imageFromState() -> UIImage? {
        
        // Because we are sparse, go ahead and copy over the fully
        // black pixels first. Then assign the green pixels to any alive
        // states.
        memcpy(bitmapData, blackBitmapData, byteCount)
        for point:GOLPoint in alive {
            
            let index = (point.y * width) + point.x
            bitmapData[index] = 0x00FF00FF
        }
        
        let context = CGContext(data: bitmapData, width: width, height: height, bitsPerComponent: Int(8), bytesPerRow: Int(bytesPerRow), space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        if let imageRef = context?.makeImage() {
            return UIImage(cgImage: imageRef)
        } else {
            return nil
        }
    }
    
    private func linearSimulation() {
        var newAlive = Set<GOLPoint>()
        var deadToProcess = Set<GOLPoint>()
        
        let rule = GOLRule(existing: alive, width: width, height: height)
        for point:GOLPoint in alive {
            rule.processPoint(checkPoint: point)
            if rule.alive {
                newAlive.insert(point)
            }
            
            for deadPoint:GOLPoint in rule.deadNeighbors {
                deadToProcess.insert(deadPoint)
            }
        }
        
        for point:GOLPoint in deadToProcess {
            rule.processPoint(checkPoint: point)
            if rule.alive {
                newAlive.insert(point)
            }
        }
        alive = newAlive
    }
    
    private func parallelSimulation() {
        var newAlive = Set<GOLPoint>()
        
        let processingGroup = DispatchGroup()
        operations.removeAll(keepingCapacity: true)
        for point:GOLPoint in alive {
            
            processingGroup.enter()
            let operation:LifeOperation = LifeOperation(existingSet:alive,checkPoint:point,width:width,height:height)
            self.operations.insert(operation)
            operation.completionBlock = {
                processingGroup.leave()
            }
            self.processingQueue.addOperation(operation)
        }

        processingGroup.wait(timeout: .distantFuture)
        
        var deadCheckPoints = Set<GOLPoint>()
        for operation:LifeOperation in self.operations {
            if operation.alive == true {
                newAlive.insert(operation.checkPoint)
            }
            
            for point in operation.deadNeighbors {
                deadCheckPoints.insert(point)
            }
        }
        operations.removeAll(keepingCapacity: false)
        
        for point:GOLPoint in deadCheckPoints {
            
            processingGroup.enter()
            let operation:LifeOperation = LifeOperation(existingSet:alive,checkPoint:point,width:width,height:height)
            self.operations.insert(operation)
            operation.completionBlock = {
                processingGroup.leave()
            }
            self.processingQueue.addOperation(operation)
        }

        processingGroup.wait(timeout: .distantFuture)

        for operation:LifeOperation in self.operations {
            if operation.alive {
                newAlive.insert(operation.checkPoint)
            }
        }
        
        alive = newAlive
    }
}

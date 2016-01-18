//
//  Today.swift
//  Today
//
//  Created by UetaMasamichi on 2015/12/23.
//  Copyright © 2015年 Masamichi Ueta. All rights reserved.
//

import UIKit
import CoreData

public final class Today: ManagedObject {
    @NSManaged public private(set) var date: NSDate
    @NSManaged public private(set) var score: Int64
    
    public var type: TodayType {
        return Today.type(Int(score))
    }
    
    public var color: UIColor {
        return type.color()
    }
    
    public static var masterScores: [Int] {
        return scoreRange.sort {
            $0 > $1
        }
    }
    
    public static var maxScore: Int {
        return Today.masterScores.first!
    }
    
    public static var minScore: Int {
        return Today.masterScores.last!
    }
    
    public static func average(moc: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest(entityName: Today.entityName)
        request.resultType = .DictionaryResultType
        
        let keyPathExpression = NSExpression(forKeyPath: "score")
        let averageExpression = NSExpression(forFunction: "average:", arguments: [keyPathExpression])
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "averageScore"
        expressionDescription.expression = averageExpression
        expressionDescription.expressionResultType = .Integer64AttributeType
        
        request.propertiesToFetch = [expressionDescription]
        
        do {
            let objects = try moc.executeFetchRequest(request)
            let averageScore = objects[0]["averageScore"] as! Int
            return averageScore
        } catch {
            return 0
        }
    }
    
    public static func type(score: Int?) -> TodayType {
        guard let s = score else {
            return .Poor
        }
        
        let step = scoreRange.count / TodayType.count
        
        switch s {
        case 0...step:
            return .Poor
        case step+1...step*2:
            return .Fair
        case step*2+1...step*3:
            return .Average
        case step*3+1...step*4:
            return .Good
        default:
            return .Excellent
        }
    }
    
    public static func insertIntoContext(moc: NSManagedObjectContext, score: Int64) -> Today {
        let today: Today = moc.insertObject()
        today.score = score
        today.date = NSDate()
        return today
    }
}

private let scoreRange = [Int](0...10)

extension Today: ManagedObjectType {
    public static var entityName: String {
        return "Today"
    }
    
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "date", ascending: false)]
    }
}

private let redColor = "#FF3830"
private let orangeColor = "#FF9500"
private let yellowColor = "#FFCC00"
private let greenColor = "#4CD964"
private let blueColor = "#34AADC"

private let goodIconImageName = "good_face_icon_"
private let averageIconImageName = "average_face_icon_"
private let poorIconImageName = "poor_face_icon_"


public enum TodayType: String {
    case Excellent
    case Good
    case Average
    case Fair
    case Poor
    
    static let count = 5
    
    public func color() -> UIColor {
        switch self {
        case .Excellent:
            return UIColor(rgba: redColor)
        case .Good:
            return UIColor(rgba: orangeColor)
        case .Average:
            return UIColor(rgba: yellowColor)
        case .Fair:
            return UIColor(rgba: greenColor)
        case .Poor:
            return UIColor(rgba: blueColor)
        }
    }
    
    public func icon(size: String) -> UIImage {
        switch self {
        case .Excellent, .Good:
            guard let image = UIImage(named: goodIconImageName + size) else {
                fatalError("Wrong image name for good")
            }
            return image.imageWithRenderingMode(.AlwaysTemplate)
        case .Average, .Fair:
            guard let image = UIImage(named: averageIconImageName + size) else {
                fatalError("Wrong image name for average")
            }
            return image.imageWithRenderingMode(.AlwaysTemplate)
        case .Poor:
            guard let image = UIImage(named: poorIconImageName + size) else {
                fatalError("Wrong image name for poor")
            }
            return image.imageWithRenderingMode(.AlwaysTemplate)
        }
    }
}

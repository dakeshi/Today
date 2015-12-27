//
//  DataSource.swift
//  Today
//
//  Created by UetaMasamichi on 2015/12/27.
//  Copyright © 2015年 Masamichi Ueta. All rights reserved.
//

protocol DataSourceDelegate: class {
    typealias Object
    func cellIdentifierForObject(object: Object) -> String
}
//
//  TodaysTableViewController.swift
//  Today
//
//  Created by MasamichiUeta on 2015/12/13.
//  Copyright © 2015年 Masamichi Ueta. All rights reserved.
//

import UIKit
import CoreData
import TodayKit

final class TodaysTableViewController: UITableViewController, ManagedObjectContextSettable, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case ShowAddTodayViewController = "showAddTodayViewController"
    }
    
    var managedObjectContext: NSManagedObjectContext!
    
    private typealias TodaysDataProvider = FetchedResultsDataProvider<TodaysTableViewController>
    private var dataProvider: TodaysDataProvider!
    private var dataSource: TableViewDataSource<TodaysTableViewController, TodaysDataProvider, TodayTableViewCell>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        registerForiCloudNotifications()
    }
    
    deinit {
        unregisterForiCloudNotifications()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.editing = editing
        self.navigationItem.rightBarButtonItem?.enabled = !editing
    }
    
    @IBAction func cancelToTodaysTableViewController(segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func saveAddTodayViewController(segue: UIStoryboardSegue) {
        guard let vc = segue.sourceViewController as? AddTodayViewController else {
            fatalError("Wrong view controller type")
        }
        
        let now = NSDate()
        
        if Today.created(managedObjectContext, forDate: now) {
            showAddAlert(nil)
            return
        }
        
        managedObjectContext.performChanges {
            
            //Create today
            Today.insertIntoContext(self.managedObjectContext, score: Int64(vc.score), date: now)
            
            //Update current streak or create a new streak
            if let currentStreak = Streak.currentStreak(self.managedObjectContext) {
                currentStreak.to = now
            } else {
                Streak.insertIntoContext(self.managedObjectContext, from: now, to: now)
            }
        }
        
    }
    
    @IBAction func showAddTodayViewController(sender: AnyObject) {
        if Today.created(managedObjectContext, forDate: NSDate()) {
            showAddAlert(nil)
        } else {
            performSegue(.ShowAddTodayViewController)
        }
    }
    
    private func setupTableView() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        setupDataSource()
    }
    
    private func setupDataSource() {
        let request = Today.sortedFetchRequest
        request.returnsObjectsAsFaults = false
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        dataProvider = FetchedResultsDataProvider(fetchedResultsController: frc, delegate: self)
        dataSource = TableViewDataSource(tableView: tableView, dataProvider: dataProvider, delegate: self)
        
        let noDataLabel = PaddingLabel(frame: CGRect(origin: tableView.bounds.origin, size: tableView.bounds.size))
        noDataLabel.text = localize("Let's start Today!")
        noDataLabel.textColor = UIColor.grayColor()
        noDataLabel.font = UIFont.systemFontOfSize(28)
        noDataLabel.textAlignment = .Center
        noDataLabel.numberOfLines = 2
        dataSource.noDataView = noDataLabel
    }
    
    private func showAddAlert(completion: (() -> Void)?) {
        let alert = UIAlertController(title: localize("Wow!"), message: localize("Everything is OK. \nYou have already created Today."), preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: localize("OK"), style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: completion)
    }
}

//MARK: - UITableViewDelegate
extension TodaysTableViewController {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("cell did select")
    }
}

//MARK: - AugmentedDataProviderDelegate
extension TodaysTableViewController: DataProviderDelegate {
    func dataProviderDidUpdate(updates: [DataProviderUpdate<Today>]?) {
        dataSource.processUpdates(updates)
    }
}

//MARK: - TableViewDataSourceDelegate
extension TodaysTableViewController: TableViewDataSourceDelegate {
    func cellIdentifierForObject(object: Today) -> String {
        return "TodayCell"
    }
    
    func canEditRowAtIndexPath(indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func didEditRowAtIndexPath(indexPath: NSIndexPath, commitEditingStyle editingStyle: UITableViewCellEditingStyle) {
        switch editingStyle {
        case .Delete:
            let today: Today = dataProvider.objectAtIndexPath(indexPath)
            managedObjectContext.performChanges {
                self.managedObjectContext.deleteObject(today)
            }
            Streak.updateStreak(managedObjectContext, forDate: today.date)
        default:
            break
        }
    }
}

//MARK: - iCloudRegistable
extension TodaysTableViewController: ICloudRegistable {
    func ubiquitousKeyValueStoreDidChangeExternally(notification: NSNotification) {
        
    }
    
    func storesWillChange(notification: NSNotification) {
        
    }
    
    func storesDidChange(notification: NSNotification) {
        setupTableView()
        tableView.reloadData()
    }
    
    func persistentStoreDidImportUbiquitousContentChanges(notification: NSNotification) {
        
    }
}
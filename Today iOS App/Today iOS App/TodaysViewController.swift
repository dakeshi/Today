//
//  TodaysViewController.swift
//  Today
//
//  Created by UetaMasamichi on 9/3/16.
//  Copyright © 2016 Masamichi Ueta. All rights reserved.
//

import UIKit
import TodayKit
import CoreData
import Social

class TodaysViewController: UIViewController {
    
    var moc: NSManagedObjectContext!
    var frc: NSFetchedResultsController<Today>!

    @IBOutlet weak var calendarView: RSDFDatePickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCalendarView()
        
        self.moc = CoreDataManager.shared.persistentContainer.viewContext
        let request: NSFetchRequest<Today> = Today.fetchRequest()
        request.sortDescriptors = Today.defaultSortDescriptors
        self.frc = NSFetchedResultsController<Today>(fetchRequest: request, managedObjectContext: self.moc, sectionNameKeyPath: nil, cacheName: nil)
        self.frc.delegate = self
        
        do {
            try self.frc.performFetch()
        } catch {
            fatalError()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func configureCalendarView() {
        self.calendarView.delegate = self
        self.calendarView.dataSource = self
        let topInset = self.navigationController?.navigationBar.frame.height ?? 44.0
        self.calendarView.contentInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    }
    
    @IBAction func scrollToTodayButtonDidTap(_ sender: AnyObject) {
        self.calendarView.scroll(toToday: true)
    }
    
    @IBAction func cancelToTodaysViewController(_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func saveAddTodayViewController(_ segue: UIStoryboardSegue) {
        guard let vc = segue.source as? AddTodayViewController else {
            fatalError("Wrong view controller type")
        }
        
        let now = Date()
        
        if Today.created(moc, forDate: now) {
            showAddAlert(nil)
            return
        }
        
        moc.performAndWait {
            //Create today
            let _ = Today.insertIntoContext(self.moc, score: Int64(vc.score), date: now)
            let _ = Streak.updateOrCreateCurrentStreak(self.moc, date: now)
            
            do {
                try self.moc.save()
            } catch {
                self.moc.rollback()
            }
        }
    }
    
    @IBAction func showAddTodayViewController(_ sender: AnyObject) {
        if Today.created(moc, forDate: Date()) {
            showAddAlert(nil)
        } else {
            performSegue(withIdentifier: "showAddTodayViewController", sender: self)
        }
    }
    
    fileprivate func showAddAlert(_ completion: (() -> Void)?) {
        let alert = UIAlertController(title: localize("Wow!"), message: localize("Everything is OK. \nYou have already created Today."), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localize("OK"), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: completion)
    }
}

extension TodaysViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.calendarView.reloadData()
    }
}

extension TodaysViewController: RSDFDatePickerViewDelegate, RSDFDatePickerViewDataSource {
    func datePickerView(_ view: RSDFDatePickerView, shouldHighlight date: Date) -> Bool {
        return true
    }
    
    func datePickerView(_ view: RSDFDatePickerView, shouldSelect date: Date) -> Bool {
        return true
    }
    
    func datePickerView(_ view: RSDFDatePickerView, didSelect date: Date) {
        if let today = Today.today(moc, date: date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            
            let alert = UIAlertController(title: dateFormatter.string(from: date), message: nil, preferredStyle: .actionSheet)
            
            if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook) {
                alert.addAction(UIAlertAction(title: localize("Share to Facebook"), style: .default, handler: { action in
                    let vc = SLComposeViewController(forServiceType: SLServiceTypeFacebook)!
                    vc.setInitialText(localize("Today's Score is \(today.score)"))
                    let image = Today.type(Int(today.score)).icon(.hundred)
                    vc.add(image)
                    vc.add(URL(string: "http://uetamasamichi.com/TodayWeb/"))
                    self.present(vc, animated: true, completion: nil)
                }))
            }
            
            if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter) {
                alert.addAction(UIAlertAction(title: localize("Share to Twitter"), style: .default, handler: { action in
                    let vc = SLComposeViewController(forServiceType: SLServiceTypeTwitter)!
                    vc.setInitialText(localize("Today's Score is \(today.score)"))
                    let image = Today.type(Int(today.score)).icon(.hundred)
                    vc.add(image)
                    vc.add(URL(string: "http://uetamasamichi.com/TodayWeb/"))
                    self.present(vc, animated: true, completion: nil)
                }))
            }
            
            alert.addAction(UIAlertAction(title: localize("Delete"), style: .destructive, handler: { action in
                self.moc.performAndWait {
                    self.moc.delete(today)
                    let _ = Streak.updateOrCreateCurrentStreak(self.moc, date: date)
                    
                    do {
                        try self.moc.save()
                    } catch {
                        self.moc.rollback()
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: localize("Cancel"), style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func datePickerView(_ view: RSDFDatePickerView, shouldMark date: Date) -> Bool {
        
        let today = self.frc.fetchedObjects?.filter { today in
            Calendar.current.isDate(today.date, inSameDayAs: date)
        }
        
        return today?.count == 0 ? false : true
    }
    
    func datePickerView(_ view: RSDFDatePickerView, markImageFor date: Date) -> UIImage? {
        
        let today = self.frc.fetchedObjects?.filter { today in
            Calendar.current.isDate(today.date, inSameDayAs: date)
        }
        
        return today?.first?.type.icon(.twentyEight)
        
    }
    
    
}

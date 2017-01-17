//
//  FetchViewController.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 10.01.2017.
//
//

import UIKit
import CoreData

protocol FakeFetchProtocol {}
private var xoAssociationKey: UInt8 = 0

extension UIViewController: FakeFetchProtocol {

    private struct FetchData {
        var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>
        var tableView: UITableView?
    }
    
    private var fetchData: [FetchData]? {
        get {
            return objc_getAssociatedObject(self, &xoAssociationKey) as? [FetchData]
        }
        set {
            objc_setAssociatedObject(self, &xoAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    open func addFetchedResultsController(_ clazz: AnyClass, sortDescription: [NSSortDescriptor]? = nil, predicate: NSPredicate? = nil, tableView: UITableView? = nil) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let entityName = NSStringFromClass(clazz)
        guard let fetchedResultsController = DatabaseHelper.sharedInstance.createFetchedResultController(entityName, sortDescriptor: sortDescription, predicate: predicate) else {
            return nil
        }
        
        if let delegate = self as? NSFetchedResultsControllerDelegate {
            fetchedResultsController.delegate = delegate
        }
        
        do {
            try fetchedResultsController.performFetch()
        } catch { }

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

        if fetchData == nil {
            fetchData = [FetchData]()
        }
        
        fetchData?.append(FetchData(fetchedResultsController: fetchedResultsController, tableView: tableView))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let tableView = tableView {
                tableView.reloadData()
            }
        }
        
        return fetchedResultsController
    }
    
    open func appDidBecomeActive(_ notification: Notification) { }
    
    open func appWillEnterForeground(_ notification: Notification) { }
    
    open func setPredicate(predicate: NSPredicate?, for controller: NSFetchedResultsController<NSFetchRequestResult>) {
        controller.fetchRequest.predicate = predicate
        do {
            try controller.performFetch()
            tableView(forController: controller)?.reloadData()
        } catch {}
    }

    open func setSort(descriptors: [NSSortDescriptor]?, for controller: NSFetchedResultsController<NSFetchRequestResult>) {
        controller.fetchRequest.sortDescriptors = descriptors
        do {
            try controller.performFetch()
            tableView(forController: controller)?.reloadData()
        } catch {}
    }

    private func tableView(forController controller: NSFetchedResultsController<NSFetchRequestResult>) -> UITableView? {
        if let data = fetchData?.first(where: { $0.fetchedResultsController == controller }), let tableView = data.tableView {
            return tableView
        }
        
        return nil
    }
    
    // MARK: - NSFetchedResultControllerDelegate
    
    open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let tableView = tableView(forController: controller) {
            tableView.beginUpdates()
        }
    }
    
    @objc(controller:didChangeSection:atIndex:forChangeType:) open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        if let tableView = tableView(forController: controller) {
            switch type {
            case .insert:
                tableView.insertSections([sectionIndex], with: .fade)
            case .delete:
                tableView.deleteSections([sectionIndex], with: .fade)
            default: break
            }
        }
    }
    
    @objc(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:) open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let tableView = tableView(forController: controller) {
            switch type {
            case .insert:
                if let newIndexPath = newIndexPath {
                    tableView.insertRows(at: [newIndexPath], with: .fade)
                }
            case .delete:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            case .update:
                if let indexPath = indexPath {
                    tableView.reloadRows(at: [indexPath], with: .fade)
                }
            case .move:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
                if let newIndexPath = newIndexPath {
                    tableView.insertRows(at: [newIndexPath], with: .fade)
                }
            }

        }
    }
    
    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let tableView = tableView(forController: controller) {
            tableView.endUpdates()
        }
    }
    
}

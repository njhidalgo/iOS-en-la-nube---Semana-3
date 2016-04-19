//
//  MasterViewController.swift
//  buscadorLibrosTablas
//
//  Created by Nahim Jesus Hidalgo Sabido on 4/18/16.
//  Copyright © 2016 Nahim Jesus Hidalgo Sabido. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "buscarLibro:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    func buscarLibro(sender: AnyObject) {
        
        //1. Se crea el Alert Controller
        var alert = UIAlertController(title: "Mensaje", message: "Ingresa un ISBN", preferredStyle: .Alert)
        
        //2. Se agrega el campo de texto
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            
        })
        
        //3. Se agrega la accion al boton
        alert.addAction(UIAlertAction(title: "Buscar", style: .Default, handler: { (action) -> Void in
            
            let textField = alert.textFields![0] as UITextField
            
            let urls = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:\(textField.text!)"
            let url = NSURL(string: urls)
            let datos: NSData? = NSData(contentsOfURL: url!)
            
            if datos == nil{
                
                let alertaProblemaInternet = UIAlertController(title: "Error", message: "Existe una falla en internet. Verifique su conexion y vuelva a intentar", preferredStyle: UIAlertControllerStyle.Alert)
                alertaProblemaInternet.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertaProblemaInternet, animated: true, completion: nil)
                
            }else{
                
                let texto = NSString(data: datos!, encoding: NSUTF8StringEncoding)
                if texto == "{}"{
                    
                    let alertaIsbnInexistente = UIAlertController(title: "Error", message: "El ISBN ingresado no se encuentro en el sistema.", preferredStyle: UIAlertControllerStyle.Alert)
                    alertaIsbnInexistente.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alertaIsbnInexistente, animated: true, completion: nil)
                    
                }else{
                    
                    do{
                        
                        let context = self.fetchedResultsController.managedObjectContext
                        let entity = self.fetchedResultsController.fetchRequest.entity!
                        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context)
                        
                        //JSON GENERAL
                        let json = try NSJSONSerialization.JSONObjectWithData(datos!, options: []) as! [String:AnyObject]
                        
                        //SE OBTIENE EL TITULO DEL LIBRO
                        let title = json["ISBN:\(textField.text!)"]!["title"] as! String
                        
                        newManagedObject.setValue(title, forKey: "titulo")
                        
                        //SE OBTIENEN LOS AUTORES
                        let dicAutores = json["ISBN:\(textField.text!)"]!["authors"] as! [[String:AnyObject]]
                        
                        var autores: String = String()
                        
                        for autor in dicAutores{
                            //print(autor["name"] as! String)
                            
                            autores += autor["name"] as! String
                            
                            if dicAutores.count > 1{
                                
                                autores += " - "
                                
                            }
                            
                        }
                        
                        //autoresLabel.text = autores
                        newManagedObject.setValue(autores, forKey: "autores")
                        
                        let urls = "http://covers.openlibrary.org/b/isbn/\(textField.text!)-M.jpg"
                        let url = NSURL(string: urls)
                        let datos: NSData? = NSData(contentsOfURL: url!)
                
                        let image: UIImage = UIImage(data:datos!,scale:1.0)!
                        let imagePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
                        let destinationPath = imagePath.stringByAppendingString("/\(title).jpg")
                        UIImageJPEGRepresentation(image, 1)?.writeToFile(destinationPath, atomically: true)

                        newManagedObject.setValue(destinationPath, forKey: "portada")
                        newManagedObject.setValue(NSDate(), forKey: "timeStamp")
                        
                        // Save the context
                        do {
                            try context.save()
                            
                            let firstIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                        
                            self.tableView.selectRowAtIndexPath(firstIndexPath, animated: true, scrollPosition: .None)
                        
                            self.performSegueWithIdentifier("showDetail", sender: nil)
                            
                            
                        } catch {
                            // Replace this implementation with code to handle the error appropriately.
                            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                            //print("Unresolved error \(error), \(error.userInfo)")
                            abort()
                        }
                        
                    }
                    catch {
                        
                        print("json error: \(error)")
                        
                    }
                }
                
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .Cancel, handler: { (action) -> Void in
            
        }))
        
        // 4. Present the alert.
        self.presentViewController(alert, animated: true, completion: nil)
        
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
        self.configureCell(cell, withObject: object)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
                
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //print("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }

    func configureCell(cell: UITableViewCell, withObject object: NSManagedObject) {
        cell.textLabel!.text = object.valueForKey("titulo")!.description
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Event", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             //print("Unresolved error \(error), \(error.userInfo)")
             abort()
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, withObject: anObject as! NSManagedObject)
            case .Move:
                tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         self.tableView.reloadData()
     }
     */

}


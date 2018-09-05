//
//  DatabaseCalls.swift
//  ShahtajNetSecTest
//
//  Created by Shahtaj Khalid on 8/11/18.
//  Copyright © 2018 Shahtaj Khalid. All rights reserved.
//

import Foundation
import CoreData
import UIKit



public class DatabaseCalls : NSManagedObject {
    
    // To save the Temperature
    let defaults = UserDefaults.standard
    
    class func getContext () -> NSManagedObjectContext {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.managedObjectContext// appDelegate.persistentContainer.viewContext
        
    }
    
    
    class func Save_Windwos_Version_Details(BuildVersion: String,softwareVersion: String,postCompleted : @escaping (_ succeeded: Bool, _ msg: String) -> ())
    {
        let context = getContext()//getContext()
        
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = context
        
        privateMOC.perform {
            
            let transc = NSEntityDescription.insertNewObject(forEntityName: "Windows", into: privateMOC)
            
            
            transc.setValue(BuildVersion, forKey: "buildVersion")
            transc.setValue(softwareVersion, forKey: "softwareVersion")
           
            
            do {
                try privateMOC.save()
                context.performAndWait {
                    do {
                        try context.save()
                        print("Data Saved!")
                        postCompleted(true, "Saved")
                        
                    } catch {
                        let nserror = error as NSError
                        fatalError("Failure to save context: \(nserror)")//error
                        
                    }
                }
                
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
                postCompleted(false, "Failure")
            } catch {
                
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                
            }
        }
    }
    
    
}
extension UIViewController {
    
    func showToast(message : String, width1:CGFloat) {
        
        //  self.view.frame.size.width/2 - 75
        let toastLabel = UILabel(frame: CGRect(x: (self.view.frame.size.width - width1) / 2 , y: self.view.frame.size.height-100, width: width1, height: 25))
        
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration:4.0, delay: 0.0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}
open class Extensions {
    
    
    
    class func ShowAlert(_ alert: UIAlertController,sender: AnyObject)
    {
        alert.view.tintColor = UIColor.black
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(10, 5, 50, 50)) as UIActivityIndicatorView
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        sender.present(alert, animated: true, completion: nil)//
    }
    
    class func HideAlert(_ alert: UIAlertController)
    {
        alert.dismiss(animated: true, completion: nil)
    }
    
    class func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    class func InternetConnectionAlert(sender : AnyObject)
    {
        let alertController = UIAlertController(title: "Warning", message: "Please Connect To The Internet!", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction!) in
            
        }
        alertController.addAction(cancelAction)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
            
        }
        alertController.addAction(OKAction)
        
        sender.present(alertController, animated: true, completion:nil)
    }
    
    class func AlertBox(title:String,msg : String, sender : AnyObject)
    {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
        }
        alertController.addAction(OKAction)
        sender.present(alertController, animated: true, completion:nil)
    }
    
    class func callController(sender:AnyObject,controllername:String){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let ViewController = storyBoard.instantiateViewController(withIdentifier: controllername)
        sender.present(ViewController, animated:true, completion:nil)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboardView))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboardView() {
        view.endEditing(true)
    }
}

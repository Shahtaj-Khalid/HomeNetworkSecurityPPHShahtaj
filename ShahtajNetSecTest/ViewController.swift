//
//  ViewController.swift
//  ShahtajNetSecTest
//
//  Created by Shahtaj Khalid on 8/3/18.
//  Copyright © 2018 Shahtaj Khalid. All rights reserved.
//

import UIKit
import CoreData


class ViewController: UIViewController,MainPresenterDelegate,UITableViewDelegate,UITableViewDataSource{
  
    
    @IBOutlet weak var tableV: UITableView!
    @IBOutlet weak var navigationBarTitle: UINavigationItem!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var tableVTopContraint: NSLayoutConstraint!
    @IBOutlet weak var scanButton: UIBarButtonItem!
    @IBOutlet weak var ScanBtnOutlet: UIButton!
    //
    private var myContext = 0
    var presenter: MainPresenter!
    
    @IBOutlet weak var TotalDeviceCount: UILabel!
    @IBOutlet weak var LastUpdateTime: UILabel!
    
     let pwait = UIAlertController(title: nil, message: "Loading ... ", preferredStyle: .alert)
    var sharedController: SNMPController?
    private var snmp: XISMobile_SNMP_PP?
    
    let queue = DispatchQueue(label: "Shahtaj_queue")
    
    var HostNames_Arr:[String] = []
    var IPs_Arr:[String] = []
    var Host_Company_Arr:[String] = []
    
    var sysDescrString:[String] = []
    var querySuccess:[Bool] = []
    
    // SAVING THE Windows and MAC Versions
    
    let windowsVersionDictionary = ["17134":"10","16299":"10","15063":"10","14393":"10","10586":"10","10240":"10",
                   "9600":"8.1",//,"9200":"8.1",
                   "9200":"8",
                   "7601":"7","7600":"7",
                   "6002":"Vista","6001":"Vista","6000":"Vista",
                   "26003":"XP"
                   ]
    var Latest_Windows_Version = "10"
    
    let Mac_VersionDictionary = ["17":"MacOS 10.13 High Sierra",
                                 "16":"MacOS 10.12 Sierra",
                                 "15":"OS X  10.11 El Capitan",
                                 "14":"OS X  10.10 Yosemite",
                                 "13":"OS X  10.9  Mavericks",
                                 "12":"OS X  10.8  Mountain Lion",
                                 "11":"OS X  10.7  Lion",
                                 "10":"OS X  10.6  Snow Leopard",
                                 "9":"OS X  10.5  Leopard",
                                 "8":"OS X  10.4  Tiger",
                                 "7":"OS X  10.3  Panther",
                                 "6":"OS X  10.2  Jaguar",
                                 "5":"OS X  10.1  Puma"
    ]
    
     var Latest_Mac_BuildVersion = "17"

    var currentDevice_is_Mac_OR_Windows = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        print("Windows dict compare = ", windowsVersionDictionary)
        print("Mac dict compare = ",Mac_VersionDictionary)
        let sorted = Mac_VersionDictionary.sorted {$00.key < $01.key}  // or {$0.value < $1.value} to sort using the dictionary values
        print(sorted)
        
        // SETUPSSS
        
        // Call the SNMPController and create our shared controller
        sharedController = SNMPController.sharedController()
       
        //Init presenter. Presenter is responsible for providing the business logic of the MainVC (MVVM)
        self.presenter = MainPresenter(delegate:self)
        
        //Add observers to monitor specific values on presenter. On change of those values MainVC UI will be updated
        self.addObserversForKVO()
        
        
      /* for (key,value) in windowsVersionDictionary {
        DatabaseCalls.Save_Windwos_Version_Details(BuildVersion: key, softwareVersion: value)
        { (succeeded: Bool, msg: String) -> () in
            DispatchQueue.main.async(execute: { () -> Void in
                if(succeeded == true){
                   print("Windows Data Saved!!")
                }else{
                   
                }
            })
            }
        }*/ // Commenting out the Local database storing part..
        
    }
    
    @IBAction func RefreshScan_Action(_ sender: Any) {
     self.BtnClickedTask()
    }
    @IBAction func RefreshScanBtn_Action(_ sender: Any) {
       self.BtnClickedTask()
     }
    
    func BtnClickedTask(){
        DispatchQueue.main.async(execute: { () -> Void in
             self.showProgressBar()
        })
 
        self.navigationBarTitle.title = self.presenter.ssidName()
        self.presenter.scanButtonClicked()
    }
    //MARK: - KVO Observers
    func addObserversForKVO ()->Void {
        
        self.presenter.addObserver(self, forKeyPath: "connectedDevices", options: .new, context:&myContext)
        self.presenter.addObserver(self, forKeyPath: "progressValue", options: .new, context:&myContext)
        self.presenter.addObserver(self, forKeyPath: "isScanRunning", options: .new, context:&myContext)
    }
    
    func removeObserversForKVO ()->Void {
        
        self.presenter.removeObserver(self, forKeyPath: "connectedDevices")
        self.presenter.removeObserver(self, forKeyPath: "progressValue")
        self.presenter.removeObserver(self, forKeyPath: "isScanRunning")
    }
    
    //MARK: - Show/Hide Progress Bar
    func showProgressBar()->Void {
      
        self.TotalDeviceCount.text = ""
       self.TotalDeviceCount.text = "Loading..."
        UIView.animate(withDuration: 0.5, animations: {
            
            self.tableVTopContraint.constant = 40
            self.view.layoutIfNeeded()
        }, completion: nil)
      
    }
    
    
    func hideProgressBar()->Void {
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.tableVTopContraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.progressView.progress = 0
        })
    }
    
    //MARK: - Presenter Delegates
    //The delegates methods from Presenters.These methods help the MainPresenter to notify the MainVC for any kind of changes
    func mainPresenterIPSearchFinished() {
         DispatchQueue.main.async(execute: { () -> Void in
        self.hideProgressBar()
        self.showAlert(title: "Scan Finished", message: "Number of devices connected to the Local Area Network : \(self.presenter.connectedDevices.count)")
          self.TotalDeviceCount.text = String(self.presenter.connectedDevices.count) + " Devices"
        self.ScanBtnOutlet.setTitle("Run Scan Again", for: .normal)
        })
        
        sysDescrString.removeAll()
        self.LoadingValuesFromSacnning()
      
        self.tableV.reloadData()
    }
    
    func mainPresenterIPSearchCancelled() {
         DispatchQueue.main.async(execute: { () -> Void in
        self.hideProgressBar()
        self.tableV.reloadData()
        })
    }
    
    func mainPresenterIPSearchFailed() {
         DispatchQueue.main.async(execute: { () -> Void in
        self.hideProgressBar()
        self.showAlert(title: "Failed to scan", message: "Please make sure your internet is connected before starting the Scan!")
        })
    }
    
    //MARK: - Alert Controller
    func showAlert(title:String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in}
        
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - UITableView Delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.presenter.connectedDevices!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceCell
        
      DispatchQueue.main.async(execute: { () -> Void in
            
        let device = self.presenter.connectedDevices[indexPath.row]
        
        var error: Error?
     
        
       
        if !device.isLocalDevice {
     
            DispatchQueue.main.async(execute: { () -> Void in
     
            if error == nil || self.querySuccess[indexPath.row] {
           // NO Error
                print("FINAL DESCPTION = ", self.sysDescrString[indexPath.row])
            
            // SPLITING AND MERGING
            if self.sysDescrString[indexPath.row].contains("Windows"){
                let Current_build_Number = self.sysDescrString[indexPath.row].slice(from: "Build", to: "Multiprocessor")?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            print("Current_build_Number for windows = \(Current_build_Number)")
            //
            // Now Searching
                for character in self.windowsVersionDictionary {
                    if character.key == Current_build_Number {
                      print(character.value)
                        cell.softwareVersionLabel.text = "Windows " + character.value
                        self.currentDevice_is_Mac_OR_Windows = "windows"
                        
                       // if self.windowsVersionDictionary.values.first == character.value {
                        if self.Latest_Windows_Version == character.value {
                            cell.softwareVersionLabel.textColor = UIColor.green
                        }else{
                            cell.softwareVersionLabel.textColor = UIColor.red
                        }
                    }
                }
            }else
                if self.sysDescrString[indexPath.row].contains("Darwin"){
                    let Current_build_Number = self.sysDescrString[indexPath.row].slice(from: "Darwin Kernel Version", to: ":")?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    print("Current_build_Number for Mac = \(Current_build_Number)")
                    let get = Current_build_Number?.components(separatedBy: ".")
                    let mainVersion = get![0]
                    //
                    // Now Searching
                    for character in self.Mac_VersionDictionary {
                        if character.key == mainVersion {
                            print(character.value)
                            cell.softwareVersionLabel.text = character.value
                            self.currentDevice_is_Mac_OR_Windows = "mac"
                           
                           // if self.Mac_VersionDictionary.values.first == character.value {
                            if self.Latest_Mac_BuildVersion == character.key {
                                cell.softwareVersionLabel.textColor = UIColor.green
                            }else{
                                cell.softwareVersionLabel.textColor = UIColor.red
                            }
                        }
                    }
                }
                else{
            cell.softwareVersionLabel.text = ""//sysDescrString //device.macAddress
                    self.currentDevice_is_Mac_OR_Windows = ""
            }
        }else{
            cell.softwareVersionLabel.text = "" // snmp not enables on host device
             self.currentDevice_is_Mac_OR_Windows = ""
            }
           
            let Devicebrand = device.brand?.components(separatedBy: ",")
            let DevicebrandMain = Devicebrand![0]
            
            if device.hostname != nil {
                
            if device.hostname.contains("android"){
                cell.modelNameLabel.text = "Android"
                cell.DeviceIconImage.image = UIImage(named: "icons8-android-filled-50")
               
            }else
            if device.hostname.contains("ipad"){
                cell.modelNameLabel.text = "iPad"
                cell.DeviceIconImage.image = UIImage(named: "icons8-ipad-filled-50")
            }else
            if self.currentDevice_is_Mac_OR_Windows == "mac" {
                    cell.modelNameLabel.text = "Mac"
                    cell.DeviceIconImage.image = UIImage(named: "icons8-macbook-50")
            }else
            if device.hostname.contains("desktop"){
                cell.modelNameLabel.text = device.macAddress
                cell.DeviceIconImage.image = UIImage(named: "icons8-laptop-filled-50")
                    
            }else
            if device.hostname.contains("iphone"){
                cell.modelNameLabel.text = "iPhone"
                cell.DeviceIconImage.image = UIImage(named: "icons8-iphone-filled-50")

            }else{
                cell.modelNameLabel.text = device.macAddress
                cell.DeviceIconImage.image = UIImage(named: "generic")
                }
                
            }else{
                cell.DeviceIconImage.image = UIImage(named: "generic")
            }
            cell.ipLabel.text = device.ipAddress
            cell.hostnameLabel.text = device.hostname
            cell.brandLabel.text = DevicebrandMain
            
            cell.MeIconImage.image = UIImage(named: "")
        })
        }else{
            cell.MeIconImage.image = UIImage(named: "icons8-user-filled-50")
            cell.ipLabel.text = device.ipAddress
            cell.hostnameLabel.text = device.hostname
            cell.brandLabel.text =  "Apple"//"Your device: " + UIDevice.current.model
            cell.modelNameLabel.text = UIDevice.current.model
            cell.softwareVersionLabel.text = "iOS " + UIDevice.current.systemVersion
            if UIDevice.current.model == "iPad"{
                cell.modelNameLabel.text = "iPad"
                cell.DeviceIconImage.image = UIImage(named: "icons8-ipad-filled-50")
            }
            if UIDevice.current.model == "iPhone"{
                    cell.modelNameLabel.text = "iPhone"
                    cell.DeviceIconImage.image = UIImage(named: "icons8-iphone-filled-50")
            }
            if UIDevice.current.systemVersion.compare("11.4", options: .numeric) != ComparisonResult.orderedAscending {
                cell.softwareVersionLabel.textColor = UIColor.green
            }else{
                cell.softwareVersionLabel.textColor = UIColor.red
            }
        }
        })
        return cell
        
    }
    
    //MARK: - KVO
    //This is the KVO function that handles changes on MainPresenter
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (context == &myContext) {
            
            switch keyPath! {
            case "connectedDevices":
                print("Testing")
             //   self.tableV.reloadData()
            case "progressValue":
                self.progressView.progress = self.presenter.progressValue
            case "isScanRunning":
                let isScanRunning = change?[.newKey] as! BooleanLiteralType
                self.scanButton.image = isScanRunning ? #imageLiteral(resourceName: "stop") : #imageLiteral(resourceName: "refresh")
            default:
                print("Not valid key for observing")
            }
        }
    }
    
    //MARK: - Deinit
    deinit {
        
        self.removeObserversForKVO()
    }
    
    
    func LoadingValuesFromSacnning(){
        
        print("Connected Devices Count = ",self.presenter.connectedDevices.count)
        var error:[Error] = []
      //  var sysDescrString:[String] = []
      //  var querySuccess:[Bool] = []
        
        for var i in (0..<self.presenter.connectedDevices.count)
        {
            let device = self.presenter.connectedDevices[i]
            
            sysDescrString.append(try! self.sharedController!.sysDescription("sysDescrString", forHost: device.ipAddress))
          
        }
       
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   
}

class DeviceCell: UITableViewCell {
    
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var softwareVersionLabel: UILabel!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var hostnameLabel: UILabel!
    @IBOutlet weak var modelNameLabel: UILabel!
    @IBOutlet weak var MeIconImage: UIImageView!
    @IBOutlet weak var DeviceIconImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
extension String {
    
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

//
//  MedicineTableViewController.swift
//  CoreDataTest
//
//  Created by James Klein on 4/24/15.
//  Copyright (c) 2015 James Klein. All rights reserved.
//

import UIKit

class MedicineTableViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    //handle datastore calls delegage
    var dataStoreDelegate: ProfileDataStoreDelegate!

    var selectedIndex: Int?

    var isUpdate = false
    var medicineToUpdate: OPMedicine?
    
    @IBOutlet weak var prescribedTimeUIPicker: UIPickerView!
    @IBOutlet weak var medicineUIPicker: UIPickerView!
    override func viewDidLoad() {
        super.viewDidLoad()

        prescribedTimeUIPicker.delegate = self
        prescribedTimeUIPicker.dataSource = self
        medicineUIPicker.delegate = self
        medicineUIPicker.dataSource = self
        
        if isUpdate {
            
            let sb = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "doneButtonTapped_Update")
            self.navigationItem.rightBarButtonItem = sb
            
            prescribedTimeUIPicker.selectRow(medicineToUpdate!.targetTimePeriodToTake.integerValue, inComponent: 0, animated: false)
            medicineUIPicker.selectRow(medicineToUpdate!.name.integerValue, inComponent: 0, animated: false)

        } else {
            let sb = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "doneButtonTapped_Add")
            self.navigationItem.rightBarButtonItem = sb
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //if pickerView
        let x = pickerView.tag
        if x == 0{
            return Medicines.count()
        } else{
            return PrescribedTimeForAction.count()
        }
    }
    
    //MARK: Delegates
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let x = pickerView.tag
        if x == 0{
            return Medicines(rawValue: row)?.name
        } else{
            return PrescribedTimeForAction(rawValue: row)?.name()
                   }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //myLabel.text = pickerData[row]
    }

    
    func doneButtonTapped_Add()
    {
        let medSelection = medicineUIPicker.selectedRowInComponent(0)
        let timeSelection = prescribedTimeUIPicker.selectedRowInComponent(0)
        let result = dataStoreDelegate.addMedicine( medSelection, prescribedTimeForAction: timeSelection)
        if let _ = result.medObject {
            //no errors
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            if result.errorArray.count > 0 {
                let errorMessages = result.errorArray.map{$0.rawValue}
                displayErrorAlert("Medicine Item", messages: errorMessages)
            }
        }
    }
    func doneButtonTapped_Update()
    {
        let medSelection = medicineUIPicker.selectedRowInComponent(0)
        let timeSelection = prescribedTimeUIPicker.selectedRowInComponent(0)
        let result = dataStoreDelegate.updateMedicine(selectedIndex!, medicine: medSelection, prescribedTimeForAction: timeSelection)
        if let _ = result.medObject {
            //no errors
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            if result.errorArray.count > 0 {
                let errorMessages = result.errorArray.map{$0.rawValue}
                displayErrorAlert("Medicine Item", messages: errorMessages)
            }
        }

    }
 
}

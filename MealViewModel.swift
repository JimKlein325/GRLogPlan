//
//  MealViewModel.swift
//  GRPatienLogAndPlan
//
//  Created by James Klein on 5/11/15.
//  Copyright (c) 2015 ObjectPrism Corp. All rights reserved.
//

import Foundation

//add protocols
//add enum declarations

protocol MealViewModelDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    func didDeselectRowAtIndexPath (indexPath: NSIndexPath, viewController: UIViewController, choiceTableCell: NewChoiceTableViewCell?)
    func saveButtonTapped()
    
    weak var tableView: UITableView! {get set}
    weak var tableviewController: UITableViewController! {get set}

}

public class MealViewModel: NSObject {
    weak var tableView: UITableView!
    weak var tableviewController: UITableViewController!
    let dataStore: DataStore
    var choiceCellSelectedState: Bool = false
    //Used in displaying current or default meal time
    var parentViewControllerIsHomeViewController = false
    var defaultMealTime: String?
    
    init(dataStore: DataStore){
        self.dataStore = dataStore
    }
    
    
    //MARK:  Cell For Row At Index Path Helpers
    func tableCell(tableView: UITableView, cellForFoodItemAtIndexPath indexPath: NSIndexPath, inArray choicesArray: [FoodItem], foodItemName: String?, viewModel: ChoiceItemSelectedDelegate?) -> UITableViewCell
    {
        let currentItem = choicesArray[indexPath.row]
        
        if let itemWithChoice = currentItem as? FoodItemWithChoice {
            let cell = tableView.dequeueReusableCellWithIdentifier(NewChoiceTableViewCell.cellIdentifier, forIndexPath: indexPath) as! NewChoiceTableViewCell
            cell.choiceLabel?.text = itemWithChoice.itemDescription
            cell.choiceSegmentControl.selectedSegmentIndex = -1
            cell.indexPath = indexPath
                
            let segControl = cell.choiceSegmentControl as UISegmentedControl
                
            segControl.removeAllSegments()
            
            for i in 0 ..< itemWithChoice.choiceItems.count {
                if i  < 2 {
                    let choiceItem = itemWithChoice.choiceItems[i]
                    segControl.insertSegmentWithTitle(choiceItem.itemDescription, atIndex: i, animated: false)

                    // cell size apportionament, used below, requires cell to have width = 0
                    segControl.setWidth(0, forSegmentAtIndex: i)
                }
                else{
                    segControl.insertSegmentWithTitle(itemWithChoice.choiceItems[i].itemDescription, atIndex: i, animated: false)
                    segControl.setWidth(0, forSegmentAtIndex: i)
                }
            }
            
            if foodItemName != nil {
                
                let myArray: [String] = foodItemName!.componentsSeparatedByString(",")
                let choiceItemIndex = myArray.last ?? "-1"
                //var choiceItemIndex = (myArray.last?)!)
                let selectedSegment = Int(choiceItemIndex) ?? -1

                cell.choiceSegmentControl.selectedSegmentIndex = selectedSegment
        
            } else {
                cell.choiceSegmentControl.selectedSegmentIndex = -1
            }
            segControl.apportionsSegmentWidthsByContent = true
            
            cell.segmentSelectionHandler = viewModel
            

            return cell
        }
        else {
            //handle plain FoodItem
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)  
            cell.textLabel?.text = currentItem.name
            var itemDescription: String = ""
            if currentItem.menuItemType == "VegetableItem" {
                
                itemDescription = currentItem.serving.servingDescription + " " + currentItem.itemDescription
            } else {
                itemDescription = currentItem.itemDescription
            }

            cell.detailTextLabel?.text = itemDescription
            return cell
        }
        
    }
    
    func tableCell(tableView: UITableView, cellForMedicineItem indexPath: NSIndexPath, medicineText: String?, switchState: Bool?) -> MedicineTableViewCell
    {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(MedicineTableViewCell.cellIdentifer, forIndexPath: indexPath)  as! MedicineTableViewCell
        
        cell.medicineLabel.text = medicineText
        cell.medicineListingLable?.text = medicineText ?? "None Selected"
        cell.medicineSwitch.on = switchState ?? false
        return cell
        
    }
    func tableCell(tableView: UITableView, cellForRequiredItemsItem indexPath: NSIndexPath, switchState: Bool) -> RequiredItemTableViewCell
    {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(RequiredItemTableViewCell.cellIdentifer, forIndexPath: indexPath)  as! RequiredItemTableViewCell
        
        cell.rItemSwitch.on = switchState
        return cell
        
    }
    func tableCell(tableView: UITableView, cellForAddOnItem indexPath: NSIndexPath, addOnText: String, switchState: Bool, switchSelectionHandler: AddOnItemSelectedDelegate) -> AddOnTableViewCell
    {
        
        let cell: AddOnTableViewCell = tableView.dequeueReusableCellWithIdentifier(AddOnTableViewCell.cellIdentifer, forIndexPath: indexPath)  as! AddOnTableViewCell
        //cell.textLabel?.text = currentItem.name
        cell.addOnTakenHandler = switchSelectionHandler//self as? AddOnItemSelectedDelegate
        cell.addOnLabel?.text = addOnText
        cell.addOnSwitch.on = switchState
        return cell
        
    }
    func tableCell(tableView: UITableView, cellForLocationItem indexPath: NSIndexPath, inout locationText: String?,  locationSelectionHandler: LocationSelectedDelegate) -> LocationTableViewCell
    {
        // Location is set from the current meal item if it has been selected, if not, we set it to the first location in the LocationForMeal enum
        let cell: LocationTableViewCell = tableView.dequeueReusableCellWithIdentifier(LocationTableViewCell.cellIdentifer, forIndexPath: indexPath)  as! LocationTableViewCell
        
        cell.locationButtonHandler = locationSelectionHandler
        let location = locationText ?? LocationForMeal(rawValue: 0)!.name()
        cell.locationButton.setTitle(location, forState: .Normal)

        return cell
    
    }
    func tableCell(tableView: UITableView, cellForParentInitialsItem indexPath: NSIndexPath, inout parentInitialsText: String?,  parentSelectionHandler: ParentInitialsSelectedDelegate) -> ParentInitsTableViewCell
    {
        //parent initals are set to selected value, or a default value of the initials for the first item in profile.Parents is displayed by dataStore method defaultParentInitials()
        dataStore.defaultParentInitials()
        let cell: ParentInitsTableViewCell = tableView.dequeueReusableCellWithIdentifier(ParentInitsTableViewCell.cellIdentifer, forIndexPath: indexPath)  as! ParentInitsTableViewCell
        cell.parentButtonHandler = parentSelectionHandler
        var pInitials = ""
        if parentInitialsText != nil {
            pInitials = parentInitialsText!
        } else {
        
            pInitials = dataStore.defaultParentInitials() ?? "Parents Not Selected"
            parentInitialsText = dataStore.defaultParentInitials()
        }
        cell.parentInitsButton.setTitle(pInitials, forState: .Normal)
        return cell
        
    }
    func tableCell(tableView: UITableView, cellForTimeItem indexPath: NSIndexPath, inout time: String,  timeSelectionHandler: TimeSelectedDelegate) -> TimeTableViewCell
    {
        //TODO: Initialize this to a median tme for the specific meal.  currently initializes to current time.
        let cell: TimeTableViewCell = tableView.dequeueReusableCellWithIdentifier(TimeTableViewCell.cellIdentifer, forIndexPath: indexPath)  as! TimeTableViewCell
        
        cell.timeSelectedHandler = timeSelectionHandler
        
        cell.timeTextField.text = time
        return cell
        
    }
    
    func tableCell(tableView: UITableView, cellForNoteItem indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NoteTableCell", forIndexPath: indexPath) 
        
        // Configure the cell...
        //cell.textLabel?.text
        
        return cell
    }
    
    //MARK: Toggle Food Item Rows
    func toggleSelectionArrayAndPropertyInModel (indexPath: NSIndexPath, inout mutableArray: [FoodItem], immutableArray: [FoodItem], inout propertyInModel: String?, choiceCell: NewChoiceTableViewCell?)
    {
        if mutableArray.count == 1 {
            // selecting row when only one row in section, deselects row and displays full list of options
            mutableArray = immutableArray  //immutable array contains full list of values
//            let c = self.tableCell(tableViewRef, cellForFoodItemAtIndexPath: indexPath, inArray: mutableArray, foodItemName: <#String?#>, viewModel: <#ChoiceItemSelectedDelegate?#>)
//            let cell = self.tableView(tableViewRef, cellForRowAtIndexPath: indexPath) //as? NewChoiceTableViewCell
            //vm.didDeselectRowAtIndexPath( indexPath, viewController: self )
            //vm.tableView(tableView, didDeselectRowAtIndexPath: indexPath)
//            if  cell != nil {
//                cell!.clearChoiceInSegmentControl()
//            }
            choiceCellSelectedState = false
            //choiceCell?.clearChoiceInSegmentControl()
            let currentProperyValue = propertyInModel
            //need to be nil so there is no selection on row insertion
            propertyInModel = nil
//            if let choiceItem = immutableArray[indexPath.row] as? FoodItemWithChoice {
//                var c = self.tableCell(<#tableView: UITableView#>, cellForFoodItemAtIndexPath: <#NSIndexPath#>, inArray: <#[FoodItem]#>, foodItemName: <#String?#>, viewModel: <#ChoiceItemSelectedDelegate?#>)
//                var cell = self.tableCell(self.tableView!, cellForFoodItemAtIndexPath: indexPath, inArray: mutableArray, foodItemName: currentProperyValue, viewModel: self)
//            }

                if choiceCell != nil {
                animateRowInsertion(immutableArray.getIndexInArray(currentProperyValue), indexPath: indexPath, rowCountInItemsArray: immutableArray.count, choiceCell: &choiceCell!.selectedIndex)
                    self.tableView.reloadData()
                } else {
                    animateRowInsertion(immutableArray.getIndexInArray(currentProperyValue), indexPath: indexPath, rowCountInItemsArray: immutableArray.count)
                }
            
            
        } else {
            //
            if  immutableArray[indexPath.row] is FoodItemWithChoice {
                return
            } else {
                choiceCellSelectedState = true
                mutableArray.removeAll(keepCapacity: false)
                mutableArray = [immutableArray[indexPath.row]]
                propertyInModel = immutableArray[indexPath.row].name

                // delete cells
                let rows = getIndexPathArrayOfRowsToDelete(indexPath, countOfArrayOfFoodItems: immutableArray.count)
                animateRowDeletion(rows)
            }
        }
    }
    
    
    //MARK: Segmented Control Handler
    
    func toggleSelectionArrayAndPropertyInModelForSegmentedControl (selectedIndexPath selectedIndexPath: NSIndexPath, selectedSegment: Int, inout mutableArray: [FoodItem], immutableArray: [FoodItem], inout propertyInModel: String?)
    {
        if mutableArray.count == 1 {
            //for FoodItemWithChoice this gets called when user changes selection after they've selected this tableCell from the list
            //mutableArray = immutableArray  //immutable array contains full list of values
            propertyInModel = self.getItemNameAndChoiceItemIndex(selectedIndexPath: selectedIndexPath, selectedSegment: selectedSegment, mutableArray: mutableArray)
        } else {
            let indexPathArrayToDelete = getIndexPathArrayOfRowsToDelete(selectedIndexPath, countOfArrayOfFoodItems: mutableArray.count)
            
            propertyInModel = self.getItemNameAndChoiceItemIndex(selectedIndexPath: selectedIndexPath, selectedSegment: selectedSegment, mutableArray: mutableArray)            
            mutableArray = [immutableArray[selectedIndexPath.row]]
            
            animateRowDeletion(indexPathArrayToDelete)
            //tableView.reloadData()
        }
    }
    func deleteRowsInDataSource ( originalCountRowsInSection: Int , selectedRow: Int, selectedSection: Int ){
        
            }
    func getIndexPathArrayOfRowsToDelete ( indexPathToKeep: NSIndexPath, countOfArrayOfFoodItems: Int) -> [NSIndexPath]
    {
        var pathSet: [NSIndexPath] = [NSIndexPath]()
        for index in 0 ..< countOfArrayOfFoodItems {
            
            if index  != indexPathToKeep.row {
                let indexPathToDelete = NSIndexPath(forRow: index , inSection: indexPathToKeep.section)
                pathSet.append(indexPathToDelete)
            }
        }
        return pathSet
    }
    
    func animateRowDeletion ( rowsToDelete: [NSIndexPath] ) {// selectedRow: Int, rowsOriginallyInSection: Int , selectedSection: Int){
        
        tableView.beginUpdates()
        tableView.deleteRowsAtIndexPaths(rowsToDelete, withRowAnimation: UITableViewRowAnimation.Automatic)
        tableView.endUpdates()
    }
    func getIndexPathArrayOfRowsToInsert ( indexPathOfSelectedItem: NSIndexPath, countOfArrayOfFoodItems: Int) -> [NSIndexPath]
    {
        var pathSet: [NSIndexPath] = [NSIndexPath]()
        for index in 0 ..< countOfArrayOfFoodItems {
            pathSet.append( NSIndexPath(forRow: index , inSection: indexPathOfSelectedItem.section) )
        }
        return pathSet
    }
    
    func animateRowInsertion ( indexInItemsArrayOfSelectedItem: Int, indexPath:  NSIndexPath, rowCountInItemsArray: Int , inout choiceCell: Int) {
        var rowsToInsert = [NSIndexPath]()
        for row in 0..<indexInItemsArrayOfSelectedItem {
            rowsToInsert.append(NSIndexPath(forRow: row, inSection: indexPath.section))
        }
      
//        var rowsBelowCurrentSelection = [NSIndexPath]()
        let nextItemInList = indexInItemsArrayOfSelectedItem + 1
        for row in  nextItemInList..<rowCountInItemsArray {
            rowsToInsert.append(NSIndexPath(forRow: row, inSection: indexPath.section))
        }

        tableView.beginUpdates()
        //choiceCell = 0
        tableView.insertRowsAtIndexPaths(rowsToInsert, withRowAnimation: UITableViewRowAnimation.Bottom)
        
        tableView.endUpdates()
//        tableView.beginUpdates()
//        tableView.endUpdates()

    }
    func animateRowInsertion ( indexInItemsArrayOfSelectedItem: Int, indexPath:  NSIndexPath, rowCountInItemsArray: Int ) {
        var rowsAboveCurrentSelection = [NSIndexPath]()
        for row in 0..<indexInItemsArrayOfSelectedItem {
            rowsAboveCurrentSelection.append(NSIndexPath(forRow: row, inSection: indexPath.section))
        }
        
//        var rowsBelowCurrentSelection = [NSIndexPath]()
        let nextItemInList = indexInItemsArrayOfSelectedItem + 1
        for row in  nextItemInList..<rowCountInItemsArray {
            rowsAboveCurrentSelection.append(NSIndexPath(forRow: row, inSection: indexPath.section))
        }
        
        tableView.beginUpdates()
//        choiceCell = 1
        tableView.insertRowsAtIndexPaths(rowsAboveCurrentSelection, withRowAnimation: UITableViewRowAnimation.Bottom)
        tableView.endUpdates()
        
        //        tableView.beginUpdates()
        //        tableView.endUpdates()
        
    }

    func getItemNameAndChoiceItemIndex ( selectedIndexPath selectedIndexPath: NSIndexPath, selectedSegment: Int, mutableArray: [FoodItem] ) -> String
    {
        var itemName = ""
        if mutableArray.count == 1 {
            let selectedFoodItem = mutableArray[0] as? FoodItemWithChoice
            itemName = selectedFoodItem!.name
            //let choiceName = selectedFoodItem!.choiceItems[selectedSegment]
        } else {
        // cast always succeeds because only FoodItemWithChoice items get the cells with the segmented controls
        let choiceItem = mutableArray[selectedIndexPath.row] as? FoodItemWithChoice
        itemName = choiceItem!.name
        //let childChoiceItemName = choiceItem!.choiceItems[selectedSegment].name
        }
        let compoundName = itemName + "," + String(selectedSegment)
        return compoundName

    }
    
    
     //MARK: Helper Methods
   
    func setPropertyInModel (value value: String, inout propertyInModel: String?){
        propertyInModel = value
    }
    func setPropertyInModel (value value: String, inout propertyInModel: String){
        propertyInModel = value
    }
    func setPropertyInModel (boolValue boolValue: Bool, inout boolPropertyInModel: Bool?){
        boolPropertyInModel = boolValue
    }
    func setPropertyInModel (dateValue dateValue: NSDate, inout datePropertyInModel: NSDate?){
        datePropertyInModel = dateValue

    }
    
    func getFoodItem ( itemName: String, foodItemArray: [FoodItem] ) -> [FoodItem] {
        // get subtype of food items for selection
        let myArray: [String] = itemName.componentsSeparatedByString(",")
        let nameOfParentFoodItem: String? = myArray.first

        let fItems = foodItemArray.filter({m in
            m.name == nameOfParentFoodItem
        })
        
        return fItems
    }
    
    func getParentInitials() -> [String] {
        var initials = [String]()
        //TODO: implement more robust version of getParentInitials
        for fullName in dataStore.parentsArray{
            var fullNameArr = fullName.characters.split {$0 == " "}.map { String($0) }
            
            let firstName: String = fullNameArr[0]
            let lastName: String? = fullNameArr.count > 1 ? fullNameArr[fullNameArr.count-1] : nil
            
            let firstInitial = firstName[firstName.startIndex]
            let lastInitial = lastName?[lastName!.startIndex]
            
            initials.append("\(firstInitial). \(lastInitial!).")
        }
        return initials
    }
    
}

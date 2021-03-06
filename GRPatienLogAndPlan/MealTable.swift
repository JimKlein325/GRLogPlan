//
//  File.swift
//  PDFGenRefactor
//
//  Created by James Klein on 7/17/15.
//  Copyright (c) 2015 James Klein. All rights reserved.
//

import UIKit
import Foundation
import QuartzCore
import CoreText

extension UIFont {
    func sizeOfString (string: String, constrainedToWidth width: Double) -> CGSize {
        return NSString(string: string).boundingRectWithSize(CGSize(width: width, height: DBL_MAX),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: self],
            context: nil).size
    }
}

struct TableLineItems {
    let horizontalLineIndices : [Int]
    let verticalYStartIndex: Int
    let verticalYEndIndex: Int
}

public struct MealTableInfoItem {
    let mealName : String
    let logItems: [String]
    let place: String?
    let time: String?
    let parent: String?
    let note: String?
    init (mealName: String, logItems: [String], place: String?, time: String?, parent: String?, note: String?)
    {
        self.mealName = mealName
        self.logItems = logItems
        self.place = place ?? "None Selected"
        self.time = time ?? "None Selected"
        self.parent = parent ?? "None Selected"
        self.note = note
    }
   }

class MealTable {
    //let drawItem: TextDrawingItem
    let mealName: String
    let logItems: [String]
    let place: String
    let time: String
    let parent: String
    let note: String?
    
    let immutableRowHeight: Int = 22
    typealias LogEntryStringResult = (logEntryString: String, boldRanges: [ CFRange])
    
    func logEntryString() -> LogEntryStringResult {
        var rangeStart = 0
        var ranges = [CFRange]()
        
        var item = ""
        //  add a bullet to the string
        for i in 0..<self.logItems.count {
            var stringWithBullet = appendStringToBullet(logItems[i])
           
            if i < logItems.count - 1 {
                stringWithBullet += "\n"
            }
            
            item += stringWithBullet
            
            let stringLength = stringWithBullet.characters.count
            
            //get range of bolded text from start of line to colon:  * Main Item: Ham Sandwich
            let pos = getPositionOfColon(stringWithBullet)
            
            ranges.append(CFRangeMake(rangeStart, pos))
            
            //increase counter for range start
            rangeStart += stringLength
            
        }
        return (item, ranges)
    }
    
    func getPositionOfColon ( item: String) -> Int {
        var pos = 0
        let needle: Character = ":"
        if let idx = item.characters.indexOf(needle) {
            pos = item.startIndex.distanceTo(idx)
        }
        return pos
    }
    
    func appendStringToBullet(s: String) -> String{
        var testString = ""
        let bulletString = UnicodeScalar(0x2022)
        testString.append(bulletString)
        testString += "  "
        testString += s
        return testString
    }
    
    
    var logEntriesHeight: Int {
        return getHeightOfString(self.logEntryString().logEntryString)
    }
    
    var noteEntryHeight: Int {
        var h = immutableRowHeight //height of Note Title row
        if note != nil {
            h += getHeightOfString(note!) + 25//fudge for bottom row padding
        }
        return h
    }
    
    var columnLineStartYIndex: Int {
        let h = immutableRowHeight +
        logEntriesHeight
        return h
    }
    var columnLineEndYIndex: Int {
        let h = immutableRowHeight + //Table Title: Meal Name
            logEntriesHeight +  //
            immutableRowHeight + //Addtional Items Titles
        immutableRowHeight //Additional Items text
        return h
    }
    
    func getHeightOfString (text: String) -> Int {
        var h = 0
        let font = UIFont(name: "Helvetica", size: 12.0)
        if let size = font?.sizeOfString(text, constrainedToWidth: 500.0) {
            h = Int(size.height)
        }
        return h
    }
    func getTableHeight () -> Int
    {
        let h = immutableRowHeight + //Table Title: Meal Name
            logEntriesHeight +
            immutableRowHeight + //Addtional Items Titles
            immutableRowHeight + //Addtional Items Values
            immutableRowHeight + //Note Title
            noteEntryHeight // Note text
        
        return h
    }
    func buildLogItems() -> [String]{
        
        return logItems
    }
    init ( mealItem:  MealTableInfoItem){
        self.mealName = mealItem.mealName
        logItems = mealItem.logItems
        place = mealItem.place!//OK to force unwrap because MealTableInfoItem uses nil colascing operator to set default values in init()
        time = mealItem.time!
        parent = mealItem.parent!
        note = mealItem.note
    }
//    init ()
//    {
//        mealName = "Placeholder"
//        var items =
//        ["Food Choice:  French Toast, 2 silices bread, 2 eggs, 1 c Milk \n",
//            "Fruit:  Cherries, 3/4 c"
//        ]
//        var bulletedItems = [String]()
//       
//        logItems = items
//        
//        place =  "Kitchen"
//        time =  "7:30 AM"
//        parent =  "J.S."
//        
//        note =  "Had this meal while visiting relatives away from home.  Fortunately, they have a very healthy live style."
//        for index in 0...items.count - 1 {
//            
//            bulletedItems.append(appendStringToBullet(items[index]))
//        }
// 
//    }
    
    func buildMealTable(yIndexForTable: Int) -> (textItems:[TextDrawingItem], tableLines: TableLineItems)  {
        var drawingItems = [TextDrawingItem]()
        var currentYOnPage = yIndexForTable
        var horizontalLineIndices = [Int]()
        
        horizontalLineIndices.append(yIndexForTable)
        // BEGIN TO ASSEMBLE TABLE
        let drawingItem = singleEntryPerRowTitleCell(mealName, currentYValue: currentYOnPage)
        drawingItems.append(drawingItem)
        horizontalLineIndices.append(Int(drawingItem.height))
        
        currentYOnPage = drawingItem.height//+= Int(drawingItem.frameRect.height)
        
        let logItem = logEntryCell(self.logEntryString(), currentYValue: currentYOnPage)
        drawingItems.append(logItem)
        
        currentYOnPage += Int(logItem.frameRect.height)
        horizontalLineIndices.append(Int(logItem.height - 4))
        let verticalYStartIndex = Int(logItem.height - 4 )
        
        
        let additionalInfoDrawItems = additionalInfoItems([place,time, parent], currentYValue: currentYOnPage)
        for i in 0...2 {
            drawingItems.append(additionalInfoDrawItems[i])
        }
        
        currentYOnPage = additionalInfoDrawItems[0].height
        horizontalLineIndices.append(Int(additionalInfoDrawItems[0].height))
        for i in 3...5 {
            drawingItems.append(additionalInfoDrawItems[i])
        }
        horizontalLineIndices.append(Int(additionalInfoDrawItems[3].height))
        currentYOnPage = additionalInfoDrawItems[3].height
        let verticalYEndIndex = Int(currentYOnPage)
        
        //Note section
        if note != nil {
            let drawingItemNote = self.singleEntryPerRowTitleCell("Note", currentYValue: currentYOnPage)
            drawingItems.append(drawingItemNote)
            currentYOnPage = drawingItemNote.height//+= Int(drawingItemNote.frameRect.height)
            horizontalLineIndices.append(Int(drawingItemNote.height))
            let noteItem = noteCell(note!, currentYValue: currentYOnPage) //logEntryCell("placeholder text", currentYOnPage)
            drawingItems.append(noteItem)
            horizontalLineIndices.append(Int(noteItem.height - 12))
        }
        //var x = getTableHeight()
        let tableLines = TableLineItems(horizontalLineIndices: horizontalLineIndices, verticalYStartIndex: verticalYStartIndex, verticalYEndIndex: verticalYEndIndex)
        return (drawingItems, tableLines)
    }//end func
    
    //Mark: Builder Helper Methods
    func singleEntryPerRowTitleCell(titleText: String, currentYValue: Int) -> TextDrawingItem
    {
        let fontSize = 12
        let horizontalPadding = 5
        let vericalPadding = 10
        let mutableStringRef = drawableTextFromString(titleText)
        setTextBoldingAndFontSizeFullString(mutableStringRef, originalString: titleText, fontSize: fontSize)
        let frameRect = cGRectForItem(72, currentYValue: currentYValue, sizeOfFontOrItemCell: fontSize, leftPadding: horizontalPadding, verticalPadding: vericalPadding, pageWidth: 468)//CGRectMake(72, CGFloat(currentYValue + fontSize + padding), 540, CGFloat(fontSize + 10))
        
        return TextDrawingItem(textToDraw: mutableStringRef, frameRect: frameRect )
    }
    func logEntryCell(entries: LogEntryStringResult, currentYValue: Int) -> TextDrawingItem {
        
        //TODO: use parameter "entries" instead of hard coded logItems string
        let logItems = entries.logEntryString
        
        let font = UIFont(name: "Helvetica", size: 12.0)
        let size = font?.sizeOfString(logItems, constrainedToWidth: 468.0)
        
        let mutableRefStr = buildMutableAttributedStringRef(logItems)
        
        for range in entries.boldRanges {
            setTextBoldingForRange(range, text: mutableRefStr, fontSize: 12)
        }
        
        let height = size!.height
        
//        let padding: CGFloat = 10
        //let frameRect = CGRectMake(CGFloat(72.0), CGFloat(currentYValue) + height + padding, CGFloat(612 - 144), height + padding/2)
        
        let frameRect = cGRectForItem(72 , currentYValue: currentYValue, sizeOfFontOrItemCell: Int(height) + 10, leftPadding: 10, verticalPadding: 10, pageWidth: 612 - 144 - 20)//subtract padding in width calculation
        return TextDrawingItem(textToDraw: mutableRefStr, frameRect: frameRect )
    }
//    func logEntryCell(entries: [String], currentYValue: Int) -> TextDrawingItem {
//        
//        var plainStringToUseWithMeasureFunction: String = ""
//        var mString = NSMutableAttributedString(string: "")
//        //for each entry:  
//        for i in 0..<entries.count{
//            
//            var string = entries[i]
//            // Add new line \n to log entries  to count - 1, the last line in list
//            if i < entries.count - 1 {
//                string = string + "\n"
//                plainStringToUseWithMeasureFunction += string
//            }
//            // Get index of :
//            let needle: Character = ":"
//            var mutableString = buildMutableAttributedStringRef(string)
//            
//            if let idx = find(string, needle) {
//                let pos = distance(string.startIndex, idx)
//                //println("Found \(needle) at position \(pos)")
//                
//                let mutableString = buildMutableAttributedStringRef(string)
//                setTextBoldingToIndex(pos, text: mutableString, fontSize: 12)
//                mString.ap
//            }
//            else {
//                println("Error in Log Item formatting:  Colon Not found")
//            }
//        
//            
//        
//        //Bold characters upto and including :
//        
//        
//        
//        }
//        //var logItems = entries
//        
//        var font = UIFont(name: "Helvetica", size: 12.0)
//        let size = font?.sizeOfString(plainStringToUseWithMeasureFunction, constrainedToWidth: 468)
//        
//        //let mutableRefStr = buildMutableAttributedStringRef(logItems)
//        let height = size!.height
//        
//        let padding: CGFloat = 10
//        //let frameRect = CGRectMake(CGFloat(72.0), CGFloat(currentYValue) + height + padding, CGFloat(612 - 144), height + padding/2)
//        
//        let frameRect = cGRectForItem(72 , currentYValue: currentYValue, sizeOfFontOrItemCell: Int(height) + 10, leftPadding: 10, verticalPadding: 10, pageWidth: 612 - 144)
//        return TextDrawingItem(textToDraw: mutableRefStr, frameRect: frameRect )
//    }
    
    func additionalInfoItems (values: [String], currentYValue: Int) -> [TextDrawingItem] {
        var drawItems = [TextDrawingItem]()
        
        // Build Draw Items for Header Columns
        drawItems.append(columnTripletDrawItem(
            "Place",
            isBoldText:true,
             columnIndex: 0,
            leftMargin: 72,
            currentYValue: currentYValue,
            sizeOfFontOrItemCell: 12,
            leftPadding: 5,
            verticalPadding: 10,
            pageWidth: 468
            )
        )
        
        drawItems.append(columnTripletDrawItem(
            "Time",
            isBoldText: true,
            columnIndex: 1,
            leftMargin: 72 ,
            currentYValue: currentYValue,
            sizeOfFontOrItemCell: 12,
            leftPadding: 5,
            verticalPadding: 10,
            pageWidth: 468
            )
        )
        
        
        drawItems.append(columnTripletDrawItem(
            "Parent",
            isBoldText: true,
            columnIndex: 2,
            leftMargin: 72 ,
            currentYValue: currentYValue,
            sizeOfFontOrItemCell: 12,
            leftPadding: 5,
            verticalPadding: 10,
            pageWidth: 468
            )
        )
        
        for i in 0...2 {
            drawItems.append(columnTripletDrawItem(
                values[i],
                isBoldText: false,
                columnIndex: i,
                leftMargin: 72 ,
                currentYValue: currentYValue + 22,
                sizeOfFontOrItemCell: 12,
                leftPadding: 5,
                verticalPadding: 10,
                pageWidth: 468
                )
            )
        }
        
        return drawItems
    }
    func noteCell(note: String, currentYValue: Int) -> TextDrawingItem {
        
        let font = UIFont(name: "Helvetica", size: 12.0)
        let size = font?.sizeOfString(note, constrainedToWidth: 468)
        
        let mutableRefStr = buildMutableAttributedStringRef(note)
        let height = size!.height
        
//        let padding: CGFloat = 10
        //let frameRect = CGRectMake(CGFloat(72.0), CGFloat(currentYValue) + height + padding, CGFloat(612 - 144), height + padding/2)
        
        let frameRect = cGRectForItem(72 , currentYValue: currentYValue, sizeOfFontOrItemCell: Int(height) + 10, leftPadding: 10, verticalPadding: 20, pageWidth: 612 - 144)
        return TextDrawingItem(textToDraw: mutableRefStr, frameRect: frameRect )
        
    }
    func buildMutableAttributedStringRef(textToDraw:String)  -> CFMutableAttributedStringRef {
        let stringRef = textToDraw as CFStringRef
        
        let currentText: CFAttributedStringRef =  CFAttributedStringCreate(nil , stringRef, nil)
        let mutableAttriburedStringRef: CFMutableAttributedStringRef = CFAttributedStringCreateMutableCopy(nil , 0, currentText)
        return mutableAttriburedStringRef
    }
    
    func drawableTextFromString(textToDraw: String) -> CFMutableAttributedStringRef {
        let stringRef = textToDraw as CFStringRef
        
        // Prepare the text using a Core Text Framesetter.
        let currentText: CFAttributedStringRef =  CFAttributedStringCreate(nil , stringRef, nil)
        let mutableAttriburedStringRef: CFMutableAttributedStringRef = CFAttributedStringCreateMutableCopy(nil , 0, currentText)
        
        return mutableAttriburedStringRef
    }
    
    func setTextBoldingAndFontSizeFullString(text:  CFMutableAttributedStringRef, originalString: String, fontSize: Int){
        let size: CGFloat = CGFloat(fontSize)
        
        let stringLength = originalString.characters.count
        let fontBold = CTFontCreateWithName("Helvetica-Bold", size, nil)
        CFAttributedStringSetAttribute(text , CFRangeMake(0, stringLength ), kCTFontAttributeName, fontBold)
    }
    
    func setTextBoldingForRange(range: CFRange, text:  CFMutableAttributedStringRef,  fontSize: Int){
        let size: CGFloat = CGFloat(fontSize)
        
        //let stringLength = count(originalString)
        let fontBold = CTFontCreateWithName("Helvetica-Bold", size, nil)
        CFAttributedStringSetAttribute(text , range, kCTFontAttributeName, fontBold)
    }
    
    //func formatLogEntryItems (items: [String]) -> [

    func columnTripletDrawItem(text: String, isBoldText: Bool, columnIndex: Int,  leftMargin: Int , currentYValue: Int, sizeOfFontOrItemCell: Int, leftPadding: Int,  verticalPadding: Int, pageWidth: Int ) -> TextDrawingItem {
        
        let mutableStringRef: CFMutableAttributedStringRef = buildMutableAttributedStringRef(text)
        
        if isBoldText {
            setTextBoldingAndFontSizeFullString(mutableStringRef, originalString: text, fontSize: 12)
        }
        //add the column # x 1/3 pageWidth to place the cell text in the right column
        //TODO: refactor and use enum
        let columnMargin = leftMargin + columnIndex * pageWidth/3
        let frameRect = cGRectForItem(columnMargin, currentYValue: currentYValue, sizeOfFontOrItemCell: sizeOfFontOrItemCell, leftPadding: leftPadding, verticalPadding: verticalPadding, pageWidth: pageWidth)
        
        return TextDrawingItem(textToDraw: mutableStringRef, frameRect: frameRect)
    }
    
    func cGRectForItem(leftMargin: Int , currentYValue: Int, sizeOfFontOrItemCell: Int, leftPadding: Int,  verticalPadding: Int, pageWidth: Int) -> CGRect {
        let cGLeftMargin = CGFloat(leftMargin)
        let cGCurrentY = CGFloat(currentYValue)
        let cGSizeOfFontOrItemCell = CGFloat(sizeOfFontOrItemCell)
        let cGLeftPadding = CGFloat(leftPadding)
        let cGVerticalPadding = CGFloat(verticalPadding)
        let cGPageWidth = CGFloat(pageWidth)
        
        return CGRectMake(cGLeftMargin + cGLeftPadding, cGCurrentY + cGSizeOfFontOrItemCell + cGVerticalPadding, cGPageWidth, cGSizeOfFontOrItemCell + cGVerticalPadding/1.5)
        
    }
    

    


}

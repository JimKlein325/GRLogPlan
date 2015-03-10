//
//  MenuDisplayCellProtocol.swift
//  FoodItemDataStoreTest
//
//  Created by James Klein on 3/8/15.
//  Copyright (c) 2015 ObjectPrism Corp. All rights reserved.
//

import Foundation

//used to display items for selected meal in detail view
@objc protocol MenuDisplayCell {
    var menuDisplayName: String { get set }
    //var mealEntryState: MealEntryState! { get set }
}


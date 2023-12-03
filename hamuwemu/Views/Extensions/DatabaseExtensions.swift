//
//  DatabaseExtensions.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/2/21.
//

import FirebaseDatabase

extension Database {
  class var root: DatabaseReference {
    return database(url: "https://hamuwemu-app-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
  }
}

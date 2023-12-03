//
//  hamuwemuUITests.swift
//  hamuwemuUITests
//
//  Created by Dulitha Dabare on 2022-03-25.
//

import XCTest

class hamuwemuUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        snapshot("0ChatView")
        
        
        
//        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["Steffi Scholz"]/*[[".cells[\"Steffi Scholz\"].buttons[\"Steffi Scholz\"]",".buttons[\"Steffi Scholz\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element(boundBy: 2).children(matching: .other).element(boundBy: 1).children(matching: .textView).element.tap()
        
        snapshot("1Encrypted")
        
        app.navigationBars["_TtGC7SwiftUI19UIHosting"].buttons["Chats"].tap()
        tablesQuery/*@START_MENU_TOKEN@*/.buttons["Tomasz Nurkiewicz"]/*[[".cells[\"Tomasz Nurkiewicz\"].buttons[\"Tomasz Nurkiewicz\"]",".buttons[\"Tomasz Nurkiewicz\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.buttons["List"].tap()
   
        snapshot("2Topics")
                        

                
        
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

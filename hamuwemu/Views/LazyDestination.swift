//
//  LazyDestination.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 12/21/21.
//

import SwiftUI

// This view lets us avoid instantiating our Destination before it has been pushed.
struct LazyDestination<Destination: View>: View {
    var destination: () -> Destination
    var body: some View {
        self.destination()
    }
}

//struct LazyDestination_Previews: PreviewProvider {
//    static var previews: some View {
//        LazyDestination()
//    }
//}

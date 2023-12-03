//
//  FloatingActionButton.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-05-02.
//

import SwiftUI

struct FloatingActionButton: View {
    @GestureState var isDetectingLongPress = false
    @State var completedLongPress = false
    
    var hint: String
    var icon: String
    var action: () -> Void
    var badgeCount: Int16 = 0
    
    var body: some View {
        HStack {
            if isDetectingLongPress {
                Text(hint)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.white))
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                    .background(Capsule().fill(Color(UIColor.black)))
            }
            Button {
                action()
                
//                            model.scrollTo = .bottonWithAnimation
            } label: {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                    .frame(width: 50, height: 40)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color(UIColor.secondarySystemBackground)))
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 3)
                    .updating($isDetectingLongPress) { currentState, gestureState,
                        transaction in
                        gestureState = currentState
//                                    transaction.animation = Animation.easeIn(duration: 2.0)
                    }
                    .onEnded { finished in
                        self.completedLongPress = finished
                    }
                
            )
        }
    }
}

struct FloatingActionButton_Previews: PreviewProvider {
    static var previews: some View {
        FloatingActionButton(hint: "Add new thread", icon: "plus", action: {})
    }
}

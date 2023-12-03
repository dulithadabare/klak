//
//  SwipeView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-19.
//

import SwiftUI

struct TestView: View {
    var index: Int
    var text: String
    var size: CGSize
    var color: Color
    var count: Int
    var currOffsetX: CGFloat
    var dragDistanceX: CGFloat
    
    private var myCurrOffsetX: CGFloat {
        (CGFloat(index) * size.width) - currOffsetX
    }
    
    var body: some View {
        VStack {
            Text(text)
            Text("x: \(dragDistanceX) width: \(size.width)")
            Text("offset: \(myCurrOffsetX + dragDistanceX )")
            Text("currOffsetX: \(currOffsetX)")
        }
        .frame(width: size.width, height: size.height)
        .background(color)
        .offset(x: myCurrOffsetX + dragDistanceX)
//        .animation(.easeOut(duration: 0.5), value: dragDistanceX)
        
        
    }
}

struct SwipeView: View {
    var chat: ChatGroup
    var thread: ChatThreadModel
    
    @State private var currOffsetX: CGFloat = .zero
    @GestureState private var dragDistanceX: CGFloat = .zero
    @State private var isDragging: Bool = false
    @State private var currIndex: Int = 0
    @StateObject var model = Model()
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(model.threads.enumerated()), id: \.element) { index, thread in
                    ThreadSwipeView(index: index, size: proxy.size, stackOffsetX: currOffsetX, dragDistanceX: dragDistanceX) {
                        ThreadMessagesView(inMemory: true, chat: model.chat, thread: thread)
                        //                            TestMessagesView(inMemory: true, threadId: threadId)
                    }
                }
//                TestView(index: 2, text: "3", size: proxy.size, color: .red, count: 3, currOffsetX: currOffsetX, dragDistanceX: dragDistanceX)
//                TestView(index: 1, text: "2", size: proxy.size, color: .blue, count: 3, currOffsetX: currOffsetX, dragDistanceX: dragDistanceX)
//                TestView(index: 0, text: "1", size: proxy.size, color: .yellow, count: 3, currOffsetX: currOffsetX, dragDistanceX: dragDistanceX)
//                ThreadSwipeView(index: 0, size: proxy.size, stackOffsetX: currOffsetX, dragDistanceX: dragDistanceX) {
//                    TestMessagesView(inMemory: true, channelId: ChatGroup.preview.defaultChannel.channelUid)
//                }
                    
            }
            .clipped()
            .gesture(
                DragGesture()
                    .updating($dragDistanceX, body: { currentState, gestureState, transaction in
//                        print("translationX:  \(currentState.translation.width) currIndex: \(currIndex)")
                        if currIndex == 0 && currentState.translation.width > 0 {
                            return
                        }
                        
                        // navigate back gesture
                        if currentState.startLocation.x < 20 {
                            return
                        }
                        
//                        guard !(currentState.translation.width > 0 && currIndex > 0) else {
//                            return
//                        }
                        gestureState = currentState.translation.width
//                        print("Current state startLocation \(currentState.startLocation.x)")
                    })
//                    .onChanged({ gesture in
//                        dragDistanceX = gesture.translation.width
//                    })
                    .onEnded({ gesture in
//                        defer {
//                            dragDistanceX = .zero
//                        }
                        
                        if gesture.translation.width > 0 {
                            //right swipe
                            guard currIndex > 0 else {
                                currOffsetX = 0.0
                                return
                            }
                            
                            
                            
                            if abs(gesture.predictedEndTranslation.width) > proxy.size.width / 2 {
                                currOffsetX = CGFloat(currIndex - 1) * proxy.size.width
                            } else {
                                currOffsetX = (CGFloat(currIndex) * proxy.size.width)
                            }
                        } else {
                            //left swipe
                            guard currIndex < model.threads.count - 1 else {
                                currOffsetX = (CGFloat(currIndex) * proxy.size.width)
                                return
                            }
                            
                            if abs(gesture.predictedEndTranslation.width) > proxy.size.width / 2 {
                                currOffsetX = CGFloat(currIndex + 1) * proxy.size.width
                            } else {
                                currOffsetX = (CGFloat(currIndex) * proxy.size.width)
                            }
                        }
                        
                    })
                
            )
            .onChange(of: currOffsetX, perform: {[currOffsetX] newValue in
                let prevIndex = Int(currOffsetX/proxy.size.width)
                currIndex = Int(newValue/proxy.size.width)
                let prevThreadModel = model.threads[prevIndex]
                if prevThreadModel.isFirstResponder {
                    prevThreadModel.isFirstResponder = false
                    let currThreadModel = model.threads[currIndex]
                    currThreadModel.isFirstResponder = true
                }
            })
            .overlay(VStack{
                Spacer()
                Text("currIndex: \(currIndex)")
            })
        }
        .onAppear {
            print("SwipeView: onAppear")
            model.performOnceOnAppear(chat: chat, thread: thread)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if currIndex < model.threads.count {
                    Text(model.threads[currIndex].title.string)
                } else {
                    Text(thread.title.string)
                }
            }
            
//            ToolbarItem(placement: .navigationBarTrailing) {
//                                Button(action: {
//
//                                }) {
//                                    Text("Mute")
//                                }
//
//            }
        }
    }
}

struct SwipeView_Previews: PreviewProvider {
    static var previews: some View {
        SwipeView(chat: ChatGroup.preview, thread: ChatThreadModel.preview)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AuthenticationService.preview)
        .environmentObject(ContactRepository.preview)
        .environmentObject(NotificationDelegate.shared)
    }
}

import CoreData
import Combine

extension SwipeView {
    class Model: ObservableObject {
        @Published var threads: [ChatThreadModel] = []
        
        //init params
        var chat: ChatGroup!
        
        private var contactRepository: ContactRepository!
        private var authenticationService: AuthenticationService!
        var persistenceController: PersistenceController!
        private var managedObjectContext: NSManagedObjectContext!
        private var initialized: Bool = false
        
        private var cancellables: Set<AnyCancellable> = []
        
        //For temp threads
        init(){
            print("SwipeView: init")
        }
        
        func performOnceOnAppear(inMemory: Bool = false, chat: ChatGroup, thread: ChatThreadModel){
            print("SwipeView: initialized \(initialized)")
            guard !initialized else {
                return
            }
            self.chat = chat
            threads = [thread]
            
            if inMemory {
                contactRepository = ContactRepository.preview
                persistenceController = PersistenceController.preview
                managedObjectContext = PersistenceController.preview.container.viewContext
                authenticationService = AuthenticationService.preview
            } else {
                contactRepository = ContactRepository.shared
                persistenceController = PersistenceController.shared
                managedObjectContext = PersistenceController.shared.container.viewContext
                authenticationService = AuthenticationService.shared
            }
            
            fetchGroupThreads()
            initialized = true
        }
        
        
        func fetchGroupThreads(){
            var asyncFetchRequest: NSAsynchronousFetchRequest<HwChatThread>?
            
            let request: NSFetchRequest<HwChatThread> = HwChatThread.fetchRequest()
            request.predicate = NSPredicate(format: "%K = %@", #keyPath(HwChatThread.groupId), chat.group)
            
            request.sortDescriptors = [
                NSSortDescriptor(
                    keyPath: \HwChatThread.timestamp,
                    ascending: true)]
            
            asyncFetchRequest = NSAsynchronousFetchRequest<HwChatThread>(
                fetchRequest: request) {
                    [weak self] (result: NSAsynchronousFetchResult) in
                    
                    guard let hwItems = result.finalResult else {
                        return
                    }
                    
                    guard let strongSelf = self else {
                        return
                    }
                    
                    var threadIds = [ChatThreadModel]()
                    for item in hwItems {
                        let thread = ChatThreadModel(from: item)
                        if !strongSelf.threads.contains(thread){
                            threadIds.append(thread)
                        }
                    }
                    
                    strongSelf.threads.append(contentsOf: threadIds)
                }
            
            do {
                guard let asyncFetchRequest = asyncFetchRequest else {
                    return
                }
                try managedObjectContext.execute(asyncFetchRequest)
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
    }
}

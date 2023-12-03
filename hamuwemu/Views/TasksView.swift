//
//  TasksView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-06-16.
//

import SwiftUI

struct TasksView: View {
    @StateObject private var model = Model(inMemory: true)
    @State private var showAddNewTaskView = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(model.items) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                Text("Assigned By \(item.assignedBy)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if item.priority > 2 {
                                Text("Urgent")
                                    .foregroundColor(.red)
                                    .padding([.trailing], 10)
                            }
                        }
                        .onTapGesture(count: 2) {
                            model.remove(item: item)
                        }
                    }
                    .onDelete { indexSet in
                        model.items.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        //Add task
                        showAddNewTaskView.toggle()
                    } label: {
                        Text("New Task")
                    }
                    .buttonStyle(.borderedProminent)

                }
            }
            .sheet(isPresented: $showAddNewTaskView, onDismiss: nil) {
                AddTaskView()
            }
        }
    }
}

struct TasksView_Previews: PreviewProvider {
    static var previews: some View {
        TasksView()
    }
}

extension TasksView {
    class Model: ObservableObject {
        @Published var items: [TaskItem] = []
        
        init(inMemory: Bool = false) {
            if inMemory {
                items.append(TaskItem(title: "Check Delivery", assignedBy: "Dilanka Gamage", priority: 3))
                items.append(TaskItem(title: "Warehouse Inventory", assignedBy: "Dilanka Gamage", priority: 2))
                items.append(TaskItem(title: "Check Delivery", assignedBy: "Dilanka Gamage", priority: 1))
                items.append(TaskItem(title: "Check Delivery", assignedBy: "Dilanka Gamage", priority: 1))
            }
        }
        
        func remove(item: TaskItem) {
            items.removeAll { $0.id == item.id }
        }
    }
}

struct TaskItem: Identifiable {
    let id = UUID()
    let title: String
    let assignedBy: String
    let priority: Int
    var status = 0
}

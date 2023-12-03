//
//  UpdatesListView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/1/21.
//

import SwiftUI

struct UpdatesListView: View {
    @ObservedObject var updateModel: UpdateView.Model
    var body: some View {
        Group{
            switch updateModel.selectedList {
            case .mentions:
                List{
                    ForEach(updateModel.messages) { update in
                        if update.type.contains(UpdateType.mention) {
                            UpdateCard( update: update)
                        } else {
                            EmptyView()
                        }
                    }
                }
            case .links:
                ScrollView{
                    VStack {
                        ForEach(updateModel.messages) { update in
                            if update.type.contains(UpdateType.link) {
                                UpdateCard( update: update)
                            } else {
                                EmptyView()
                            }
                        }
                    }
                }
            default:
                List{
                    ForEach(updateModel.messages) { update in
                        if update.type.contains(UpdateType.image) {
                            UpdateCard( update: update)
                        } else {
                            EmptyView()
                        }
                    }
                }
            }
        }
    }
}

struct UpdatesListView_Previews: PreviewProvider {
    static var previews: some View {
        UpdatesListView(updateModel: UpdateView.Model())
    }
}


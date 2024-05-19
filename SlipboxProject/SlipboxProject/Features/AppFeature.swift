//
//  AppFeature.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct AppLogic {
	
	@ObservableState
	struct State: Equatable {
		var columnVisibility: NavigationSplitViewVisibility = .all
		var folderList = FolderListLogic.State()
	}
	
	enum Action: BindableAction {
		case binding(BindingAction<State>)
		case folderList(FolderListLogic.Action)
	}
	
	var body: some ReducerOf<Self> {
		BindingReducer()
		Scope(state: \.folderList, action: \.folderList) {
			FolderListLogic()
		}
		Reduce { state, action in
			switch action {
			case .binding:
				return .none
			case .folderList:
				return .none
			}
		}
	}
}

struct AppView: View {
	@Bindable var store: StoreOf<AppLogic>
	var body: some View {
		NavigationSplitView(
			columnVisibility: $store.columnVisibility) {
				FolderListView(
					store: store.scope(
						state: \.folderList,
						action: \.folderList
					)
				)
			} content: {
				ContentUnavailableView("Please select a folder", systemImage: "questionmark.folder.fill")
			} detail: {
				ContentUnavailableView("Please select a note", systemImage: "doc.questionmark.fill")
			}

	}
}

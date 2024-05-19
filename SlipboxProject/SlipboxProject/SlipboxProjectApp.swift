//
//  SlipboxProjectApp.swift
//  SlipboxProject
//
//  Created by Anderson  on 2024/5/19.
//

import SwiftUI
import ComposableArchitecture

@main
struct SlipboxProjectApp: App {
	
	let store: StoreOf<AppLogic>
	let persistenceController: PersistenceController
	
	init() {
		store = Store(initialState: AppLogic.State()) {
			AppLogic()._printChanges()
		}
		persistenceController = .shared
	}
	var body: some Scene {
		WindowGroup {
			AppView(store: store)
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
		}
	}
}

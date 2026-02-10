//
//  ContentView.swift
//  Applite
//
//  Created by Milán Várady on 2022. 09. 24..
//

import SwiftUI
import OSLog

struct ContentView: View {
    @EnvironmentObject var caskManager: CaskManager
    @EnvironmentObject var iCloudSyncManager: ICloudSyncManager

    /// Currently selected tab in the sidebar
    @State var selection: SidebarItem = .home

    @StateObject var loadAlert = AlertManager()

    @State var brokenInstall = false
    
    /// If true the sidebar is disabled
    @State var modifyingBrew = false

    /// App search query
    @State var searchInput = ""
    @State var showSearchResults = false

    // Sorting options
    @AppStorage(Preferences.searchSortOption.rawValue) var sortBy = SortingOptions.mostDownloaded
    @AppStorage(Preferences.hideUnpopularApps.rawValue) var hideUnpopularApps = false
    @AppStorage(Preferences.hideDisabledApps.rawValue) var hideDisabledApps = false

    let logger = Logger()

    private var searchSuggestions: [Cask] {
        guard !searchInput.isEmpty, showSearchResults else { return [] }
        return Array(caskManager.allCasks.casksMatchingSearch.prefix(5))
    }

    var body: some View {
        NavigationSplitView {
            sidebarViews
                .disabled(modifyingBrew)
        } detail: {
            detailView
        }
        .onAppear {
            caskManager.iCloudSyncManager = iCloudSyncManager
        }
        // Load all cask releated data
        .task {
            await loadCasks()
        }
        // MARK: - Search
        .searchable(text: $searchInput, placement: .sidebar)
        // Live debounced search
        .task(id: searchInput, debounceTime: .seconds(0.3)) {
            let trimmed = String(searchInput.prefix(30))
            if !trimmed.isEmpty {
                await searchAndSort()
                showSearchResults = true
                if selection != .home {
                    selection = .home
                }
            } else {
                showSearchResults = false
            }
        }
        // Instant search on Enter key
        .onSubmit(of: .search) {
            Task {
                if !searchInput.isEmpty {
                    await searchAndSort()
                    showSearchResults = true
                    if selection != .home { selection = .home }
                }
            }
        }
        // Search suggestions
        .searchSuggestions {
            if !searchInput.isEmpty {
                ForEach(searchSuggestions) { cask in
                    Text(cask.info.name).searchCompletion(cask.info.name)
                }
            }
        }
        // Apply sorting options
        .task(id: sortBy) {
            // Refilter if sorting options change
            await sortCasks(ignoreBestMatch: false)
        }
        // Apply filter option
        .task(id: hideUnpopularApps) {
            if hideUnpopularApps {
                await filterUnpopular()
            } else {
                await caskManager.allCasks.search(query: searchInput)
            }
        }
        .task(id: hideDisabledApps) {
            if hideDisabledApps {
                await filterDisabled()
            } else {
                await caskManager.allCasks.search(query: searchInput)
            }
        }
        // Load failure alert
        .alert(loadAlert.title, isPresented: $loadAlert.isPresented) {
            AsyncButton {
                await loadCasks()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }

            Button("Quit", role: .destructive) {
                NSApplication.shared.terminate(self)
            }

            Button("OK", role: .cancel) { }
        } message: {
            Text(loadAlert.message)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

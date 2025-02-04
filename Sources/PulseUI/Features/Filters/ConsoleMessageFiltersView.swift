// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

struct ConsoleMessageFiltersView: View {
    @ObservedObject var viewModel: ConsoleMessageSearchCriteriaViewModel
    @ObservedObject var sharedCriteriaViewModel: ConsoleSharedSearchCriteriaViewModel

    @State private var isGeneralSectionExpanded = true
    @State private var isLevelsSectionExpanded = true
    @State private var isLabelsSectionExpanded = true

#if os(iOS) || os(tvOS) || os(watchOS)
    var body: some View {
        Form { formContents }
#if os(iOS)
            .navigationBarItems(leading: buttonReset)
#endif
    }
#else
    var body: some View {
        ScrollView {
            VStack(spacing: ConsoleFilters.formSpacing) {
                VStack(spacing: 6) {
                    HStack {
                        Text("FILTERS")
                            .foregroundColor(.secondary)
                        Spacer()
                        buttonReset
                    }
                    Divider()
                }
                .padding(.top, 6)

                formContents
            }.padding(ConsoleFilters.formPadding)
        }
    }
#endif
}

// MARK: - ConsoleMessageFiltersView (Contents)

extension ConsoleMessageFiltersView {
    @ViewBuilder
    var formContents: some View {
#if os(tvOS) || os(watchOS)
        Section {
            buttonReset
        }
#endif
        if #available(iOS 14, tvOS 14, *) {
            ConsoleSharedFiltersView(viewModel: sharedCriteriaViewModel)
        }
#if os(iOS) || os(macOS)
        if #available(iOS 15, *) {
            generalSection
        }
#endif
        logLevelsSection
        labelsSection
    }

    var buttonReset: some View {
        Button("Reset") {
            viewModel.resetAll()
            sharedCriteriaViewModel.resetAll()
        }.disabled(!(viewModel.isButtonResetEnabled || sharedCriteriaViewModel.isButtonResetEnabled))
    }
}

// MARK: - ConsoleMessageFiltersView (Custom Filters)

#if os(iOS) || os(macOS)
@available(iOS 15, *)
extension ConsoleMessageFiltersView {
    var generalSection: some View {
        ConsoleFilterSection(
            isExpanded: $isGeneralSectionExpanded,
            header: { generalHeader },
            content: { generalContent }
        )
    }

    private var generalHeader: some View {
        ConsoleFilterSectionHeader(
            icon: "line.horizontal.3.decrease.circle", title: "Filters",
            color: .yellow,
            reset: { viewModel.resetFilters() },
            isDefault: viewModel.isDefaultFilters,
            isEnabled: $viewModel.criteria.isFiltersEnabled
        )
    }

#if os(iOS) || os(tvOS)
    @ViewBuilder
    private var generalContent: some View {
        customFiltersList
        if !viewModel.isDefaultFilters {
            Button(action: viewModel.addFilter) {
                Text("Add Filter").frame(maxWidth: .infinity)
            }
        }
    }
#else
    @ViewBuilder
    private var generalContent: some View {
        VStack {
            customFiltersList
        }.padding(.leading, -8)

        if !viewModel.isDefaultFilters {
            Button(action: viewModel.addFilter) {
                Image(systemName: "plus.circle")
            }.padding(.top, 6)
        }
    }
#endif

    private var customFiltersList: some View {
        ForEach(viewModel.filters) { filter in
            ConsoleCustomMessageFilterView(filter: filter, onRemove: viewModel.removeFilter, isRemoveHidden: viewModel.isDefaultFilters)
        }
    }
}
#endif

// MARK: - ConsoleMessageFiltersView (Log Levels)

extension ConsoleMessageFiltersView {
    var logLevelsSection: some View {
        ConsoleFilterSection(
            isExpanded: $isLevelsSectionExpanded,
            header: { logLevelsHeader },
            content: { logLevelsContent }
        )
    }

    private var logLevelsHeader: some View {
        ConsoleFilterSectionHeader(
            icon: "flag", title: "Levels",
            color: .accentColor,
            reset: { viewModel.criteria.logLevels = .default },
            isDefault: viewModel.criteria.logLevels == .default,
            isEnabled: $viewModel.criteria.logLevels.isEnabled
        )
    }

#if os(macOS)
    private var logLevelsContent: some View {
        HStack(spacing:0) {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("All", isOn: viewModel.bindingForTogglingAllLevels)
                    .accentColor(Color.secondary)
                    .foregroundColor(Color.secondary)
                HStack(spacing: 32) {
                    makeLevelsSection(levels: [.trace, .debug, .info, .notice])
                    makeLevelsSection(levels: [.warning, .error, .critical])
                }.fixedSize()
            }
            Spacer()
        }
    }

    private func makeLevelsSection(levels: [LoggerStore.Level]) -> some View {
        VStack(alignment: .leading) {
            Spacer()
            ForEach(levels, id: \.self) { level in
                Toggle(level.name.capitalized, isOn: viewModel.binding(forLevel: level))
            }
        }
    }
#else
    @ViewBuilder
    private var logLevelsContent: some View {
        ForEach(LoggerStore.Level.allCases, id: \.self) { level in
            Checkbox(level.name.capitalized, isOn: viewModel.binding(forLevel: level))
        }
        Button(viewModel.bindingForTogglingAllLevels.wrappedValue ? "Disable All" : "Enable All") {
            viewModel.bindingForTogglingAllLevels.wrappedValue.toggle()
        }
    }
#endif
}

// MARK: - ConsoleMessageFiltersView (Labels)

extension ConsoleMessageFiltersView {
    var labelsSection: some View {
        ConsoleFilterSection(
            isExpanded: $isLabelsSectionExpanded,
            header: { labelsHeader },
            content: { labelsContent }
        )
    }

    private var labelsHeader: some View {
        ConsoleFilterSectionHeader(
            icon: "tag", title: "Labels",
            color: .orange,
            reset: { viewModel.criteria.labels = .default },
            isDefault: viewModel.criteria.labels == .default,
            isEnabled: $viewModel.criteria.labels.isEnabled
        )
    }

#if os(macOS)
    private var labelsContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("All", isOn: viewModel.bindingForTogglingAllLabels)
                    .accentColor(Color.secondary)
                    .foregroundColor(Color.secondary)
                ForEach(viewModel.allLabels, id: \.self) { item in
                    Toggle(item.capitalized, isOn: viewModel.binding(forLabel: item))
                }
            }
            Spacer()
        }
    }
#else
    @ViewBuilder
    private var labelsContent: some View {
        let labels = viewModel.allLabels

        if labels.isEmpty {
            Text("No Labels")
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.secondary)
        } else {
            ForEach(labels.prefix(4), id: \.self) { item in
                Checkbox(item.capitalized, isOn: viewModel.binding(forLabel: item))
            }
            if labels.count > 4 {
                NavigationLink(destination: ConsoleFiltersLabelsPickerView(viewModel: viewModel)) {
                    Text("View All").foregroundColor(.blue)
                }
            }
        }
    }
#endif
}

#if DEBUG
struct ConsoleMessageFiltersView_Previews: PreviewProvider {
    static var previews: some View {
#if os(macOS)
        ConsoleMessageFiltersView(viewModel: makeMockViewModel(), sharedCriteriaViewModel: .init(store: .mock))
            .previewLayout(.fixed(width: ConsoleFilters.preferredWidth - 15, height: 700))
#else
        NavigationView {
            ConsoleMessageFiltersView(viewModel: makeMockViewModel(), sharedCriteriaViewModel: .init(store: .mock))
        }.navigationViewStyle(.stack)
#endif
    }
}

private func makeMockViewModel() -> ConsoleMessageSearchCriteriaViewModel {
    let viewModel = ConsoleMessageSearchCriteriaViewModel(store: .mock)
    viewModel.displayLabels(["Auth", "Network", "Analytics", "Home", "Storage"])
    return viewModel
}
#endif

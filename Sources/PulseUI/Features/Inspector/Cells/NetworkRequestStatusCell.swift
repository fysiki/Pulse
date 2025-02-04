// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

struct NetworkRequestStatusCell: View {
    let viewModel: NetworkRequestStatusCellModel

#if os(watchOS)
    var body: some View {
        HStack(spacing: spacing) {
            Text(viewModel.title)
                .lineLimit(3)
                .foregroundColor(viewModel.tintColor)
            Spacer()
            viewModel.duration.map(DurationLabel.init)
        }
        .font(.headline)
        .listRowBackground(Color.clear)
    }

#else
    var body: some View {
        HStack(spacing: spacing) {
            if #available(iOS 14, tvOS 14, *) {
                Text(Image(systemName: viewModel.imageName))
                    .foregroundColor(viewModel.tintColor)
            } else {
                Image(systemName: viewModel.imageName)
                    .foregroundColor(viewModel.tintColor)
            }
            Text(viewModel.title)
                .lineLimit(1)
                .foregroundColor(viewModel.tintColor)
            Spacer()
            viewModel.duration.map(DurationLabel.init)
        }
#if os(tvOS)
        .font(.system(size: 38, weight: .bold))
        .padding(.top, 16)
        .padding(.bottom, 16)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
#else
        .font(.headline)
#endif
    }

    #endif
}

struct NetworkRequestStatusCellModel {
    let imageName: String
    let title: String
    let tintColor: Color
    fileprivate let duration: DurationViewModel?

    init(task: NetworkTaskEntity) {
        switch task.state {
        case .pending:
            imageName = "clock.fill"
            title = ProgressViewModel.title(for: task).capitalized
            tintColor = .orange
        case .success:
            imageName = "checkmark.circle.fill"
            title = StatusCodeFormatter.string(for: Int(task.statusCode))
            tintColor = .green
        case .failure:
            imageName = "exclamationmark.octagon.fill"
            title = ErrorFormatter.shortErrorDescription(for: task)
            tintColor = .red
        }
        duration = DurationViewModel(task: task)
    }

    init(transaction: NetworkTransactionMetricsEntity) {
        if let response = transaction.response {
            if response.isSuccess {
                imageName = "checkmark.circle.fill"
                title = StatusCodeFormatter.string(for: Int(response.statusCode))
                tintColor = .green
            } else {
                imageName = "exclamationmark.octagon.fill"
                title = StatusCodeFormatter.string(for: Int(response.statusCode))
                tintColor = .red
            }
        } else {
            imageName = "exclamationmark.octagon.fill"
            title = "No Response"
            tintColor = .secondary
        }
        duration = DurationViewModel(transaction: transaction)
    }

    var uiTintColor: UXColor {
        if #available(iOS 14, tvOS 14, *) {
            return UXColor(tintColor)
        } else {
            return UXColor.label
        }
    }
}

// MARK: - Helpers

private struct DurationLabel: View {
    @ObservedObject var viewModel: DurationViewModel

    var body: some View {
        if let duration = viewModel.duration {
            Text(duration)
                .backport.monospacedDigit()
                .lineLimit(1)
                .font(.system(.callout, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

private final class DurationViewModel: ObservableObject {
    @Published var duration: String?

    private weak var timer: Timer?

    init(task: NetworkTaskEntity) {
        switch task.state {
        case .pending:
            // TODO: Update in sync with the object (creation date is not the same as fetch start date)
//            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
//                self?.refreshPendingDuration(task: task)
//            }
            duration = nil
        case .failure, .success:
            duration = DurationFormatter.string(from: task.duration, isPrecise: false)
        }
    }

    init?(transaction: NetworkTransactionMetricsEntity) {
        guard let duration = transaction.timing.duration else {
            return nil
        }
        self.duration = DurationFormatter.string(from: duration, isPrecise: false)
    }

    private func refreshPendingDuration(task: NetworkTaskEntity) {
        let duration = Date().timeIntervalSince(task.createdAt)
        if duration > 0 {
            self.duration = DurationFormatter.string(from: duration, isPrecise: false)
        }
        if task.state != .pending {
            timer?.invalidate()
        }
    }
}

#if os(tvOS)
private let spacing: CGFloat = 20
#else
private let spacing: CGFloat? = nil
#endif

private extension NetworkResponseEntity {
    var isSuccess: Bool {
        (200..<400).contains(statusCode)
    }
}

#if DEBUG
struct NetworkRequestStatusCell_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                ForEach(MockTask.allEntities, id: \.objectID) { task in
                    NetworkRequestStatusCell(viewModel: .init(task: task))
                }
            }
#if os(macOS)
            .frame(width: ConsoleView.contentColumnWidth)
#endif
        }
    }
}
#endif

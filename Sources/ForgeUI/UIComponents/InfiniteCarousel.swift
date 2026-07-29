//
//  CompatInfiniteCarousel.swift
//  Robyn
//
//  Created by Dino Catalinac on 02.03.2026..
//

import Algorithms
import ForgeCore
import SwiftUI

public struct InfiniteCarousel<Items: RandomAccessCollection, Content: View>: View
where Items.Element: Identifiable, Items.Index == Int {
    @Environment(\.scenePhase) private var scenePhase

    let items: Items
    @Binding var activeIndex: Int
    let pageOffset: Int
    let interval: TimeInterval?
    let pageWidthRatio: CGFloat
    let spacing: CGFloat
    let sizesToActivePage: Bool
    let content: (Items.Element) -> Content

    @State private var frameWidth: CGFloat = 0
    @State private var pageHeights: [Int: CGFloat] = [:]
    @State private var scrollPosition: Int?
    @State private var isUserInteracting: Bool = false
    @State private var isScrollingProgrammatically: Bool = false
    @State private var scrollDisabled: Bool = false
    @State private var shouldUpdateScrollPosition: Bool = true
    @State private var autoScrollTask: Task<Void, Error>?

    /// Creates a carousel that wraps seamlessly around its item collection.
    ///
    /// - Parameters:
    ///   - items: The items displayed by the carousel.
    ///   - activeIndex: The index of the currently selected item.
    ///   - pageOffset: The number of duplicated pages placed at each edge to support seamless wrapping.
    ///   - interval: The automatic paging interval, or `nil` to disable automatic paging.
    ///   - pageWidthRatio: The proportion of the carousel width occupied by one page.
    ///   - spacing: Horizontal padding applied to each page.
    ///   - sizesToActivePage: Whether the carousel adopts the active page's intrinsic height.
    ///   - content: A view builder that creates a page for an item.
    public init(
        items: Items,
        activeIndex: Binding<Int>,
        pageOffset: Int,
        interval: TimeInterval?,
        pageWidthRatio: CGFloat = 1,
        spacing: CGFloat = 0,
        sizesToActivePage: Bool = false,
        @ViewBuilder content: @escaping (Items.Element) -> Content
    ) {
        self.items = items
        self._activeIndex = activeIndex
        self.pageOffset = pageOffset
        self.interval = interval
        self.pageWidthRatio = pageWidthRatio
        self.spacing = spacing
        self.sizesToActivePage = sizesToActivePage
        self.content = content
    }

    private var pageWidth: CGFloat {
        frameWidth * pageWidthRatio
    }

    private var contentMargin: CGFloat {
        (frameWidth - pageWidth) / 2
    }

    public var body: some View {
        scrollView {
            ForEach(0..<items.count + (2 * pageOffset), id: \.self) { index in
                if let item = getItem(at: index) {
                    content(item)
                        .padding(.horizontal, spacing)
                        .frame(width: pageWidth)
                        .fixedSize(horizontal: false, vertical: sizesToActivePage)
                        .onGeometryChange(for: CGFloat.self) { geometry in
                            geometry.size.height.rounded(.up)
                        } action: { height in
                            guard sizesToActivePage else {
                                return
                            }

                            pageHeights[index] = height
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            guard !isScrollingProgrammatically else {
                                return
                            }
                            Task { await scroll(to: index, animationDuration: 0.4) }
                        }
                        .id(index)
                }
            }
        }
        .contentMargins(.horizontal, contentMargin, for: .scrollContent)
        .scrollPosition(id: $scrollPosition)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .scrollIndicators(.hidden)
        .allowsHitTesting(!scrollDisabled && !isScrollingProgrammatically)
        .onScrollPhaseChange { _, newPhase in
            let wasInteracting = isUserInteracting

            switch newPhase {
            case .tracking, .interacting, .decelerating:
                isUserInteracting = true
            default:
                isUserInteracting = false
            }

            if isUserInteracting {
                stopAutoScroll()
            } else if wasInteracting {
                startAutoScroll()
                updateScrollPosition()
            }
        }
        .onChange(of: scrollPosition) {
            shouldUpdateScrollPosition = false
            updateActiveIndex()

            Task {
                await Task.yield()
                shouldUpdateScrollPosition = true
            }
        }
        .onChange(of: activeIndex, initial: true) {
            if shouldUpdateScrollPosition && !isScrollingProgrammatically {
                scrollPosition = activeIndex + pageOffset
                startAutoScroll()
            }
        }
        .onDisappear {
            stopAutoScroll()
        }
        .onChange(of: interval) {
            startAutoScroll()
        }
        .onChange(of: items.count) {
            startAutoScroll()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                startAutoScroll()
            case .background:
                stopAutoScroll()
            default:
                return
            }
        }
        .sensoryFeedback(.selection, trigger: interval == nil ? activeIndex : nil)
        .frame(maxWidth: .infinity)
        .frame(height: activePageHeight, alignment: .top)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: {
            guard frameWidth == 0 else {
                return
            }
            frameWidth = $0.width
        }
    }

    private var activePageHeight: CGFloat? {
        guard sizesToActivePage, let scrollPosition else {
            return nil
        }

        return pageHeights[scrollPosition]
    }

    @ViewBuilder
    private func scrollView<ScrollableContent: View>(@ViewBuilder _ content: () -> ScrollableContent) -> some View {
        // Workaround for a weird UI glitch where LazyHStack would sometimes abruptly hide a child view on auto-scroll.
        if interval.isSome {
            ScrollView(.horizontal) {
                HStack(spacing: .zero, content: content)
                    .scrollTargetLayout()
            }
        } else {
            ScrollView(.horizontal) {
                LazyHStack(spacing: .zero, content: content)
                    .scrollTargetLayout()
            }
        }
    }

    private func getItem(at index: Int) -> Items.Element? {
        let offsetIndex = index - pageOffset
        let count = items.count

        guard count > 0 else {
            return nil
        }

        var wrapped = offsetIndex % count
        if wrapped < 0 {
            wrapped += count
        }

        return items[safe: wrapped]
    }

    private func startAutoScroll() {
        stopAutoScroll()

        guard let interval, interval > 0, items.count > pageOffset else {
            return
        }

        autoScrollTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(interval))

                guard pageOffset > 0, let currentScrollPosition = scrollPosition else {
                    break
                }

                guard !isUserInteracting && !isScrollingProgrammatically else {
                    continue
                }

                await scroll(to: currentScrollPosition + 1, animationDuration: 0.8)
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }

    private func scroll(to pageIndex: Int, animationDuration: TimeInterval) async {
        isScrollingProgrammatically = true
        defer { isScrollingProgrammatically = false }

        if animationDuration > 0 {
            withAnimation(.spring(duration: animationDuration)) {
                scrollPosition = pageIndex
            }
            try? await Task.sleep(for: .seconds(animationDuration + 0.4))
        } else {
            scrollPosition = pageIndex
        }

        updateScrollPosition()
    }

    private func updateScrollPosition() {
        guard let currentScrollPosition = scrollPosition, pageOffset > 0, !items.isEmpty else {
            return
        }

        if currentScrollPosition < pageOffset {
            let undershoot = pageOffset - currentScrollPosition
            scrollPosition = items.count + pageOffset - undershoot
        } else if currentScrollPosition >= items.count + pageOffset {
            let overshoot = currentScrollPosition - (items.count + pageOffset)
            scrollPosition = pageOffset + overshoot
        }
    }

    private func updateActiveIndex() {
        guard let currentScrollPosition = scrollPosition, !items.isEmpty else {
            return
        }

        if currentScrollPosition < pageOffset {
            scrollDisabled = true
            let undershoot = pageOffset - currentScrollPosition
            activeIndex = max(0, items.count - undershoot)
        } else if currentScrollPosition >= items.count + pageOffset {
            scrollDisabled = true
            let overshoot = currentScrollPosition - (items.count + pageOffset)
            activeIndex = overshoot % items.count
        } else {
            scrollDisabled = false
            activeIndex = currentScrollPosition - pageOffset
        }
    }
}

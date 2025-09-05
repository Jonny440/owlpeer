//
//  MindMapView.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import SwiftUI
import WebKit

struct MindMapViewFull: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: MindMapViewModel
    @State private var webViewLoading = true
    
    let id: UUID
    
    init(id: UUID) {
        self.id = id
        _viewModel = StateObject(wrappedValue: MindMapViewModel(videoUUID: id))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(localized: "MindMap")
                    .font(.custom("Futura-Bold", size: 22))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }
            .padding()
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Content
            MindMapView(videoUUID: id)
                .background(Color.white)
        }
        .background(Color.background)
        .onAppear {
            Task {
                await viewModel.fetch()
            }
        }
    }
}

// MARK: - Position and Layout Models
struct NodePosition {
    let id: UUID
    var position: CGPoint
    let level: Int
    let angle: Double
}

// MARK: - Mind Map View
struct MindMapView: View {
    @StateObject private var viewModel: MindMapViewModel
    @State private var nodePositions: [UUID: CGPoint] = [:]
    @State private var dragOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var selectedNodeId: UUID?
    @State private var canvasSize: CGSize = .zero
    @State private var lastScaleValue: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var lastPanValue: CGSize = .zero
    
    private let nodeWidth: CGFloat = 200
    private let nodeHeight: CGFloat = 80
    private let levelSpacing: CGFloat = 250
    private let minNodeDistance: CGFloat = 220 // Increased to prevent overlap
    
    init(videoUUID: UUID) {
        self._viewModel = StateObject(wrappedValue: MindMapViewModel(videoUUID: videoUUID))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                
                switch viewModel.state {
                case .loading:
                    ProgressView("Loading Mind Map...")
                        .scaleEffect(1.2)
                    
                case .loaded(let mindmap):
                    mindMapContent(mindmap: mindmap, geometry: geometry)
                    
                case .error(let message):
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text(localized: "Error")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(localized: message)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Retry") {
                            Task {
                                await viewModel.fetch()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    
                case .noMindMap:
                    VStack(spacing: 20) {
                        Image(systemName: "brain")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text(localized: "No Mind Map Available")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(localized: "Generate a mind map for this video")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button("Generate Mind Map") {
                            Task {
                                await viewModel.generateMindMap()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isGenerating)
                    }
                    .padding()
                }
            }
        }
        .task {
            await viewModel.fetch()
        }
    }
    
    @ViewBuilder
    private func mindMapContent(mindmap: MindMapRootWrapper, geometry: GeometryProxy) -> some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            ZStack {
                // Connection lines
                Canvas { context, size in
                    drawConnections(context: context, rootNode: mindmap.root)
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                
                // Nodes
                ForEach(getAllNodes(from: mindmap.root), id: \.id) { node in
                    NodeView(
                        node: node,
                        isRoot: node.id == mindmap.root.id,
                        isSelected: selectedNodeId == node.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedNodeId = selectedNodeId == node.id ? nil : node.id
                            }
                        }
                    )
                    .position(getNodePosition(for: node.id))
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .scaleEffect(scale)
            .offset(panOffset)
        }
        .onAppear {
            calculateImprovedRadialLayout(rootNode: mindmap.root, canvasSize: geometry.size)
        }
        .gesture(
            // Combined gesture for better zoom and pan
            SimultaneousGesture(
                // Improved magnification gesture
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScaleValue
                        lastScaleValue = value
                        
                        let newScale = scale * delta
                        scale = max(0.3, min(newScale, 3.0))
                    }
                    .onEnded { value in
                        lastScaleValue = 1.0
                    },
                
                // Pan gesture
                DragGesture()
                    .onChanged { value in
                        panOffset = CGSize(
                            width: lastPanValue.width + value.translation.width,
                            height: lastPanValue.height + value.translation.height
                        )
                    }
                    .onEnded { value in
                        lastPanValue = panOffset
                    }
            )
        )
        // Double tap to reset zoom and position
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                scale = 1.0
                panOffset = .zero
                lastPanValue = .zero
            }
        }
    }
    
    private func calculateImprovedRadialLayout(rootNode: MindMapNode, canvasSize: CGSize) {
        let centerX = max(canvasSize.width / 2, 1000)
        let centerY = max(canvasSize.height / 2, 800)
        
        // Position root node at center
        nodePositions[rootNode.id] = CGPoint(x: centerX, y: centerY)
        
        guard let children = rootNode.children, !children.isEmpty else {
            self.canvasSize = CGSize(width: centerX * 2, height: centerY * 2)
            return
        }
        
        // Calculate positions for first level children with collision avoidance
        var occupiedAreas: [CGRect] = []
        let rootRect = CGRect(
            x: centerX - nodeWidth/2,
            y: centerY - nodeHeight/2,
            width: nodeWidth,
            height: nodeHeight
        )
        occupiedAreas.append(rootRect)
        
        let baseRadius = levelSpacing * 1.8
        
        for (index, child) in children.enumerated() {
            let preferredAngle = Double(index) * (2 * Double.pi / Double(children.count)) - Double.pi / 2
            
            let position = findNonOverlappingPosition(
                preferredAngle: preferredAngle,
                radius: baseRadius,
                center: CGPoint(x: centerX, y: centerY),
                occupiedAreas: occupiedAreas,
                nodeSize: CGSize(width: nodeWidth, height: nodeHeight)
            )
            
            nodePositions[child.id] = position
            
            let childRect = CGRect(
                x: position.x - nodeWidth/2,
                y: position.y - nodeHeight/2,
                width: nodeWidth,
                height: nodeHeight
            )
            occupiedAreas.append(childRect)
            
            // Position grandchildren with improved spacing
            positionChildrenWithCollisionAvoidance(
                parent: child,
                parentPosition: position,
                parentAngle: preferredAngle,
                level: 2,
                occupiedAreas: &occupiedAreas
            )
        }
        
        // Calculate canvas size based on positioned nodes
        calculateCanvasSize()
    }
    
    private func findNonOverlappingPosition(
        preferredAngle: Double,
        radius: CGFloat,
        center: CGPoint,
        occupiedAreas: [CGRect],
        nodeSize: CGSize
    ) -> CGPoint {
        let maxAttempts = 36 // Check every 10 degrees
        let angleStep = Double.pi / 18 // 10 degrees
        
        for attempt in 0..<maxAttempts {
            let angle = preferredAngle + (Double(attempt / 2) * angleStep * (attempt % 2 == 0 ? 1 : -1))
            let testRadius = radius + CGFloat(attempt / 8) * 50 // Gradually increase radius
            
            let position = CGPoint(
                x: center.x + cos(angle) * testRadius,
                y: center.y + sin(angle) * testRadius
            )
            
            let testRect = CGRect(
                x: position.x - nodeSize.width/2,
                y: position.y - nodeSize.height/2,
                width: nodeSize.width,
                height: nodeSize.height
            ).insetBy(dx: -10, dy: -10) // Add padding
            
            let overlaps = occupiedAreas.contains { rect in
                rect.intersects(testRect)
            }
            
            if !overlaps {
                return position
            }
        }
        
        // Fallback: use preferred position with increased radius
        return CGPoint(
            x: center.x + cos(preferredAngle) * (radius + 100),
            y: center.y + sin(preferredAngle) * (radius + 100)
        )
    }
    
    private func positionChildrenWithCollisionAvoidance(
        parent: MindMapNode,
        parentPosition: CGPoint,
        parentAngle: Double,
        level: Int,
        occupiedAreas: inout [CGRect]
    ) {
        guard let children = parent.children, !children.isEmpty, level < 5 else { return }
        
        let childRadius = levelSpacing * 0.9
        let angleSpread = min(Double.pi / 2, Double.pi / max(1, Double(children.count - 1))) // Dynamic spread
        
        for (index, child) in children.enumerated() {
            let angleOffset = angleSpread * (Double(index) / max(1, Double(children.count - 1)) - 0.5)
            let childAngle = parentAngle + angleOffset
            
            let position = findNonOverlappingPosition(
                preferredAngle: childAngle,
                radius: childRadius,
                center: parentPosition,
                occupiedAreas: occupiedAreas,
                nodeSize: CGSize(width: nodeWidth * 0.8, height: nodeHeight * 0.8)
            )
            
            nodePositions[child.id] = position
            
            let childRect = CGRect(
                x: position.x - nodeWidth * 0.4,
                y: position.y - nodeHeight * 0.4,
                width: nodeWidth * 0.8,
                height: nodeHeight * 0.8
            )
            occupiedAreas.append(childRect)
            
            // Continue with next level
            positionChildrenWithCollisionAvoidance(
                parent: child,
                parentPosition: position,
                parentAngle: childAngle,
                level: level + 1,
                occupiedAreas: &occupiedAreas
            )
        }
    }
    
    private func calculateCanvasSize() {
        guard !nodePositions.isEmpty else {
            canvasSize = CGSize(width: 1600, height: 1200)
            return
        }
        
        let positions = nodePositions.values
        let minX = positions.map { $0.x }.min() ?? 0
        let maxX = positions.map { $0.x }.max() ?? 0
        let minY = positions.map { $0.y }.min() ?? 0
        let maxY = positions.map { $0.y }.max() ?? 0
        
        let padding: CGFloat = 300
        canvasSize = CGSize(
            width: max(1600, maxX - minX + padding * 2),
            height: max(1200, maxY - minY + padding * 2)
        )
    }
    
    private func getNodePosition(for nodeId: UUID) -> CGPoint {
        return nodePositions[nodeId] ?? CGPoint(x: 100, y: 100)
    }
    
    private func getAllNodes(from root: MindMapNode) -> [MindMapNode] {
        var nodes: [MindMapNode] = [root]
        
        if let children = root.children {
            for child in children {
                nodes.append(contentsOf: getAllNodes(from: child))
            }
        }
        
        return nodes
    }
    
    private func drawConnections(context: GraphicsContext, rootNode: MindMapNode) {
        drawNodeConnections(context: context, node: rootNode)
    }
    
    private func drawNodeConnections(context: GraphicsContext, node: MindMapNode) {
        guard let children = node.children else { return }
        
        let parentPos = nodePositions[node.id] ?? .zero
        
        for child in children {
            let childPos = nodePositions[child.id] ?? .zero
            
            // Create curved path for better visual appeal
            let path = Path { path in
                let controlPoint = CGPoint(
                    x: (parentPos.x + childPos.x) / 2,
                    y: (parentPos.y + childPos.y) / 2 - 30
                )
                path.move(to: parentPos)
                path.addQuadCurve(to: childPos, control: controlPoint)
            }
            
            // Draw connection line
            context.stroke(
                path,
                with: .color(.blue.opacity(0.7)),
                style: StrokeStyle(
                    lineWidth: 2.5,
                    lineCap: .round,
                    dash: [10, 5]
                )
            )
            
            // Draw arrow at the end
            drawArrow(context: context, from: parentPos, to: childPos)
            
            // Recursively draw connections for children
            drawNodeConnections(context: context, node: child)
        }
    }
    
    private func drawArrow(context: GraphicsContext, from start: CGPoint, to end: CGPoint) {
        let arrowLength: CGFloat = 15
        let arrowAngle = Double.pi / 5 // 36 degrees for better arrow
        
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = atan2(dy, dx)
        
        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        
        let arrowPath = Path { path in
            path.move(to: end)
            path.addLine(to: arrowPoint1)
            path.move(to: end)
            path.addLine(to: arrowPoint2)
        }
        
        context.stroke(arrowPath, with: .color(.blue.opacity(0.7)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }
}

// MARK: - Node View
struct NodeView: View {
    let node: MindMapNode
    let isRoot: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(localized: node.message)
                .font(isRoot ? .title2 : .system(size: 14, weight: .medium))
                .fontWeight(isRoot ? .bold : .medium)
                .lineLimit(isRoot ? 3 : 2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            if let description = node.description, isSelected && !isRoot {
                Text(localized: description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: isRoot ? 220 : 180, height: isSelected && !isRoot ? 100 : 80)
        .background(
            RoundedRectangle(cornerRadius: isRoot ? 18 : 14)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isRoot ? 18 : 14)
                .stroke(borderColor, lineWidth: isSelected ? 3 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .onTapGesture {
            onTap()
        }
    }
    
    private var backgroundColor: LinearGradient {
        if isRoot {
            return LinearGradient(
                colors: [Color.purple.opacity(0.9), Color.indigo.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isSelected {
            return LinearGradient(
                colors: [Color.green.opacity(0.8), Color.teal.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.orange.opacity(0.8), Color.red.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .white.opacity(0.9)
        } else {
            return .clear
        }
    }
}

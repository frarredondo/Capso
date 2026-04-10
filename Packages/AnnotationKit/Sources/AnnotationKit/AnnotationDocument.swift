// Packages/AnnotationKit/Sources/AnnotationKit/AnnotationDocument.swift
import Foundation
import CoreGraphics
import Observation

@MainActor
@Observable
public final class AnnotationDocument {
    public let imageSize: CGSize
    public private(set) var objects: [any AnnotationObject] = []
    public private(set) var selectedObjectID: ObjectID?

    private var undoStack: [[(any AnnotationObject)]] = []
    private var redoStack: [[(any AnnotationObject)]] = []

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public init(imageSize: CGSize) {
        self.imageSize = imageSize
    }

    public func addObject(_ object: any AnnotationObject) {
        pushUndo()
        objects.append(object)
        selectedObjectID = object.id
    }

    public func removeObject(id: ObjectID) {
        pushUndo()
        objects.removeAll { $0.id == id }
        if selectedObjectID == id { selectedObjectID = nil }
    }

    public func removeSelected() {
        guard let id = selectedObjectID else { return }
        removeObject(id: id)
    }

    public func selectObject(id: ObjectID?) {
        selectedObjectID = id
    }

    public func clearSelection() {
        selectedObjectID = nil
    }

    public var selectedObject: (any AnnotationObject)? {
        guard let id = selectedObjectID else { return nil }
        return objects.first { $0.id == id }
    }

    public func objectAt(point: CGPoint, threshold: CGFloat = 8) -> (any AnnotationObject)? {
        for object in objects.reversed() {
            if object.hitTest(point: point, threshold: threshold) {
                return object
            }
        }
        return nil
    }

    public func moveObject(id: ObjectID, by delta: CGSize) {
        guard let obj = objects.first(where: { $0.id == id }) else { return }
        obj.move(by: delta)
    }

    public func beginDrag() {
        pushUndo()
    }

    private func pushUndo() {
        undoStack.append(objects.map { $0.copy() })
        redoStack.removeAll()
    }

    public func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        redoStack.append(objects.map { $0.copy() })
        objects = snapshot
        selectedObjectID = nil
    }

    public func redo() {
        guard let snapshot = redoStack.popLast() else { return }
        undoStack.append(objects.map { $0.copy() })
        objects = snapshot
        selectedObjectID = nil
    }
}

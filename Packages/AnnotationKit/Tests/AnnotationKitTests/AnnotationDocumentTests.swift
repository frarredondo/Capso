// Packages/AnnotationKit/Tests/AnnotationKitTests/AnnotationDocumentTests.swift
import Testing
import Foundation
import CoreGraphics
@testable import AnnotationKit

@Suite("AnnotationDocument")
struct AnnotationDocumentTests {
    @Test("Add and remove objects")
    @MainActor
    func addRemove() {
        let doc = AnnotationDocument(imageSize: CGSize(width: 800, height: 600))
        let arrow = ArrowObject(start: .zero, end: CGPoint(x: 100, y: 100))
        doc.addObject(arrow)
        #expect(doc.objects.count == 1)
        doc.removeObject(id: arrow.id)
        #expect(doc.objects.count == 0)
    }

    @Test("Undo and redo add")
    @MainActor
    func undoRedo() {
        let doc = AnnotationDocument(imageSize: CGSize(width: 800, height: 600))
        let arrow = ArrowObject(start: .zero, end: CGPoint(x: 100, y: 100))
        doc.addObject(arrow)
        #expect(doc.objects.count == 1)
        #expect(doc.canUndo)

        doc.undo()
        #expect(doc.objects.count == 0)
        #expect(doc.canRedo)

        doc.redo()
        #expect(doc.objects.count == 1)
    }

    @Test("Selection")
    @MainActor
    func selection() {
        let doc = AnnotationDocument(imageSize: CGSize(width: 800, height: 600))
        let arrow = ArrowObject(start: .zero, end: CGPoint(x: 100, y: 100))
        doc.addObject(arrow)
        doc.selectObject(id: arrow.id)
        #expect(doc.selectedObjectID == arrow.id)
        doc.clearSelection()
        #expect(doc.selectedObjectID == nil)
    }
}

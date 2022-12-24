// MARK: - NoPotentialAttachmentError

struct NoPotentialAttachmentError: Error {}

// MARK: - ActiveRouteNotFound

struct ActiveRouteNotFound: Error {}

// MARK: - NotAttachedError

struct NotAttachedError: Error {}

// MARK: - NoModelAttached

struct NoModelAttached<M: Model>: Error {
  init(attachmentPoint: AttachmentPoint<M>, expectedModel: M) {
    debugDescription =
      """
      Tried to detach \(expectedModel.self) from \(attachmentPoint.self) but it was not attached.
      AttachmentPoint: \(attachmentPoint)
      expected model: \(expectedModel)
      """
  }

  let debugDescription: String
}

// MARK: - UnexpectedModelAttached

struct UnexpectedModelAttached<M: Model>: Error {
  init(attachmentPoint: AttachmentPoint<M>, oldModel: M, newModel: M) {
    debugDescription =
      """
      Tried to attach \(newModel.self) to \(attachmentPoint.self) but it had an attached model.
      AttachmentPoint: \(attachmentPoint)
      new model: \(newModel)
      unexpected attached model: \(oldModel)
      """
  }

  let debugDescription: String
}

// MARK: - UnexpectedModel

struct UnexpectedModel<M: Model>: Error {
  init(oldModel: M, newModel: M) {
    debugDescription =
      """
      Tried to attach \(newModel.self) but it had an attached model.
      new model: \(newModel)
      unexpected attached model: \(oldModel)
      """
  }

  let debugDescription: String
}

// MARK: - UnexpectedModelUnion

struct UnexpectedModelUnion<Union>: Error {
  init(oldModel: Union, newModel: Union) {
    debugDescription =
      """
      Tried to attach \(newModel.self) but it had an attached model.
      new model union: \(newModel)
      unexpected attached model union: \(oldModel)
      """
  }

  let debugDescription: String
}

// MARK: - UnexpectedAttachmentState

struct UnexpectedAttachmentState<M: Model>: Error {
  init(oldAttachment: [any Model], newAttachment: [any Model]) {
    debugDescription =
      """
      Tried to update attached models \(M.self) but current state was unexpected.
      new model: \(oldAttachment)
      unexpected attached model: \(newAttachment)
      """
  }

  let debugDescription: String
}

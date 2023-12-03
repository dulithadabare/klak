//
//  HamuwemuError.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-29.
//

import Foundation

enum PromiseError: Error {
    case timeout
}

enum AuthError: Error {
    case userIdNil
    case userNil
    case idTokenNil
    case verificationIdNil
    case deviceTokenNil
}

enum ApiError: Error {
    case jsonEncodeError
    case serverError
    case errorCreatingChatGroup(error: Error)
    case errorSendingMessage
}

enum PersistenceError: Error {
    case wrongDataFormat(error: Error)
    case creationError
    case batchInsertError
    case batchDeleteError
    case persistentHistoryChangeError
    case unexpectedError(error: Error)
}

extension PersistenceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .wrongDataFormat(let error):
            return NSLocalizedString("Could not digest the fetched data. \(error.localizedDescription)", comment: "")
        case .creationError:
            return NSLocalizedString("Failed to create a new Quake object.", comment: "")
        case .batchInsertError:
            return NSLocalizedString("Failed to execute a batch insert request.", comment: "")
        case .batchDeleteError:
            return NSLocalizedString("Failed to execute a batch delete request.", comment: "")
        case .persistentHistoryChangeError:
            return NSLocalizedString("Failed to execute a persistent history change request.", comment: "")
        case .unexpectedError(let error):
            return NSLocalizedString("Received unexpected error. \(error.localizedDescription)", comment: "")
        }
    }
}

extension PersistenceError: Identifiable {
    var id: String? {
        errorDescription
    }
}

enum HamuwemuAuthError: Error {
    case wrongDataFormat(error: Error)
    case missingPublicKey
    case imageCompressionError
    case missingThumbnail
    case imageNormalizationError
    case blurHashGenerationError
    case unexpectedError(error: Error)
}

extension HamuwemuAuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .wrongDataFormat(let error):
            return NSLocalizedString("Could not digest the fetched data. \(error.localizedDescription)", comment: "")
        case .missingPublicKey:
            return NSLocalizedString("Could not find public key for current user.", comment: "")
        case .imageCompressionError:
            return NSLocalizedString("Failed to compress image", comment: "")
        case .missingThumbnail:
            return NSLocalizedString("Image thumbnail not found", comment: "")
        case .imageNormalizationError:
            return NSLocalizedString("Failed to normalize image", comment: "")
        case .blurHashGenerationError:
            return NSLocalizedString("Failed to generate blurhash", comment: "")
        case .unexpectedError(let error):
            return NSLocalizedString("Received unexpected error. \(error.localizedDescription)", comment: "")
        }
    }
}

extension HamuwemuAuthError: Identifiable {
    var id: String? {
        errorDescription
    }
}

enum QuakeError: Error {
    case wrongDataFormat(error: Error)
    case missingData
    case creationError
    case batchInsertError
    case batchDeleteError
    case persistentHistoryChangeError
    case unexpectedError(error: Error)
}

extension QuakeError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .wrongDataFormat(let error):
            return NSLocalizedString("Could not digest the fetched data. \(error.localizedDescription)", comment: "")
        case .missingData:
            return NSLocalizedString("Found and will discard a quake missing a valid code, magnitude, place, or time.", comment: "")
        case .creationError:
            return NSLocalizedString("Failed to create a new Quake object.", comment: "")
        case .batchInsertError:
            return NSLocalizedString("Failed to execute a batch insert request.", comment: "")
        case .batchDeleteError:
            return NSLocalizedString("Failed to execute a batch delete request.", comment: "")
        case .persistentHistoryChangeError:
            return NSLocalizedString("Failed to execute a persistent history change request.", comment: "")
        case .unexpectedError(let error):
            return NSLocalizedString("Received unexpected error. \(error.localizedDescription)", comment: "")
        }
    }
}

extension QuakeError: Identifiable {
    var id: String? {
        errorDescription
    }
}

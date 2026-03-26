//
//  AppleSignInService.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 12/17/25.
//
import AuthenticationServices
import UIKit

final class AppleSignInService: NSObject {
    // Keep a strong reference so it doesn't deallocate mid-flow
    private var activeDelegate: SignInDelegate?

    func startSignIn(presentationAnchor: ASPresentationAnchor? = nil) async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = SignInDelegate(
                continuation: continuation,
                onFinish: { [weak self] in self?.activeDelegate = nil }
            )

            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            delegate.presentationAnchor = presentationAnchor ?? Self.defaultAnchor()

            // Hold a strong reference during the request
            self.activeDelegate = delegate
            controller.performRequests()
        }
    }

    private static func defaultAnchor() -> ASPresentationAnchor {
        // iOS: find a key window. Adjust for visionOS/macOS if needed.
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

private final class SignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>
    var presentationAnchor: ASPresentationAnchor?
    let onFinish: () -> Void

    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>, onFinish: @escaping () -> Void) {
        self.continuation = continuation
        self.onFinish = onFinish
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentationAnchor ?? ASPresentationAnchor()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation.resume(returning: credential)
        } else {
            continuation.resume(throwing: NSError(domain: "SignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing AppleID credential"]))
        }
        onFinish()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
        onFinish()
    }
}

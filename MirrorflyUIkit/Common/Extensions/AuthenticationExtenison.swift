//
//  AuthenticationExtenison.swift
//  MirrorflyUIkit
//
//  Created by Amose Vasanth on 21/03/23.
//

import Foundation
import LocalAuthentication

extension LAContext {
    enum BiometricType: String {
        case none
        case touchID
        case faceID
    }

    var biometricType: BiometricType {
        var error: NSError?

        guard self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch self.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .none:
            return .none
        @unknown default:
            #warning("Handle new Biometric type")
        }

        return  self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
    }
}

//
//  IntegerExtension.swift
//  MirrorflyUIkit
//
//  Created by User on 07/09/21.
//

import Foundation
extension Int32 {
    var byteSize: String {
        return ByteCountFormatter().string(fromByteCount: Int64(self))
    }
}

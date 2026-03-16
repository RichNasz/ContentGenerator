//
//  CGSpecsUTType.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import UniformTypeIdentifiers

extension UTType {
    /// The uniform type identifier for .cgspecs packages.
    nonisolated static var cgspecs: UTType {
        UTType(exportedAs: "com.naszcyniec.cgspecs", conformingTo: .package)
    }
}

//
//  Other.swift
//  VillainArc
//
//  Created by Fernando Caudillo Tafoya on 5/15/24.
//
import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
//    func endEditing(_ force: Bool) {
//        UIApplication.shared.connectedScenes
//            .compactMap { $0 as? UIWindowScene }
//            .flatMap { $0.windows }
//            .first { $0.isKeyWindow }?
//            .endEditing(force)
//    }
}
#endif

func formattedWeight(_ weight: Double) -> String {
    let weightInt = Int(weight)
    return weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(weightInt)" : String(format: "%.1f", weight)
}

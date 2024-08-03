import SwiftUI

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    func isSameDayAs(_ date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    static func from(_ month: Int, _ day: Int, _ year: Int) -> Date {
        var components = DateComponents()
        components.month = month
        components.day = day
        components.year = year
        
        let calendar = Calendar.current
        return calendar.date(from: components)!
    }
}
extension View {
    @ViewBuilder
    func hSpacing(_ alignment: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    @ViewBuilder
    func vSpacing(_ alignment: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
}

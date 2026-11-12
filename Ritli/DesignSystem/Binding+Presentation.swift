import SwiftUI

extension Binding where Value == Bool {
    /// Presents while `item` holds a value and clears it on dismissal, for
    /// alerts driven by an optional message or pending item.
    init<Item>(isPresenting item: Binding<Item?>) {
        self.init(
            get: { item.wrappedValue != nil },
            set: { isPresented in
                if !isPresented {
                    item.wrappedValue = nil
                }
            }
        )
    }
}

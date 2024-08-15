import SwiftUI
import SwiftData
import MapKit

struct GymDetailView: View {
    var gym: MKMapItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Gym> { $0.favorite }) private var gyms: [Gym]
    var homeGym: Gym? { return gyms.first }
    
    private func isHomeGym(_ gym: MKMapItem) -> Bool {
        if let homeGym {
            return homeGym.latitude == gym.placemark.coordinate.latitude && homeGym.longitude == gym.placemark.coordinate.longitude
        } else {
            return false
        }
    }
    var body: some View {
        NavigationView {
            Form {
                if let address = gym.placemark.title {
                    HStack {
                        Text(address)
                            .font(.body)
                        Spacer()
                        Button(action: {
                            openMaps(for: gym)
                        }) {
                            Image(systemName: "map.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .listRowBackground(BlurView())
                }
                if let phoneNumber = gym.phoneNumber {
                    HStack {
                        Text("Phone: \(phoneNumber)")
                            .font(.body)
                        Spacer()
                        Button(action: {
                            callPhoneNumber(phoneNumber)
                        }) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .listRowBackground(BlurView())
                }
                if let url = gym.url {
                    HStack {
                        Text(trimmedURL(url))
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Spacer()
                        Link(destination: url) {
                            Image(systemName: "link")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                    }
                    .listRowBackground(BlurView())
                }
                Section {
                    if isHomeGym(gym) {
                        Button {
                            if let homeGym {
                                DataManager.shared.removeHomeGym(gym: homeGym, context: modelContext)
                            }
                            dismiss()
                        } label: {
                            Text("Remove as Home Gym")
                                .fontWeight(.semibold)
                        }
                        .listRowBackground(Color.red.opacity(0.5))
                    } else {
                        Button {
                            DataManager.shared.saveHomeGym(gym: gym, context: modelContext)
                            dismiss()
                        } label: {
                            Text("Set as Home Gym")
                                .fontWeight(.semibold)
                        }
                        .listRowBackground(Color.blue.opacity(0.5))
                    }
                }
            }
            .navigationTitle(gym.placemark.name ?? "Unknown Gym")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .fontWeight(.semibold)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .background(BackgroundView())
        }
    }
    private func openMaps(for gym: MKMapItem) {
        let mapItem = gym
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    private func callPhoneNumber(_ phoneNumber: String) {
        let formattedPhoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if let phoneURL = URL(string: "tel://\(formattedPhoneNumber)"), UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        }
    }
    private func trimmedURL(_ url: URL) -> String {
        let urlString = url.absoluteString
        let components = urlString.split(separator: "/")
        if components.count > 3 {
            return components.prefix(3).joined(separator: "/") + "/..."
        } else {
            return urlString
        }
    }
}

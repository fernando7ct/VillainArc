import Foundation
import SwiftData
import HealthKit

class HealthManager {
    static let shared = HealthManager()
    let healthStore = HKHealthStore()
    let healthTypes: Set = [HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned)]
    
    func requestHealthData(completion: @escaping (Bool) -> Void) {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore.requestAuthorization(toShare: [], read: healthTypes) { success, _ in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    func accessGranted(success: @escaping (Bool) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: .distantPast, end: .now)
        let query = HKStatisticsQuery(quantityType: HKQuantityType(.stepCount), quantitySamplePredicate: predicate) { _, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
                success(false)
                return
            }
        }
        healthStore.execute(query)
        let query2 = HKStatisticsQuery(quantityType: HKQuantityType(.activeEnergyBurned), quantitySamplePredicate: predicate) { _, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
                success(false)
                return
            }
            success(true)
        }
        healthStore.execute(query2)
    }
    func fetchSteps(context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<User>()
        let users = try! context.fetch(fetchDescriptor)
        let user = users.first!
        fetchAndSaveSteps(context: context, startDate: Calendar.current.startOfDay(for: user.dateJoined))
    }
    func fetchActiveEnergy(context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<User>()
        let users = try! context.fetch(fetchDescriptor)
        let user = users.first!
        fetchAndSaveActiveEnergy(context: context, startDate: Calendar.current.startOfDay(for: user.dateJoined))
    }
    func fetchAllHealthSteps(context: ModelContext) -> [HealthSteps] {
        let fetchDescriptor = FetchDescriptor<HealthSteps>()
        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            print("Error fetching HealthSteps: \(error)")
            return []
        }
    }
    func fetchAllHealthActiveEnergy(context: ModelContext) -> [HealthActiveEnergy] {
        let fetchDescriptor = FetchDescriptor<HealthActiveEnergy>()
        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            print("Error fetching HealthSteps: \(error)")
            return []
        }
    }
    func fetchAndSaveSteps(context: ModelContext, startDate: Date) {
        let steps = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())
        let query = HKStatisticsCollectionQuery(
            quantityType: steps,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        query.initialResultsHandler = { _, result, error in
            guard let result = result else {
                print("Error fetching steps: \(String(describing: error))")
                return
            }
            let existingHealthSteps = self.fetchAllHealthSteps(context: context)
            
            result.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                let date = statistics.startDate
                
                if let exisitingSetData = existingHealthSteps.first(where: { $0.date == date }) {
                    if exisitingSetData.steps != steps {
                        exisitingSetData.steps = steps
                        DataManager.shared.updateHealthSteps(healthSteps: exisitingSetData, context: context)
                    }
                } else {
                    let stepData = HealthSteps(id: UUID().uuidString, date: statistics.startDate, steps: steps)
                    DataManager.shared.saveHealthSteps(healthSteps: stepData, context: context)
                }
            }
        }
        healthStore.execute(query)
    }
    func fetchAndSaveActiveEnergy(context: ModelContext, startDate: Date) {
        let activeEnergyType = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())
        let query = HKStatisticsCollectionQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        query.initialResultsHandler = { _, result, error in
            guard let result = result else {
                print("Error fetching active energy: \(String(describing: error))")
                return
            }
            let existingActiveEnergy = self.fetchAllHealthActiveEnergy(context: context)
            
            result.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                let activeEnergy = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                let date = statistics.startDate
                
                if let exisitingSetData = existingActiveEnergy.first(where: { $0.date == date }) {
                    if exisitingSetData.activeEnergy != activeEnergy {
                        exisitingSetData.activeEnergy = activeEnergy
                        DataManager.shared.updateHealthActiveEnergy(activeEnergy: exisitingSetData, context: context)
                    }
                } else {
                    let activeEnergyData = HealthActiveEnergy(id: UUID().uuidString, date: statistics.startDate, activeEnergy: activeEnergy)
                    DataManager.shared.saveHealthActiveEnergy(activeEnergy: activeEnergyData, context: context)
                }
            }
        }
        healthStore.execute(query)
    }
}

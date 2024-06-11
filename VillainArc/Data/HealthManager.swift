import Foundation
import SwiftData
import HealthKit

class HealthManager {
    static let shared = HealthManager()
    let healthStore = HKHealthStore()
    let healthTypes: Set = [HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned), HKQuantityType(.basalEnergyBurned)]
    
    func requestHealthData(completion: @escaping (Bool) -> Void) {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore.requestAuthorization(toShare: [], read: healthTypes) { success, _ in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    func accessGranted(context: ModelContext, success: @escaping (Bool) -> Void) {
        let fetchDescriptor = FetchDescriptor<User>()
        let users = try! context.fetch(fetchDescriptor)
        let user = users.first!
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: user.dateJoined), end: .now)
        
        let query = HKStatisticsQuery(quantityType: HKQuantityType(.stepCount), quantitySamplePredicate: predicate) { _, result, error in
            guard let _ = result?.sumQuantity(), error == nil else {
                success(false)
                return
            }
        }
        healthStore.execute(query)
        let query2 = HKStatisticsQuery(quantityType: HKQuantityType(.activeEnergyBurned), quantitySamplePredicate: predicate) { _, result, error in
            guard let _ = result?.sumQuantity(), error == nil else {
                success(false)
                return
            }
        }
        healthStore.execute(query2)
        let query3 = HKStatisticsQuery(quantityType: HKQuantityType(.basalEnergyBurned), quantitySamplePredicate: predicate) { _, result, error in
            guard let _ = result?.sumQuantity(), error == nil else {
                success(false)
                return
            }
            success(true)
        }
        healthStore.execute(query3)
    }
    func fetchTodaySteps(completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        
        let query = HKStatisticsQuery(quantityType: HKQuantityType(.stepCount), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            var totalSteps: Double = 0
            
            if let result = result, let sum = result.sumQuantity() {
                totalSteps = sum.doubleValue(for: HKUnit.count())
            } else {
                print("Failed to fetch steps: \(error?.localizedDescription ?? "No error")")
            }
            
            DispatchQueue.main.async {
                completion(totalSteps)
            }
        }
        
        healthStore.execute(query)
    }
    func fetchTodayActiveEnergy(completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        
        let query = HKStatisticsQuery(quantityType: HKQuantityType(.activeEnergyBurned), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            var totalActiveEnergy: Double = 0
            
            if let result = result, let sum = result.sumQuantity() {
                totalActiveEnergy = sum.doubleValue(for: HKUnit.kilocalorie())
            } else {
                print("Failed to fetch active energy: \(error?.localizedDescription ?? "No error")")
            }
            
            DispatchQueue.main.async {
                completion(totalActiveEnergy)
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchTodayRestingEnergy(completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        
        let query = HKStatisticsQuery(quantityType: HKQuantityType(.basalEnergyBurned), quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            var totalRestingEnergy: Double = 0
            
            if let result = result, let sum = result.sumQuantity() {
                totalRestingEnergy = sum.doubleValue(for: HKUnit.kilocalorie())
            } else {
                print("Failed to fetch resting energy: \(error?.localizedDescription ?? "No error")")
            }
            
            DispatchQueue.main.async {
                completion(totalRestingEnergy)
            }
        }
        
        healthStore.execute(query)
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
    func fetchRestingEnergy(context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<User>()
        let users = try! context.fetch(fetchDescriptor)
        let user = users.first!
        fetchAndSaveRestingEnergy(context: context, startDate: Calendar.current.startOfDay(for: user.dateJoined))
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
            print("Error fetching Health Active Energy: \(error)")
            return []
        }
    }
    func fetchAllHealthRestingEnergy(context: ModelContext) -> [HealthRestingEnergy] {
        let fetchDescriptor = FetchDescriptor<HealthRestingEnergy>()
        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            print("Error fetching Health Resting Energy: \(error)")
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
    func fetchAndSaveRestingEnergy(context: ModelContext, startDate: Date) {
        let restingEnergyType = HKQuantityType(.basalEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())
        let query = HKStatisticsCollectionQuery(
            quantityType: restingEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        query.initialResultsHandler = { _, result, error in
            guard let result = result else {
                print("Error fetching resting energy: \(String(describing: error))")
                return
            }
            let existingRestingEnergy = self.fetchAllHealthRestingEnergy(context: context)
            
            result.enumerateStatistics(from: startDate, to: Date()) { statistics, _ in
                let restingEnergy = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                let date = statistics.startDate
                
                if let exisitingSetData = existingRestingEnergy.first(where: { $0.date == date }) {
                    if exisitingSetData.restingEnergy != restingEnergy {
                        exisitingSetData.restingEnergy = restingEnergy
                        DataManager.shared.updateHealthRestingEnergy(restingEnergy: exisitingSetData, context: context)
                    }
                } else {
                    let restingEnergyData = HealthRestingEnergy(id: UUID().uuidString, date: statistics.startDate, restingEnergy: restingEnergy)
                    DataManager.shared.saveHealthRestingEnergy(restingEnergy: restingEnergyData, context: context)
                }
            }
        }
        healthStore.execute(query)
    }
}

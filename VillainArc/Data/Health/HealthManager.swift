import Foundation
import SwiftData
import HealthKit

class HealthManager {
    static let shared = HealthManager()
    let healthStore = HKHealthStore()
    
    func requestHealthData(completion: @escaping (Bool) -> Void) {
        if HKHealthStore.isHealthDataAvailable() {
            let healthTypes: Set = [HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned), HKQuantityType(.basalEnergyBurned), HKQuantityType(.bodyMass)]
            healthStore.requestAuthorization(toShare: [HKQuantityType(.bodyMass)], read: healthTypes) { success, _ in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    func accessGranted(success: @escaping (Bool) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: .distantPast, end: .now)
        
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
    
    func fetchAndUpdateAllData(context: ModelContext) async {
        let descriptor = FetchDescriptor<User>()
        let user = try? context.fetch(descriptor).first!
        let distantPast = user?.dateJoined.startOfDay ?? Date()
        let endDate = Date()
        
        let mostRecentStepsDate = getMostRecentHealthSteps(context: context)?.date
        var secondToLast: Date? = nil
        if let mostRecentStepsDate {
            secondToLast = Calendar.current.date(byAdding: .day, value: -1, to: mostRecentStepsDate)
        }
        let startDate = secondToLast ?? distantPast
        fetchAndSaveSteps(context: context, startDate: startDate, endDate: endDate)
        
        let mostRecentCaloriesDate = getMostRecentHealthEnergy(context: context)?.date
        var secondToLast2: Date? = nil
        if let mostRecentCaloriesDate {
            secondToLast2 = Calendar.current.date(byAdding: .day, value: -1, to: mostRecentCaloriesDate)
        }
        let startDate2 = secondToLast2 ?? distantPast
        fetchAndSaveActiveEnergy(context: context, startDate: startDate2, endDate: endDate)
        fetchAndSaveRestingEnergy(context: context, startDate: startDate2, endDate: endDate)
        
        let mostRecentWeightEntry = getMostRecentWeightEntry(context: context)?.date
        var secondToLast3: Date? = nil
        if let mostRecentWeightEntry {
            secondToLast3 = Calendar.current.date(byAdding: .day, value: -1, to: mostRecentWeightEntry)
        }
        let startDate3 = secondToLast3 ?? distantPast
        fetchAndSaveWeightData(context: context, startDate: startDate3, endDate: endDate)
    }
    private func getMostRecentHealthSteps(context: ModelContext) -> HealthSteps? {
        let fetchDescriptor = FetchDescriptor<HealthSteps>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let healthSteps = try? context.fetch(fetchDescriptor)
        return healthSteps?.first
    }
    private func getMostRecentHealthEnergy(context: ModelContext) -> HealthEnergy? {
        let fetchDescriptor = FetchDescriptor<HealthEnergy>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let healthEnergy = try? context.fetch(fetchDescriptor)
        return healthEnergy?.first
    }
    private func getMostRecentWeightEntry(context: ModelContext) -> WeightEntry? {
        let fetchDescriptor = FetchDescriptor<WeightEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let entries = try? context.fetch(fetchDescriptor)
        return entries?.first
    }
    func fetchAllHealthSteps(context: ModelContext, startDate: Date) -> [HealthSteps] {
        let fetchDescriptor = FetchDescriptor<HealthSteps>(predicate: #Predicate { $0.date >= startDate })
        let steps = try? context.fetch(fetchDescriptor)
        return steps ?? []
    }
    func fetchAllHealthEnergy(context: ModelContext, startDate: Date) -> [HealthEnergy] {
        let fetchDescriptor = FetchDescriptor<HealthEnergy>(predicate: #Predicate { $0.date >= startDate })
        let energy = try? context.fetch(fetchDescriptor)
        return energy ?? []
    }
    func fetchAllWeightEntries(context: ModelContext, startDate: Date) -> [WeightEntry] {
        let fetchDescriptor = FetchDescriptor<WeightEntry>(predicate: #Predicate { $0.date >= startDate })
        let entries = try? context.fetch(fetchDescriptor)
        return entries ?? []
    }
    func fetchAndSaveSteps(context: ModelContext, startDate: Date, endDate: Date) {
        let steps = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
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
            let existingHealthSteps = self.fetchAllHealthSteps(context: context, startDate: startDate)
            result.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                let date = statistics.startDate
                if let exisitingSetData = existingHealthSteps.first(where: { $0.date == date }) {
                    if exisitingSetData.steps != steps {
                        exisitingSetData.steps = steps
                        DispatchQueue.main.async {
                            DataManager.shared.saveHealthSteps(healthSteps: exisitingSetData, context: context, update: true)
                        }
                    }
                } else {
                    let stepData = HealthSteps(id: UUID().uuidString, date: statistics.startDate, steps: steps)
                    DispatchQueue.main.async {
                        DataManager.shared.saveHealthSteps(healthSteps: stepData, context: context, update: false)
                    }
                }
            }
        }
        healthStore.execute(query)
    }
    func fetchAndSaveActiveEnergy(context: ModelContext, startDate: Date, endDate: Date) {
        let activeEnergyType = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
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
            let existingEnergy = self.fetchAllHealthEnergy(context: context, startDate: startDate)
            result.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                let activeEnergy = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                let date = statistics.startDate
                if let exisitingSetData = existingEnergy.first(where: { $0.date == date }) {
                    if exisitingSetData.activeEnergy != activeEnergy {
                        exisitingSetData.activeEnergy = activeEnergy
                        DispatchQueue.main.async {
                            DataManager.shared.saveHealthEnergy(energy: exisitingSetData, context: context, update: true)
                        }
                    }
                } else {
                    let activeEnergyData = HealthEnergy(id: UUID().uuidString, date: statistics.startDate, restingEnergy: 0, activeEnergy: activeEnergy)
                    DispatchQueue.main.async {
                        DataManager.shared.saveHealthEnergy(energy: activeEnergyData, context: context, update: false)
                    }
                }
            }
        }
        healthStore.execute(query)
    }
    
    func fetchAndSaveRestingEnergy(context: ModelContext, startDate: Date, endDate: Date) {
        let restingEnergyType = HKQuantityType(.basalEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
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
            let existingRestingEnergy = self.fetchAllHealthEnergy(context: context, startDate: startDate)
            result.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                let restingEnergy = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                let date = statistics.startDate
                if let exisitingSetData = existingRestingEnergy.first(where: { $0.date == date }) {
                    if exisitingSetData.restingEnergy != restingEnergy {
                        exisitingSetData.restingEnergy = restingEnergy
                        DispatchQueue.main.async {
                            DataManager.shared.saveHealthEnergy(energy: exisitingSetData, context: context, update: true)
                        }
                    }
                } else {
                    let restingEnergyData = HealthEnergy(id: UUID().uuidString, date: statistics.startDate, restingEnergy: restingEnergy, activeEnergy: 0)
                    DispatchQueue.main.async {
                        DataManager.shared.saveHealthEnergy(energy: restingEnergyData, context: context, update: false)
                    }
                }
            }
        }
        healthStore.execute(query)
    }
    func fetchAndSaveWeightData(context: ModelContext, startDate: Date, endDate: Date) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            print("Weight type is not available in HealthKit")
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
            guard let self = self, let samples = samples as? [HKQuantitySample], error == nil else {
                print("Error fetching weight data: \(String(describing: error))")
                return
            }
            let existingWeightEntries = self.fetchAllWeightEntries(context: context, startDate: startDate)
            for sample in samples {
                let weightInKilograms = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                let weightInPounds = weightInKilograms / 0.45359237
                let date = sample.startDate
                
                if let existingEntry = existingWeightEntries.first(where: { $0.date == date }) {
                    if existingEntry.weight != weightInPounds {
                        existingEntry.weight = weightInPounds
                        DispatchQueue.main.async {
                            DataManager.shared.saveWeightEntry(weightEntry: existingEntry, context: context, update: true, saveToHealthKit: false)
                        }
                    }
                } else {
                    let newWeightEntry = WeightEntry(id: UUID().uuidString, weight: weightInPounds, notes: "", date: date, photoData: nil)
                    DispatchQueue.main.async {
                        DataManager.shared.saveWeightEntry(weightEntry: newWeightEntry, context: context, update: false, saveToHealthKit: false)
                    }
                }
            }
        }
        healthStore.execute(query)
    }
    func saveWeightToHealthKit(weight: Double, date: Date, completion: @escaping (Bool, Error?) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(false, nil)
            return
        }
        let weightInKilograms = weight * 0.45359237
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weightInKilograms)
        let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: date, end: date)
        
        healthStore.save(weightSample) { success, error in
            completion(success, error)
        }
    }
    func deleteWeightFromHealthKit(weightEntry: WeightEntry, completion: @escaping (Bool, Error?) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(false, nil)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: weightEntry.date, end: weightEntry.date, options: .strictStartDate)
        let sampleQuery = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, samples, error in
            guard let samples = samples, let sampleToDelete = samples.first(where: { sample in
                if let quantitySample = sample as? HKQuantitySample {
                    let weightInKilograms = weightEntry.weight * 0.45359237
                    return quantitySample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo)) == weightInKilograms
                }
                return false
            }) else {
                completion(false, error)
                return
            }
            self.healthStore.delete(sampleToDelete) { success, error in
                completion(success, error)
            }
        }
        healthStore.execute(sampleQuery)
    }
}

import Foundation
import SwiftData
import HealthKit

class HealthManager: ObservableObject {
    static let shared = HealthManager()
    let healthStore = HKHealthStore()
    @Published var todaysSteps: Double = 0
    @Published var todaysActiveCalories: Double = 0
    @Published var todaysRestingCalories: Double = 0
    @Published var todaysWalkingRunningDistance: Double = 0
    
    private let updateQueue = DispatchQueue(label: "com.yourapp.healthUpdateQueue", attributes: .concurrent)
    
    func requestHealthData(completion: @escaping (Bool) -> Void) {
        if HKHealthStore.isHealthDataAvailable() {
            let healthTypes: Set = [HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned), HKQuantityType(.basalEnergyBurned), HKQuantityType(.distanceWalkingRunning)]
            healthStore.requestAuthorization(toShare: [], read: healthTypes) { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }

    func accessGranted(success: @escaping (Bool) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: .distantPast, end: .now)
        
        let query = HKStatisticsQuery(quantityType: HKQuantityType(.stepCount), quantitySamplePredicate: predicate) { _, result, error in
            guard let _ = result?.sumQuantity(), error == nil else {
                DispatchQueue.main.async {
                    success(false)
                }
                return
            }
        }
        healthStore.execute(query)
        
        let query2 = HKStatisticsQuery(quantityType: HKQuantityType(.activeEnergyBurned), quantitySamplePredicate: predicate) { _, result, error in
            guard let _ = result?.sumQuantity(), error == nil else {
                DispatchQueue.main.async {
                    success(false)
                }
                return
            }
        }
        healthStore.execute(query2)
        
        let query3 = HKStatisticsQuery(quantityType: HKQuantityType(.basalEnergyBurned), quantitySamplePredicate: predicate) { _, result, error in
            guard let _ = result?.sumQuantity(), error == nil else {
                DispatchQueue.main.async {
                    success(false)
                }
                return
            }
        }
        healthStore.execute(query3)
        
        let query4 = HKStatisticsQuery(quantityType: HKQuantityType(.distanceWalkingRunning), quantitySamplePredicate: predicate) { _, result, error in
            guard let _ = result?.sumQuantity(), error == nil else {
                DispatchQueue.main.async {
                    success(false)
                }
                return
            }
            DispatchQueue.main.async {
                success(true)
            }
        }
        healthStore.execute(query4)
    }
    
    func fetchAndUpdateAllData(context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<User>()
        let users = try! context.fetch(fetchDescriptor)
        let user = users.first!
        let userStartDate = Calendar.current.startOfDay(for: user.dateJoined)
        
        let endDate = Date()
        
        let mostRecentStepsDate = getMostRecentHealthSteps(context: context)?.date
        var secondToLast: Date? = nil
        if let mostRecentStepsDate {
            secondToLast = Calendar.current.date(byAdding: .day, value: -1, to: mostRecentStepsDate)
        }
        let startDate = secondToLast ?? userStartDate
        fetchAndSaveSteps(context: context, startDate: startDate, endDate: endDate)
        
        let mostRecentActiveDate = getMostRecentHealthActiveEnergy(context: context)?.date
        var secondToLast2: Date? = nil
        if let mostRecentActiveDate {
            secondToLast2 = Calendar.current.date(byAdding: .day, value: -1, to: mostRecentActiveDate)
        }
        let startDate2 = secondToLast2 ?? userStartDate
        fetchAndSaveActiveEnergy(context: context, startDate: startDate2, endDate: endDate)
        
        let mostRecentRestingDate = getMostRecentHealthRestingEnergy(context: context)?.date
        var secondToLast3: Date? = nil
        if let mostRecentRestingDate {
            secondToLast3 = Calendar.current.date(byAdding: .day, value: -1, to: mostRecentRestingDate)
        }
        let startDate3 = secondToLast3 ?? userStartDate
        fetchAndSaveRestingEnergy(context: context, startDate: startDate3, endDate: endDate)
        
        let mostRecentDistanceDate = getMostRecentHealthWalkingRunningDistance(context: context)?.date
        var secondToLast4: Date? = nil
        if let mostRecentDistanceDate {
            secondToLast4 = Calendar.current.date(byAdding: .day, value: -1, to: mostRecentDistanceDate)
        }
        let startDate4 = secondToLast4 ?? userStartDate
        fetchAndSaveWalkingRunningDistance(context: context, startDate: startDate4, endDate: endDate)
        
        fetchTodaySteps(context: context) { steps in
            DispatchQueue.main.async {
                self.todaysSteps = steps
            }
        }
        fetchTodayActiveEnergy(context: context) { activeEnergy in
            DispatchQueue.main.async {
                self.todaysActiveCalories = activeEnergy
            }
        }
        fetchTodayRestingEnergy(context: context) { restingEnergy in
            DispatchQueue.main.async {
                self.todaysRestingCalories = restingEnergy
            }
        }
        fetchTodayWalkingRunningDistance(context: context) { distance in
            DispatchQueue.main.async {
                self.todaysWalkingRunningDistance = distance
            }
        }
    }
    
    func fetchTodaySteps(context: ModelContext, completion: @escaping (Double) -> Void) {
        let todaysStep = getMostRecentHealthSteps(context: context)
        let steps = todaysStep?.steps ?? 0
        DispatchQueue.main.async {
            completion(steps)
        }
    }
    func fetchTodayActiveEnergy(context: ModelContext, completion: @escaping (Double) -> Void) {
        let todaysActive = getMostRecentHealthActiveEnergy(context: context)
        let energy = todaysActive?.activeEnergy ?? 0
        DispatchQueue.main.async {
            completion(energy)
        }
    }
    func fetchTodayRestingEnergy(context: ModelContext, completion: @escaping (Double) -> Void) {
        let todaysResting = getMostRecentHealthRestingEnergy(context: context)
        let energy = todaysResting?.restingEnergy ?? 0
        DispatchQueue.main.async {
            completion(energy)
        }
    }
    func fetchTodayWalkingRunningDistance(context: ModelContext, completion: @escaping (Double) -> Void) {
        let todaysDistance = getMostRecentHealthWalkingRunningDistance(context: context)
        let distance = todaysDistance?.distance ?? 0
        DispatchQueue.main.async {
            completion(distance)
        }
    }
    private func getMostRecentHealthSteps(context: ModelContext) -> HealthSteps? {
        let fetchDescriptor = FetchDescriptor<HealthSteps>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let healthSteps = try? context.fetch(fetchDescriptor)
        return healthSteps?.first
    }
    private func getMostRecentHealthActiveEnergy(context: ModelContext) -> HealthActiveEnergy? {
        let fetchDescriptor = FetchDescriptor<HealthActiveEnergy>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let healthActiveEnergy = try? context.fetch(fetchDescriptor)
        return healthActiveEnergy?.first
    }
    private func getMostRecentHealthRestingEnergy(context: ModelContext) -> HealthRestingEnergy? {
        let fetchDescriptor = FetchDescriptor<HealthRestingEnergy>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let healthRestingEnergy = try? context.fetch(fetchDescriptor)
        return healthRestingEnergy?.first
    }
    private func getMostRecentHealthWalkingRunningDistance(context: ModelContext) -> HealthWalkingRunningDistance? {
        let fetchDescriptor = FetchDescriptor<HealthWalkingRunningDistance>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let healthWalkingRunningDistance = try? context.fetch(fetchDescriptor)
        return healthWalkingRunningDistance?.first
    }
    func fetchAllHealthSteps(context: ModelContext) -> [HealthSteps] {
        let fetchDescriptor = FetchDescriptor<HealthSteps>()
        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            print("Error fetching Health Steps: \(error.localizedDescription)")
            return []
        }
    }
    func fetchAllHealthActiveEnergy(context: ModelContext) -> [HealthActiveEnergy] {
        let fetchDescriptor = FetchDescriptor<HealthActiveEnergy>()
        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            print("Error fetching Health Active Energy: \(error.localizedDescription)")
            return []
        }
    }
    func fetchAllHealthRestingEnergy(context: ModelContext) -> [HealthRestingEnergy] {
        let fetchDescriptor = FetchDescriptor<HealthRestingEnergy>()
        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            print("Error fetching Health Resting Energy: \(error.localizedDescription)")
            return []
        }
    }
    func fetchAllHealthWalkingRunningDistance(context: ModelContext) -> [HealthWalkingRunningDistance] {
        let fetchDescriptor = FetchDescriptor<HealthWalkingRunningDistance>()
        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            print("Error fetching Health Resting Energy: \(error.localizedDescription)")
            return []
        }
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
            let existingHealthSteps = self.fetchAllHealthSteps(context: context)
            self.updateQueue.async(flags: .barrier) {
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
            let existingActiveEnergy = self.fetchAllHealthActiveEnergy(context: context)
            self.updateQueue.async(flags: .barrier) {
                result.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let activeEnergy = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    let date = statistics.startDate
                    if let exisitingSetData = existingActiveEnergy.first(where: { $0.date == date }) {
                        if exisitingSetData.activeEnergy != activeEnergy {
                            exisitingSetData.activeEnergy = activeEnergy
                            DispatchQueue.main.async {
                                DataManager.shared.saveHealthActiveEnergy(activeEnergy: exisitingSetData, context: context, update: true)
                            }
                        }
                    } else {
                        let activeEnergyData = HealthActiveEnergy(id: UUID().uuidString, date: statistics.startDate, activeEnergy: activeEnergy)
                        DispatchQueue.main.async {
                            DataManager.shared.saveHealthActiveEnergy(activeEnergy: activeEnergyData, context: context, update: false)
                        }
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
            let existingRestingEnergy = self.fetchAllHealthRestingEnergy(context: context)
            self.updateQueue.async(flags: .barrier) {
                result.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let restingEnergy = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    let date = statistics.startDate
                    if let exisitingSetData = existingRestingEnergy.first(where: { $0.date == date }) {
                        if exisitingSetData.restingEnergy != restingEnergy {
                            exisitingSetData.restingEnergy = restingEnergy
                            DispatchQueue.main.async {
                                DataManager.shared.saveHealthRestingEnergy(restingEnergy: exisitingSetData, context: context, update: true)
                            }
                        }
                    } else {
                        let restingEnergyData = HealthRestingEnergy(id: UUID().uuidString, date: statistics.startDate, restingEnergy: restingEnergy)
                        DispatchQueue.main.async {
                            DataManager.shared.saveHealthRestingEnergy(restingEnergy: restingEnergyData, context: context, update: false)
                        }
                    }
                }
            }
        }
        healthStore.execute(query)
    }
    func fetchAndSaveWalkingRunningDistance(context: ModelContext, startDate: Date, endDate: Date) {
        let walkingRunningDistance = HKQuantityType(.distanceWalkingRunning)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let query = HKStatisticsCollectionQuery(
            quantityType: walkingRunningDistance,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        query.initialResultsHandler = { _, result, error in
            guard let result = result else {
                print("Error fetching walking running distance: \(String(describing: error))")
                return
            }
            let existingHealthWalkingRunningDistance = self.fetchAllHealthWalkingRunningDistance(context: context)
            self.updateQueue.async(flags: .barrier) {
                result.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let distance = statistics.sumQuantity()?.doubleValue(for: .mile()) ?? 0
                    let date = statistics.startDate
                    if let exisitingSetData = existingHealthWalkingRunningDistance.first(where: { $0.date == date }) {
                        if exisitingSetData.distance != distance {
                            exisitingSetData.distance = distance
                            DispatchQueue.main.async {
                                DataManager.shared.saveHealthWalkingRunningDistance(healthDistance: exisitingSetData, context: context, update: true)
                            }
                        }
                    } else {
                        let distanceData = HealthWalkingRunningDistance(id: UUID().uuidString, date: statistics.startDate, distance: distance)
                        DispatchQueue.main.async {
                            DataManager.shared.saveHealthWalkingRunningDistance(healthDistance: distanceData, context: context, update: false)
                        }
                    }
                }
            }
        }
        healthStore.execute(query)
    }
}

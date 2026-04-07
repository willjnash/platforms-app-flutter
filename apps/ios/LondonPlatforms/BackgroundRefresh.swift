import BackgroundTasks
import Foundation

enum BackgroundRefresh {
  static let taskId = "com.platforms.londonplatforms.refresh"
  private static let trackedKeyDefaults = "trackedServiceKey"
  static let trackedStationCRSDefaults = "trackedStationCRS"

  static func register() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: taskId, using: nil) { task in
      guard let task = task as? BGAppRefreshTask else { return }
      handle(task)
    }
  }

  static func scheduleNext() {
    // Don't touch @MainActor state here; use persisted tracking state.
    guard UserDefaults.standard.string(forKey: trackedKeyDefaults) != nil else { return }
    let request = BGAppRefreshTaskRequest(identifier: taskId)
    request.earliestBeginDate = Date().addingTimeInterval(nextIntervalSeconds())
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      // Best effort: if the system rejects scheduling, we’ll update next time we’re foregrounded.
    }
  }

  private static func handle(_ task: BGAppRefreshTask) {
    scheduleNext()
    let operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 1

    let op = RefreshOperation()
    task.expirationHandler = {
      operationQueue.cancelAllOperations()
    }
    op.completionBlock = {
      task.setTaskCompleted(success: !op.isCancelled)
    }
    operationQueue.addOperation(op)
  }

  private static func nextIntervalSeconds() -> TimeInterval {
    // Best effort: use a conservative cadence. iOS may run less often anyway.
    // If we can infer “minutes until departure” from the pinned service’s booked time,
    // choose shorter intervals closer to departure.
    let booked = UserDefaults.standard.string(forKey: "trackedBookedHHmm")
    return TimeUtils.nextCheckIntervalSeconds(bookedHHmm: booked)
  }
}

private final class RefreshOperation: Operation {
  override func main() {
    if isCancelled { return }
    let semaphore = DispatchSemaphore(value: 0)
    Task {
      defer { semaphore.signal() }
      guard let crs = UserDefaults.standard.string(forKey: BackgroundRefresh.trackedStationCRSDefaults) else {
        return
      }
      do {
        let res = try await RTTClient.shared.fetchBoard(crs: crs, arrivals: false, timeHHmm: nil)
        await TrackedServiceManager.shared.updateFromBoard(
          stationName: AppSettings.savedStationDescription,
          services: res.services ?? []
        )
      } catch {
        // Best effort: ignore errors; backoff is handled by iOS scheduling + our conservative interval.
      }
    }
    _ = semaphore.wait(timeout: .now() + 25)
  }
}


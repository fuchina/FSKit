//
//  FSXIRR.swift
//  FSKit
//
//  Unified XIRR solver for Inventory-related modules.
//

import Foundation

open class FSXIRR: NSObject {

    public struct CashFlow {
        public let date: Double
        public let amount: Double

        public init(date: Double, amount: Double) {
            self.date = date
            self.amount = amount
        }
    }

    public struct Options {
        public var initialRate: Double
        public var lowerBound: Double
        public var upperBound: Double
        public var maxNewtonIterations: Int
        public var maxBisectionIterations: Int
        public var maxBracketExpansionIterations: Int
        public var derivativeEpsilon: Double
        public var rateTolerance: Double
        public var npvTolerance: Double
        public var residualTolerance: Double
        public var useBisectionFallback: Bool
        public var useAnnualizeFallback: Bool

        public init(
            initialRate: Double = 0.1,
            lowerBound: Double = -0.999_999,
            upperBound: Double = 1_000_000,
            maxNewtonIterations: Int = 200,
            maxBisectionIterations: Int = 200,
            maxBracketExpansionIterations: Int = 40,
            derivativeEpsilon: Double = 1e-15,
            rateTolerance: Double = 1e-10,
            npvTolerance: Double = 1e-8,
            residualTolerance: Double = 0.01,
            useBisectionFallback: Bool = true,
            useAnnualizeFallback: Bool = true
        ) {
            self.initialRate = initialRate
            self.lowerBound = lowerBound
            self.upperBound = upperBound
            self.maxNewtonIterations = maxNewtonIterations
            self.maxBisectionIterations = maxBisectionIterations
            self.maxBracketExpansionIterations = maxBracketExpansionIterations
            self.derivativeEpsilon = derivativeEpsilon
            self.rateTolerance = rateTolerance
            self.npvTolerance = npvTolerance
            self.residualTolerance = residualTolerance
            self.useBisectionFallback = useBisectionFallback
            self.useAnnualizeFallback = useAnnualizeFallback
        }
    }

    // Mirrors FSTransactionManager behavior.
    public static let transactionOptions = Options(
        initialRate: 0.1,
        lowerBound: -0.999_999,
        upperBound: 1_000_000,
        maxNewtonIterations: 200,
        maxBisectionIterations: 200,
        maxBracketExpansionIterations: 40,
        derivativeEpsilon: 1e-15,
        rateTolerance: 1e-10,
        npvTolerance: 1e-8,
        residualTolerance: 0.01,
        useBisectionFallback: true,
        useAnnualizeFallback: true
    )

    // Mirrors FSDayProfitModel behavior.
    public static let dayProfitOptions = Options(
        initialRate: 0.1,
        lowerBound: -0.99,
        upperBound: 100,
        maxNewtonIterations: 200,
        maxBisectionIterations: 0,
        maxBracketExpansionIterations: 0,
        derivativeEpsilon: 1e-15,
        rateTolerance: 1e-10,
        npvTolerance: 1e-8,
        residualTolerance: 0.01,
        useBisectionFallback: false,
        useAnnualizeFallback: false
    )

    public static func solve(
        _ cashFlows: [(date: Double, amount: Double)],
        options: Options = FSXIRR.transactionOptions
    ) -> Double? {
        let flows = cashFlows.map { CashFlow(date: $0.date, amount: $0.amount) }
        let v = solve(flows, options: options)
        return v
    }

    public static func solve(
        _ cashFlows: [CashFlow],
        options: Options = FSXIRR.transactionOptions
    ) -> Double? {
        
        guard cashFlows.count >= 2 else { return nil }

        let sorted = cashFlows.sorted { $0.date < $1.date }
        guard hasBothSigns(sorted) else { return nil }

        let baseDate = sorted[0].date
        let secondsPerYear = 365.25 * 86400.0
        let lower = max(options.lowerBound, -0.999_999_999)
        let upper = max(options.upperBound, lower + 1e-9)

        func npv(_ rate: Double) -> Double {
            var result = 0.0
            for cf in sorted {
                let years = (cf.date - baseDate) / secondsPerYear
                let denom = pow(1.0 + rate, years)
                if denom != 0, denom.isFinite {
                    result += cf.amount / denom
                }
            }
            return result
        }

        func npvDeriv(_ rate: Double) -> Double {
            var result = 0.0
            for cf in sorted {
                let years = (cf.date - baseDate) / secondsPerYear
                let denom = pow(1.0 + rate, years)
                if denom != 0, denom.isFinite {
                    result -= years * cf.amount / (denom * (1.0 + rate))
                }
            }
            return result
        }

        var rate = min(max(options.initialRate, lower), upper)
        for _ in 0..<max(options.maxNewtonIterations, 0) {
            let f = npv(rate)
            let df = npvDeriv(rate)
            if !f.isFinite || !df.isFinite || abs(df) < options.derivativeEpsilon {
                break
            }

            let next = rate - f / df
            if !next.isFinite {
                break
            }

            let bounded = min(max(next, lower), upper)
            if abs(bounded - rate) < options.rateTolerance {
                return bounded
            }
            rate = bounded
        }

        if abs(npv(rate)) < options.residualTolerance {
            return rate
        }

        if options.useBisectionFallback && options.maxBisectionIterations > 0 {
            var low = lower
            var high = min(1.0, upper)
            if high <= low { high = min(low + 1.0, upper) }

            var fLow = npv(low)
            var fHigh = npv(high)

            var bracketed = false
            for _ in 0..<max(options.maxBracketExpansionIterations, 0) {
                if fLow.isFinite, fHigh.isFinite, fLow * fHigh <= 0 {
                    bracketed = true
                    break
                }
                high = min(high * 2, upper)
                if high <= low { break }
                fHigh = npv(high)
            }

            if bracketed {
                for _ in 0..<options.maxBisectionIterations {
                    let mid = (low + high) / 2
                    let fMid = npv(mid)
                    if !fMid.isFinite {
                        break
                    }
                    if abs(fMid) < options.npvTolerance || abs(high - low) < options.rateTolerance {
                        return mid
                    }
                    if fLow * fMid <= 0 {
                        high = mid
                        fHigh = fMid
                    } else {
                        low = mid
                        fLow = fMid
                    }
                }
                let mid = (low + high) / 2
                if mid.isFinite {
                    return mid
                }
            }
        }

        if options.useAnnualizeFallback {
            return annualizeFallback(sorted)
        }

        return nil
    }

    public static func annualizeByRatio(
        principal: Double,
        terminal: Double,
        start: Double,
        end: Double
    ) -> Double? {
        guard principal > 0, terminal > 0 else { return nil }
        let secondsPerYear = 365.25 * 86400.0
        let spanSeconds = max(end - start, 1)
        let years = max(spanSeconds / secondsPerYear, 1.0 / 3650.0)
        let ratio = terminal / principal
        guard ratio > 0 else { return nil }
        let value = pow(ratio, 1.0 / years) - 1.0
        return value.isFinite ? value : nil
    }

    private static func hasBothSigns(_ cashFlows: [CashFlow]) -> Bool {
        var hasPositive = false
        var hasNegative = false
        for cf in cashFlows {
            if cf.amount > 0 { hasPositive = true }
            if cf.amount < 0 { hasNegative = true }
            if hasPositive && hasNegative { return true }
        }
        return false
    }

    private static func annualizeFallback(_ cashFlows: [CashFlow]) -> Double? {
        guard let first = cashFlows.first, let last = cashFlows.last else { return nil }

        let totalIn = -cashFlows.filter { $0.amount < 0 }.reduce(0.0) { $0 + $1.amount }
        let totalOut = cashFlows.filter { $0.amount > 0 }.reduce(0.0) { $0 + $1.amount }
        guard totalIn > 0, totalOut > 0 else { return nil }

        let secondsPerYear = 365.25 * 86400.0
        let spanSeconds = max(last.date - first.date, 1)
        let years = max(spanSeconds / secondsPerYear, 1.0 / 3650.0)
        let ratio = totalOut / totalIn
        guard ratio > 0 else { return nil }

        let fallback = pow(ratio, 1.0 / years) - 1.0
        return fallback.isFinite ? fallback : nil
    }
}


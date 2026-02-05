//
//  FSTuple.swift
//  FSKit
//
//  Created by pwrd on 2026/2/5.
//

import Foundation

public struct Tuple2<A,B> {
    public let v1: A
    public let v2: B
    
    public init(v1: A, v2: B) {
        self.v1 = v1
        self.v2 = v2
    }
}

public struct Tuple3<A,B,C> {
    public let v1: A
    public let v2: B
    public let v3: C
    
    public init(v1: A, v2: B, v3: C) {
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
    }
}

public struct Tuple4<A,B,C,D> {
    public let v1: A
    public let v2: B
    public let v3: C
    public let v4: D
    
    public init(v1: A, v2: B, v3: C, v4: D) {
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
        self.v4 = v4
    }
}

public struct Tuple5<A,B,C,D,E> {
    public let v1: A
    public let v2: B
    public let v3: C
    public let v4: D
    public let v5: E
    
    public init(v1: A, v2: B, v3: C, v4: D, v5: E) {
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
        self.v4 = v4
        self.v5 = v5
    }
}


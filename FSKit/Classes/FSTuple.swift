//
//  FSTuple.swift
//  FSKit
//
//  Created by pwrd on 2026/2/5.
//

import Foundation

public struct Tuple2<A,B> {
    public var v1: A
    public var v2: B
    
    public init(v1: A, v2: B) {
        self.v1 = v1
        self.v2 = v2
    }
}

public struct Tuple3<A,B,C> {
    public var v1: A
    public var v2: B
    public var v3: C
    
    public init(v1: A, v2: B, v3: C) {
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
    }
}

public struct Tuple4<A,B,C,D> {
    public var v1: A
    public var v2: B
    public var v3: C
    public var v4: D
    
    public init(v1: A, v2: B, v3: C, v4: D) {
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
        self.v4 = v4
    }
}

public struct Tuple5<A,B,C,D,E> {
    public var v1: A
    public var v2: B
    public var v3: C
    public var v4: D
    public var v5: E
    
    public init(v1: A, v2: B, v3: C, v4: D, v5: E) {
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
        self.v4 = v4
        self.v5 = v5
    }
}


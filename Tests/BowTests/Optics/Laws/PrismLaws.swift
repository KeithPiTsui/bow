import SwiftCheck
@testable import Bow

class PrismLaws<A, B> where A : Arbitrary, B : Arbitrary, B : CoArbitrary, B : Hashable {
    
    static func check<EqA, EqB>(prism : Prism<A, B>, eqA : EqA, eqB : EqB) where EqA : Eq, EqA.A == A, EqB : Eq, EqB.A == B {
        partialRoundTripOneWay(prism, eqA)
        roundTripOtherWay(prism, Maybe<B>.eq(eqB))
        modifyId(prism, eqA)
        composeModify(prism, eqA)
        consistentSetModify(prism, eqA)
        consistentModifyModifyFId(prism, eqA)
        consistentGetMaybeModifyFId(prism, Maybe<B>.eq(eqB))
    }
    
    private static func partialRoundTripOneWay<EqA>(_ prism : Prism<A, B>, _ eqA : EqA) where EqA : Eq, EqA.A == A {
        property("Partial round trip one way") <- forAll { (a : A) in
            return eqA.eqv(prism.getOrModify(a).fold(id, prism.reverseGet), a)
        }
    }
    
    private static func roundTripOtherWay<EqMaybeB>(_ prism : Prism<A, B>, _ eqB : EqMaybeB) where EqMaybeB : Eq, EqMaybeB.A == MaybeOf<B> {
        property("Round trip other way") <- forAll { (b : B) in
            return eqB.eqv(prism.getMaybe(prism.reverseGet(b)),
                           Maybe.some(b))
        }
    }
    
    private static func modifyId<EqA>(_ prism : Prism<A, B>, _ eqA : EqA) where EqA : Eq, EqA.A == A {
        property("Modify id") <- forAll { (a : A) in
            return eqA.eqv(prism.modify(a, id), a)
        }
    }
    
    private static func composeModify<EqA>(_ prism : Prism<A, B>, _ eqA : EqA) where EqA : Eq, EqA.A == A {
        property("Compose modify") <- forAll { (a : A, f : ArrowOf<B, B>, g : ArrowOf<B, B>) in
            return eqA.eqv(prism.modify(prism.modify(a, f.getArrow), g.getArrow),
                           prism.modify(a, g.getArrow <<< f.getArrow))
        }
    }
    
    private static func consistentSetModify<EqA>(_ prism : Prism<A, B>, _ eqA : EqA) where EqA : Eq, EqA.A == A {
        property("Consistent set - modify") <- forAll { (a : A, b : B) in
            return eqA.eqv(prism.set(a, b),
                           prism.modify(a, constF(b)))
        }
    }
    
    private static func consistentModifyModifyFId<EqA>(_ prism : Prism<A, B>, _ eqA : EqA) where EqA : Eq, EqA.A == A {
        property("Consistent modify - modifyF Id") <- forAll { (a : A, f : ArrowOf<B, B>) in
            return eqA.eqv(prism.modify(a, f.getArrow),
                           prism.modifyF(Id<B>.applicative(), a, { b in Id<B>.pure(f.getArrow(b)) }).fix().value)
        }
    }
    
    private static func consistentGetMaybeModifyFId<EqMaybeB>(_ prism : Prism<A, B>, _ eqB : EqMaybeB) where EqMaybeB : Eq, EqMaybeB.A == MaybeOf<B> {
        property("Consistent getMaybe - modifyF Id") <- forAll { (a : A) in
            return eqB.eqv(Const<Maybe<B>, A>.fix(prism.modifyF(Const<Maybe<B>, B>.applicative(PrismMonoid<B>()), a, { b in Const<Maybe<B>, B>.pure(Maybe<B>.some(b)) })).value,
                           prism.getMaybe(a))
        }
    }
    
    fileprivate class PrismMonoid<T> : Monoid {
        typealias A = Maybe<T>
        var empty: Maybe<T> {
            return Maybe<T>.none()
        }
        
        func combine(_ a: Maybe<T>, _ b: Maybe<T>) -> Maybe<T> {
            return a.orElse(b)
        }
    }
}


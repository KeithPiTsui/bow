import Foundation

public protocol TraverseFilter : Traverse, FunctorFilter {
    func traverseFilter<A, B, G, Appl>(_ fa : Kind<F, A>, _ f : @escaping (A) -> Kind<G, Maybe<B>>, _ applicative : Appl) -> Kind<G, Kind<F, B>> where Appl : Applicative, Appl.F == G
}

public extension TraverseFilter {
    public func mapFilter<A, B>(_ fa: Kind<F, A>, _ f: @escaping (A) -> Maybe<B>) -> Kind<F, B> {
        return (traverseFilter(fa, { a in Id<Maybe<B>>.pure(f(a)) }, Id<Maybe<B>>.applicative()) as! Id<Kind<F, B>>).extract()
    }
    
    public func filterA<A, G, Appl>(_ fa : Kind<F, A>, _ f : @escaping (A) -> Kind<G, Bool>, _ applicative : Appl) -> Kind<G, Kind<F, A>> where Appl : Applicative, Appl.F == G {
        return traverseFilter(fa, { a in applicative.map(f(a), { b in b ? Maybe.some(a) : Maybe.none() }) }, applicative)
    }
    
    public func filter<A>(_ fa : Kind<F, A>, _ f : @escaping (A) -> Bool) -> Kind<F, A> {
        return (filterA(fa, { a in Id.pure(f(a)) }, Id<A>.applicative()) as! Id<Kind<F, A>>).extract()
    }
}

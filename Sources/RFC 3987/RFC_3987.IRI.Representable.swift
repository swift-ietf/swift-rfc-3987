public import ASCII
public import Binary


extension RFC_3987.IRI {
    public protocol Representable {

        var iri: RFC_3987.IRI { get }
    }
}

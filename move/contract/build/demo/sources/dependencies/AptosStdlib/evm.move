/// Cryptographic hashes:
/// - Keccak-256: see https://keccak.team/keccak.html
///
/// In addition, SHA2-256 and SHA3-256 are available in `std::hash`. Note that SHA3-256 is a variant of Keccak: it is
/// NOT the same as Keccak-256.
///
/// Non-cryptograhic hashes:
module aptos_std::evm {

    public native fun address_to_vector(addr: address): vector<u8>;

}

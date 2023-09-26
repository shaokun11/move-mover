module demo::util {
    use std::signer;
    const INVALID_CALLER: u64 = 103;

    public fun checkCaller(account: &signer) {
        assert!(signer::address_of(account) == @signer, INVALID_CALLER);
    }
}
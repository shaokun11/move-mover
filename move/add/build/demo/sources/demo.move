module demo::demo {
    // use Evm::Evm;

    // use Evm::Evm::self;

    // #[view, create33333]
    // public fun plus(a: u64, b: u64): address {
    //     // let c = Evm::msg_sender();
    //     // c
    //     // self()
    // }

    #[view]
    public fun sub(a: u64, b: u64): u64 {
        a - b
    }

    #[view]
    public fun mul(a: u64, b: u64, c: u64): u64 {
        a * b * c
    }
}
module local::counter {
    use std::signer;

    struct M has key {
       num: u64
   }

    public entry fun add(sender: signer) acquires M{
        if(!exists<M>(@local)) {
            move_to(&sender, M {
                num: 0
            })
        };

        let addr = signer::address_of(&sender);
        borrow_global_mut<M>(addr).num = borrow_global_mut<M>(addr).num + 1;
    }

    public entry fun add_simulate(sender: signer) acquires M{
        if(!exists<M>(@local)) {
            move_to(&sender, M {
                num: 0
            })
        };

        let addr = signer::address_of(&sender);
        borrow_global_mut<M>(addr).num = borrow_global_mut<M>(addr).num + 1;
    }

    #[view]
    public fun get(addr: address): u64 acquires M {
        borrow_global<M>(addr).num
    }
}


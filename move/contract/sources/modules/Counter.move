
module demo::counter {

    struct T has key {
        count: u64

    }

    fun init_module(signer: &signer) {
        move_to(signer, T{
        count: 0

        });
    }

    #[view]
    public fun get_counter(): u64 acquires T {
        let ret_1 = borrow_global_mut<T>(@demo).count;
        let ret = ret_1;
        ret
    }

    fun fun_increase() acquires T  {
        let _1 = borrow_global_mut<T>(@demo).count;
        _1 = _1 + 1;
    }

    public entry fun increase() acquires T {
        fun_increase()
    }
}
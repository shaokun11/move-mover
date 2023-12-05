
module demo::counter_test {
    use demo::yul;
    use std::vector;
    use aptos_std::simple_map;
    use aptos_std::simple_map::SimpleMap;
    use aptos_std::debug;
    use std::signer;
    #[test_only]
    use aptos_framework::account;
    #[test_only]
    use std::string::utf8;


    struct T has key {
        storage: SimpleMap<u256, u256>
    }

    entry fun init_module(account: &signer) {
        move_to(account, T {
            storage: simple_map::new<u256, u256>(),
        });
    }

    public fun run(_sender: address, data: vector<u8>): vector<u8> acquires T {
        let move_ret = &mut vector::empty<u8>();
        let memory = &mut simple_map::new<u256, u256>();
        let pstorage = &mut borrow_global_mut<T>(@demo).storage;
        let _1 = yul::memoryguard(0x80);
        yul::mstore(memory,64,_1);
        if(yul::iszero(yul::lt(yul::calldatasize(data),4)) != 0) {
            let _2 = 0;
            let m = yul::shr(224,yul::calldataload(data,_2));
            if(yul::equal(m, 0x06661abd)) {
                if(yul::callvalue() != 0) {
                    yul::revert(_2,_2);
                };
                if(yul::slt(yul::add(yul::calldatasize(data),yul::not(3)),_2) != 0) {
                    yul::revert(_2,_2);
                };
                yul::mstore(memory,_1,yul::sload(pstorage,_2));
                yul::ret(move_ret,memory,_1,32);
            };
            if(yul::equal(m, 0x30f3f0db)) {
                if(yul::callvalue() != 0) {
                    yul::revert(_2,_2);
                };
                if(yul::slt(yul::add(yul::calldatasize(data),yul::not(3)),32) != 0) {
                    yul::revert(_2,_2);
                };
                let _3 = yul::sload(pstorage,_2);
                let sum = yul::add(_3,yul::calldataload(data,4));
                if(yul::gt(_3,sum) != 0) {
                    yul::mstore(memory,_2,yul::shl(224,0x4e487b71));
                    yul::mstore(memory,4,0x11);
                    yul::revert(_2,0x24);
                };
                yul::sstore(pstorage,_2,sum);
                yul::ret(move_ret,memory,_2,_2);
            };
        };
        *takes_mut_returns_immut(move_ret)
    }

    fun takes_mut_returns_immut(x: &mut vector<u8>): &vector<u8> { x }

    public entry fun call(account: &signer,data: vector<u8>) acquires T  {
        run(signer::address_of(account), data);
    }

    #[view]
    public fun view(sender: address, data: vector<u8>): vector<u8> acquires T  {
        run(sender, data)
    }

    #[test(admin = @0x123)]
    fun testCall() acquires T {
        let user = account::create_account_for_test(@demo);
        init_module(&user);

        // yul::caller(signer::address_of(&user));
        // let sender =
        // u256::from_number1(87903029871075914254377627908054574944891091886930582284385770809450030037083);
        //
        //
        // u256::from_number2(1);
        debug::print(&utf8(b"counter +10"));
        let input = x"30f3f0db000000000000000000000000000000000000000000000000000000000000000a";
        call(&user, input);

        debug::print(&utf8(b"counter +10"));
        let input = x"30f3f0db000000000000000000000000000000000000000000000000000000000000000a";
        call(&user, input);

        debug::print(&utf8(b"get counter"));
        let input2 = x"06661abd";
        let res = view(signer::address_of(&user), input2);
        debug::print(&res);
    }
}
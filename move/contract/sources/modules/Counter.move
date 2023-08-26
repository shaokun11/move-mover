module demo::counter {
    use demo::yul;
    use u256::u256;
    use aptos_std::simple_map;
    use u256::u256::U256;
    use aptos_std::simple_map::SimpleMap;
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    use std::vector;
    #[test_only]
    use std::string::utf8;
    use aptos_std::debug;

    struct T has key {
        storage: SimpleMap<U256, U256>
    }

    entry fun init_module(account: &signer) {
        move_to(account, T {
            storage: simple_map::new(),
        });
    }

    public fun call(data: vector<u8>): vector<u8> acquires T {
        let ret = vector::empty<u8>();
        let memory = simple_map::new<U256, U256>();
        let pstorage = borrow_global_mut<T>(@demo).storage;
        let _1 = yul::memoryguard(u256::from_u64(0x80));
        yul::mstore(&mut memory,u256::from_u64(64),_1);
        if(!yul::eq(yul::iszero(yul::lt(yul::calldatasize(data),u256::from_u64(4))),u256::zero())) {
            let _2 = u256::from_u64(0);
            let m = yul::shr(u256::from_u64(224),yul::calldataload(data,_2));
            if(yul::eq(m, u256::from_u64(0x06661abd))) {
                if(!yul::eq(yul::callvalue(),u256::zero())) {
                    yul::revert(_2,_2);
                };
                if(!yul::eq(yul::slt(yul::add(yul::calldatasize(data),yul::not(u256::from_u64(3))),_2),u256::zero())) {
                    assert!(false, 13);
                    yul::revert(_2,_2);
                };
                yul::mstore(&mut memory,_1,yul::sload(&mut pstorage, _2));
                yul::ret(&mut ret, &memory, _1,u256::from_u64(32));
            };
            if(yul::eq(m, u256::from_u64(0x30f3f0db))) {
                if(!yul::eq(yul::callvalue(),u256::zero())) {
                    yul::revert(_2,_2);
                };
                if(!yul::eq(yul::slt(yul::add(yul::calldatasize(data),yul::not(u256::from_u64(3))),u256::from_u64(32)),u256::zero())) {
                    assert!(false, 15);
                    yul::revert(_2,_2);
                };
                let _3 = yul::sload(&mut pstorage, _2);
                let sum = yul::add(_3,yul::calldataload(data,u256::from_u64(4)));
                if(!yul::eq(yul::gt(_3,sum),u256::zero())) {
                    yul::mstore(&mut memory,_2,yul::shl(u256::from_u64(224),u256::from_u64(0x4e487b71)));
                    yul::mstore(&mut memory,u256::from_u64(4),u256::from_u64(0x11));
                    yul::revert(_2,u256::from_u64(0x24));
                };
                yul::sstore(&mut pstorage,_2,sum);
                yul::ret(&mut ret, &memory, _2,_2);
            };
        };
        borrow_global_mut<T>(@demo).storage = pstorage;
        ret
    }

    #[test (acc = @0xc3bb8488ab1a5815a9d543d7e41b0e0df46a7396f89b22821f07a4362f75ddc5)]
    fun testCall() acquires T {
        let resource_account = create_account_for_test(@demo);
        init_module(&resource_account);
        debug::print(&utf8(b"counter +10"));
        let input = x"30f3f0db000000000000000000000000000000000000000000000000000000000000000a";
        call(input);

        debug::print(&utf8(b"counter +10"));
        let input = x"30f3f0db000000000000000000000000000000000000000000000000000000000000000a";
        call(input);

        debug::print(&utf8(b"get counter"));
        let input2 = x"06661abd";
        let res = call(input2);
        debug::print(&res);
    }

}
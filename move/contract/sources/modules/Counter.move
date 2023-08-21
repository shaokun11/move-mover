
module demo::counter {
    use demo::yul;
    use u256::u256;
    use aptos_std::simple_map;
    use u256::u256::U256;

    public fun call(data: vector<u8>) {
        let memory = simple_map::new<U256, U256>();
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
                    yul::revert(_2,_2);
                };
                yul::mstore(&mut memory,_1,yul::sload(_2));
                yul::ret(_1,u256::from_u64(32));
            };
            if(yul::eq(m, u256::from_u64(0x30f3f0db))) {
                if(!yul::eq(yul::callvalue(),u256::zero())) {
                    yul::revert(_2,_2);
                };
                if(!yul::eq(yul::slt(yul::add(yul::calldatasize(data),yul::not(u256::from_u64(3))),u256::from_u64(32)),u256::zero())) {
                    yul::revert(_2,_2);
                };
                let _3 = yul::sload(_2);
                let sum = yul::add(_3,yul::calldataload(data,u256::from_u64(4)));
                if(!yul::eq(yul::gt(_3,sum),u256::zero())) {
                    yul::mstore(&mut memory,_2,yul::shl(u256::from_u64(224),u256::from_u64(0x4e487b71)));
                    yul::mstore(&mut memory,u256::from_u64(4),u256::from_u64(0x11));
                    yul::revert(_2,u256::from_u64(0x24));
                };
                yul::sstore(_2,sum);
                yul::ret(_2,_2);
            };
        };
        yul::revert(u256::from_u64(0),u256::from_u64(0));

    }
}
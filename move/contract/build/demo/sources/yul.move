
module demo::yul {
    use std::vector;
    use aptos_std::simple_map;
    use u256::u256;
    use u256::u256::U256;
    use aptos_std::simple_map::SimpleMap;

    struct TestEvent has drop, store {
        number: U256,
    }

    public fun sload(storage: &mut SimpleMap<U256, U256>, pos: U256): U256{
        let contain = simple_map::contains_key<U256, U256>(storage, &pos);
        if(contain)
            *simple_map::borrow(storage, &pos)
        else {
            return u256::zero()
        }
    }

    public fun callvalue(): U256 {
        u256::zero()
    }

    public fun calldataload(data: vector<u8>, pos: U256): U256 {
        let p = u256::as_u64(pos);
        dataToU256(data, p, 32)
    }

    public fun shr(n1: U256, n2: U256): U256 {
        let n = u256::shr(n2, (u256::as_u64(n1) as u8));
        n
    }

    public fun shl(n1: U256, n2: U256): U256 {
        u256::shr(n2, (u256::as_u64(n1) as u8))
    }

    public fun lt(n1: U256, n2: U256): U256 {
        if(u256::compare(&n1, &n2) == 1) {
            u256::from_u64(1)
        } else {
            u256::zero()
        }
    }

    public fun slt(a: U256, b: U256): U256 {
        if(u256::compare(&a, &b) == 1) {
            u256::from_u64(1)
        } else {
            u256::zero()
        }
    }

    public fun eq(a: U256, b: U256): bool {
        return u256::compare(&a, &b) == 0
    }

    public fun gt(a: U256, b: U256): U256 {
        if(u256::compare(&a, &b) == 2) {
            u256::from_u64(1)
        } else {
            u256::zero()
        }
    }

    public fun revert(a: U256, _b: U256) {
        assert!(false, u256::as_u64(a));
    }

    public fun sstore(storage: &mut SimpleMap<U256, U256>, pos: U256, value: U256) {
        simple_map::upsert(storage, pos, value);
    }

    public fun mstore(memory: &mut SimpleMap<U256, U256>, pos: U256, value: U256) {
        simple_map::upsert(memory, pos, value);
    }

    public fun ret(r: &mut vector<u8>, memory: &SimpleMap<U256, U256>, a: U256, b:U256) {
        let i = 0;
        while(i < u256::as_u64(b)) {
            if(simple_map::contains_key(memory, &a)) {
                let value = simple_map::borrow(memory, &u256::add(a, u256::from_u64(i)));
                vector::append(r, U256ToData(*value));
            }
            else {
                vector::append(r, U256ToData(u256::zero()));
            };
            i = i + 32;
        };
    }

    public fun iszero(n: U256): U256 {
        if(u256::compare(&n, &u256::zero()) == 0) {
            u256::from_u64(1)
        } else {
            u256::zero()
        }
    }

    public fun not(_n: U256): U256 {
        u256::zero()
    }

    public fun add(a: U256, b: U256): U256 {
        u256::add(a, b)
    }

    public fun memoryguard(_n: U256): U256 {
        u256::zero()
    }

    public fun calldatasize(data: vector<u8>): U256 {
        u256::from_u64(vector::length(&data))
    }

    fun u64Todata(num64: u64): vector<u8> {
        let res = vector::empty<u8>();
        let i = 0;
        while(i < 8) {
            let shifted_value = num64 >> (i * 8);
            let byte = ((shifted_value & 0xff) as u8);
            vector::push_back(&mut res, byte);
            i = i + 1;
        };
        vector::reverse(&mut res);
        res
    }

    fun U256ToData(num256: U256): vector<u8> {
        let res = vector::empty<u8>();
        vector::append(&mut res,u64Todata(u256::get(&num256,3)));
        vector::append(&mut res,u64Todata(u256::get(&num256,2)));
        vector::append(&mut res,u64Todata(u256::get(&num256,1)));
        vector::append(&mut res,u64Todata(u256::get(&num256,0)));

        res
    }

    fun dataToU256(data: vector<u8>, p: u64, size: u64): U256 {
        let res = u256::zero();
        let i = 0;
        let len = vector::length(&data);
        while (i < size) {
            if(p + i < len) {
                let value = *vector::borrow(&data, p + i);
                res = u256::add(u256::shl(res, 8), u256::from_u64((value as u64)));
            } else {
                res = u256::shl(res, 8)
            };

            i = i + 1;
        };

        res
    }
}
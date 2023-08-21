
module demo::yul {
    use std::vector;
    use aptos_std::simple_map;
    use u256::u256;
    use u256::u256::U256;
    use aptos_std::simple_map::SimpleMap;

    struct T has key {
        storage: SimpleMap<U256, U256>
    }

    public fun sload(pos: U256): U256 acquires T{
        *simple_map::borrow(&borrow_global<T>(@demo).storage, &pos)
    }

    public fun callvalue(): U256 {
        u256::zero()
    }

    public fun calldataload(_data: vector<u8>, _pos: U256): U256 {
        u256::zero()
    }

    public fun shr(n1: U256, n2: U256): U256 {
        u256::shr(n2, (u256::as_u64(n1) as u8))
    }

    public fun shl(n1: U256, n2: U256): U256 {
        u256::shr(n2, (u256::as_u64(n1) as u8))
    }

    public fun lt(n1: U256, n2: U256): U256 {
        if(u256::compare(&n1, &n2) == 1) {
            u256::zero()
        } else {
            u256::from_u64(1)
        }
    }

    public fun slt(a: U256, b: U256): U256 {
        if(u256::compare(&a, &b) == 1) {
            u256::zero()
        } else {
            u256::from_u64(1)
        }
    }

    public fun eq(a: U256, b: U256): bool {
        return u256::compare(&a, &b) == 0
    }

    public fun gt(a: U256, b: U256): U256 {
        if(u256::compare(&a, &b) == 2) {
            u256::zero()
        } else {
            u256::from_u64(1)
        }
    }

    public fun revert(a: U256, _b: U256) {
        assert!(false, u256::as_u64(a));
    }

    public fun sstore(pos: U256, value: U256) acquires T {
        simple_map::upsert(&mut borrow_global_mut<T>(@demo).storage, pos, value);
    }

    public fun mstore(memory: &mut SimpleMap<U256, U256>, pos: U256, value: U256) {
        simple_map::upsert(memory, pos, value);
    }

    public fun ret(_a: U256, _b:U256) {

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
        u256::from_u64(vector::length(&data) / 32)
    }
}
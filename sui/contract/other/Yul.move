
module demo::yul {
    use std::vector;
    use aptos_std::simple_map;
    use aptos_std::simple_map::SimpleMap;
    // use std::signer;
    // use aptos_framework::object::address_to_object;
    // use aptos_framework::util::address_from_bytes;
    // use aptos_std::from_bcs;
    // use std::signer::borrow_address;
    // use aptos_std::string_utils::{to_string_with_canonical_addresses};
    // use aptos_std::debug;
    // use std::string;
    // use std::string::{bytes, utf8};
    // use aptos_std::from_bcs::to_bytes;
    // use aptos_std::from_bcs::to_bytes;
    // use aptos_std::debug;
    // use aptos_std::aptos_hash;

    struct TestEvent has drop, store {
        number: u256,
    }

    public fun keccak256(_memory: &mut SimpleMap<u256, u256>, _p: u256, _n:u256): u256 {
        0
    }

    public fun mload(memory: &mut SimpleMap<u256, u256>, pos: u256): u256 {
        if(simple_map::contains_key<u256, u256>(memory, &pos))
            *simple_map::borrow(memory, &pos)
        else {
            0
        }
    }

    public fun sload(storage: &mut SimpleMap<u256, u256>, pos: u256): u256{
        let contain = simple_map::contains_key<u256, u256>(storage, &pos);
        if(contain)
            *simple_map::borrow(storage , &pos)
        else {
            0
        }
    }

    public fun callvalue(): u256 {
        0
    }

    public fun calldataload(data: vector<u8>, pos: u256): u256 {
        // let p = u256::as_u64(pos);
        dataToU256(data, pos, 32)
    }

    public fun shr(n1: u256, n2: u256): u256 {
        // let n = u256::shr(n2, (u256::as_u64(n1) as u8));
        // n
        n2 >> (n1 as u8)
    }

    public fun shl(n1: u256, n2: u256): u256 {

        // u256::shr(n2, (u256::as_u64(n1) as u8))
        n2 << (n1 as u8)
    }

    public fun lt(a: u256, b: u256): u256 {
        if(a < b) {
            return 1
        };
        0
    }

    public fun slt(a: u256, b: u256): u256 {
        if(a < b) {
            return 1
        };
        0
    }

    public fun eq(a: u256, b: u256): u256 {
        if(a == b) {
            return 1
        };
        0
    }

    public fun equal(a: u256, b: u256): bool {
        a == b
    }

    public fun gt(a: u256, b: u256): u256 {
        if(a > b) {
            return 1
        };
        0
    }

    public fun and(a: u256, b: u256): u256 {
        a & b
    }

    public fun or(a: u256, b: u256): u256 {
        a | b
    }

    public fun sub(a: u256, b: u256): u256 {
        a - b
    }

    public fun revert(_a: u256, _b: u256) {
        assert!(false, (_a as u64));
    }

    public fun sstore(storage: &mut SimpleMap<u256, u256>, pos: u256, value: u256) {
        simple_map::upsert(storage, pos, value);
    }

    public fun mstore(memory: &mut SimpleMap<u256, u256>, pos: u256, value: u256) {
        simple_map::upsert(memory, pos, value);
    }

    public fun ret(r: &mut vector<u8>, memory: &SimpleMap<u256, u256>, a: u256, b:u256) {
        let i = 0;
        while(i < b) {
            if(simple_map::contains_key(memory, &a)) {
                let value = simple_map::borrow(memory, &(a + i));
                vector::append(r, U256ToData(*value));
            }
            else {
                vector::append(r, U256ToData(0));
            };
            i = i + 32;
        };
    }

    public fun iszero(n: u256): u256 {
        if(n == 0) {
            return 1
        };
        0
    }

    public fun not(_n: u256): u256 {
        0
    }

    public fun add(a: u256, b: u256): u256 {
        a + b
    }

    public fun memoryguard(_n: u256): u256 {
        0
    }

    public fun calldatasize(data: vector<u8>): u256 {
        (vector::length(&data) as u256)
    }

    public fun log3(_p: u256, _s: u256, _t1: u256, _t2: u256, _t3: u256) {

    }

    public fun caller(_sender: address): u256 {

        0
    }

    fun U256ToData(num256: u256): vector<u8> {
        let res = vector::empty<u8>();
        let i = 0;
        while(i < 32) {
            let shifted_value = num256 >> (i * 8);
            let byte = ((shifted_value & 0xff) as u8);
            vector::push_back(&mut res, byte);
            i = i + 1;
        };
        vector::reverse(&mut res);
        res
    }

    fun dataToU256(data: vector<u8>, p: u256, size: u256): u256 {
        let res = 0;
        let i = 0;
        let len = (vector::length(&data) as u256);
        while (i < size) {
            if(p + i < len) {
                let value = *vector::borrow(&data, ((p + i) as u64));
                res = (res << 8) + (value as u256);
            } else {
                res = res << 8
            };

            i = i + 1;
        };

        res
    }
}
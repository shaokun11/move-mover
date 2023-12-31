module demo::evm {
    use std::vector;
    use std::signer;
    use aptos_std::simple_map;
    use aptos_std::simple_map::SimpleMap;
    use std::string::utf8;
    // use aptos_std::table;
    use aptos_std::debug;
    use aptos_std::aptos_hash::keccak256;
    use aptos_framework::event::EventHandle;
    use aptos_framework::account::{new_event_handle};
    use aptos_framework::event;
    use aptos_framework::timestamp::now_microseconds;
    use demo::evmstorage;
    use demo::util::checkCaller;
    use aptos_framework::block;
    use aptos_framework::account;
    #[test_only]
    use aptos_framework::timestamp::{set_time_has_started_for_testing};
    use demo::evmstorage::{transfer, createAccount};
    // #[test_only]
    // use aptos_framework::resource_account;

    const INVALID_SENDER: u64 = 1;
    const INVALID_SIGNER: u64 = 2;

    const CONTRACT_DEPLOYED: u64 = 1000;
    const CONTRACT_READ_ONLY: u64 = 1001;
    const CALL_CONTRACT_NOT_EXIST: u64 = 1002;
    const U256_MAX: u256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    const U255_MAX: u256 = 57896044618658097711785492504343953926634992332820282019728792003956564819967;
    const ZERO_BYTES: vector<u8>    = x"0000000000000000000000000000000000000000000000000000000000000000";
    const WRAP_CONTRACT_ADDR: vector<u8> = x"0000000000000000000000000200000000000000000000000000000000000005";

    struct Log3Event has drop, store {
        contract: vector<u8>,
        data: vector<u8>,
        topic0: vector<u8>,
        topic1: vector<u8>,
        topic2: vector<u8>
    }

    struct Log1Event has drop, store {
        contract: vector<u8>,
        data: vector<u8>,
        topic0: vector<u8>
    }

    struct Log2Event has drop, store {
        contract: vector<u8>,
        data: vector<u8>,
        topic0: vector<u8>,
        topic1: vector<u8>
    }

    struct T has key, store {
        storage: SimpleMap<u256, vector<u8>>,
        runtime: vector<u8>,
        nonce: u256
    }

    struct S has key {
        contracts: simple_map::SimpleMap<vector<u8>, T>,
        log1Event: EventHandle<Log1Event>,
        log2Event: EventHandle<Log2Event>,
        log3Event: EventHandle<Log3Event>,
    }

    entry fun init_module(account: &signer) {
        move_to(account, S {
            contracts: simple_map::create<vector<u8>, T>(),
            log1Event: new_event_handle<Log1Event>(account),
            log2Event: new_event_handle<Log2Event>(account),
            log3Event: new_event_handle<Log3Event>(account),
        });
    }

    public fun deploy(account: &signer, sender: vector<u8>, nonce: u256, construct: vector<u8>, value: u256): vector<u8> acquires S {
        checkCaller(account);
        assert!(vector::length(&sender) == 32, INVALID_SENDER);
        let _account_addr = signer::address_of(account);
        create(sender, nonce, construct, value)
    }

    fun create(sender: vector<u8>, nonce: u256, construct: vector<u8>, value: u256): vector<u8> acquires S {
        let global = borrow_global_mut<S>(@demo);
        let bytes = copy sender;
        vector::append(&mut bytes, u256_to_data(nonce));
        let contract_addr = get_contract_address(sender, nonce);
        assert!(!simple_map::contains_key(&global.contracts, &contract_addr), CONTRACT_DEPLOYED);
        simple_map::add(&mut global.contracts, contract_addr, T {
            storage: simple_map::create<u256, vector<u8>>(),
            runtime: x"",
            nonce: 1
        });

        createAccount(contract_addr, true);

        let runtime = run(global, sender, sender, contract_addr, construct, x"", false, value);
        simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &contract_addr).runtime = runtime;
        contract_addr
    }

    public fun call(account: &signer, sender: vector<u8>, contract_addr: vector<u8>, data: vector<u8>, value: u256) acquires S {
        checkCaller(account);
        let global = borrow_global_mut<S>(@demo);
        assert!(vector::length(&sender) == 32, INVALID_SENDER);
        if(simple_map::contains_key(&global.contracts, &contract_addr)) {
            let contract = simple_map::borrow<vector<u8>, T>(&global.contracts, &contract_addr);
            run(global, sender, sender, copy contract_addr, contract.runtime, data, false, value);
        } else {
            transfer(sender, contract_addr, value);
        }
    }

    #[view]
    public fun view(sender:vector<u8>, contract_addr: vector<u8>, data: vector<u8>): vector<u8> acquires S {
        let global = borrow_global_mut<S>(@demo);
        let contract = simple_map::borrow<vector<u8>, T>(&global.contracts, &contract_addr);
        run(global, sender, sender, copy contract_addr, contract.runtime, data, true, 0)
    }

    fun run(global: &mut S, sender: vector<u8>, origin: vector<u8>, contract_addr: vector<u8>, code: vector<u8>, data: vector<u8>, readOnly: bool, value: u256): vector<u8> {
        transfer(sender, contract_addr, value);
        // aptos_coin::mint()
        let stack = &mut vector::empty<u256>();
        let memory = &mut vector::empty<u8>();
        let storage = simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &contract_addr).storage;
        let len = vector::length(&code);
        let runtime_code = vector::empty<u8>();
        let i = 0;
        let ret_size = 0;
        let ret_bytes = vector::empty<u8>();

        while (i < len) {
            let opcode = *vector::borrow(&code, i);
            // debug::print(&i);
            // debug::print(&opcode);
            // stop
            if(opcode == 0x00) {
                ret_bytes = runtime_code;
                break
            }
            else if(opcode == 0xf3) {
                let pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                // move_ret = read_bytes(*memory, pos, end);
                ret_bytes = slice(*memory, pos, len);
                break
            }
                //add
            else if(opcode == 0x01) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                if(a > 0 && b >= (U256_MAX - a + 1)) {
                    vector::push_back(stack, b - (U256_MAX - a + 1));
                } else {
                    vector::push_back(stack, a + b);
                };
                i = i + 1;
            }
                //mul
            else if(opcode == 0x02) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, a * b);
                i = i + 1;
            }
                //sub
            else if(opcode == 0x03) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                if(a >= b) {
                    vector::push_back(stack, a - b);
                } else {
                    vector::push_back(stack, U256_MAX - b + a + 1);
                };
                i = i + 1;
            }
                //div && sdiv
            else if(opcode == 0x04 || opcode == 0x05) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, a / b);
                i = i + 1;
            }
                //mod && smod
            else if(opcode == 0x06 || opcode == 0x07) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, a % b);
                i = i + 1;
            }
                //addmod
            else if(opcode == 0x08) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                let n = vector::pop_back(stack);
                vector::push_back(stack, (a + b) % n);
                i = i + 1;
            }
                //mulmod
            else if(opcode == 0x09) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                let n = vector::pop_back(stack);
                vector::push_back(stack, (a * b) % n);
                i = i + 1;
            }
                //exp
            else if(opcode == 0x0a) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, power(a, b));
                i = i + 1;
            }
             //lt
            else if(opcode == 0x10) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                if(a < b) {
                    vector::push_back(stack, 1)
                } else {
                    vector::push_back(stack, 0)
                };
                i = i + 1;
            }
            //gt
            else if(opcode == 0x11) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                if(a > b) {
                    vector::push_back(stack, 1)
                } else {
                    vector::push_back(stack, 0)
                };
                i = i + 1;
            }
            //slt
            else if(opcode == 0x12) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                let(sg_a, num_a) = to_int256(a);
                let(sg_b, num_b) = to_int256(b);
                let value = 0;
                if((sg_a && !sg_b) || (sg_a && sg_b && num_a > num_b) || (!sg_a && !sg_b && num_a < num_b)) {
                    value = 1
                };
                vector::push_back(stack, value);
                i = i + 1;
            }
                //sgt
            else if(opcode == 0x13) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                let(sg_a, num_a) = to_int256(a);
                let(sg_b, num_b) = to_int256(b);
                let value = 0;
                if((sg_a && !sg_b) || (sg_a && sg_b && num_a < num_b) || (!sg_a && !sg_b && num_a > num_b)) {
                    value = 1
                };
                vector::push_back(stack, value);
                i = i + 1;
            }
                //eq
            else if(opcode == 0x14) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                if(a == b) {
                    vector::push_back(stack, 1);
                } else {
                    vector::push_back(stack, 0);
                };
                i = i + 1;
            }
                //and
            else if(opcode == 0x16) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, a & b);
                i = i + 1;
            }
                //or
            else if(opcode == 0x17) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, a | b);
                i = i + 1;
            }
                //xor
            else if(opcode == 0x18) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, a ^ b);
                i = i + 1;
            }
                //not
            else if(opcode == 0x19) {
                // 10 1010
                // 6 0101
                let n = vector::pop_back(stack);
                vector::push_back(stack, U256_MAX - n);
                i = i + 1;
            }
                //shl
            else if(opcode == 0x1b) {
                let b = vector::pop_back(stack);
                let a = vector::pop_back(stack);
                if(b >= 256) {
                    vector::push_back(stack, 0);
                } else {
                    vector::push_back(stack, a << (b as u8));
                };
                i = i + 1;
            }
                //shr
            else if(opcode == 0x1c) {
                let b = vector::pop_back(stack);
                let a = vector::pop_back(stack);
                if(b >= 256) {
                    vector::push_back(stack, 0);
                } else {
                    vector::push_back(stack, a >> (b as u8));
                };

                i = i + 1;
            }
                //push0
            else if(opcode == 0x5f) {
                vector::push_back(stack, 0);
                i = i + 1;
            }
                // push1 -> push32
            else if(opcode >= 0x60 && opcode <= 0x7f)  {
                let n = ((opcode - 0x60) as u64);
                let number = data_to_u256(code, ((i + 1) as u256), ((n + 1) as u256));
                vector::push_back(stack, (number as u256));
                i = i + n + 2;
            }
                // pop
            else if(opcode == 0x50) {
                vector::pop_back(stack);
                i = i + 1
            }
                //address
            else if(opcode == 0x30) {
                vector::push_back(stack, data_to_u256(contract_addr, 0, 32));
                i = i + 1;
            }
                //balance
            else if(opcode == 0x31) {
                let addr = u256_to_data(vector::pop_back(stack));
                let (balance, _nonce) = evmstorage::getAccount(addr);
                vector::push_back(stack, balance);
                i = i + 1;
            }
                //origin
            else if(opcode == 0x32) {
                let value = data_to_u256(origin, 0, 32);
                vector::push_back(stack, value);
                i = i + 1;
            }
                //caller
            else if(opcode == 0x33) {
                // debug::print(&utf8(b"caller"));
                // debug::print(&sender);
                let value = data_to_u256(sender, 0, 32);

                // debug::print(&value);
                vector::push_back(stack, value);
                i = i + 1;
            }
                // callvalue
            else if(opcode == 0x34) {
                vector::push_back(stack, value);
                i = i + 1;
            }
                //calldataload
            else if(opcode == 0x35) {
                let pos = vector::pop_back(stack);
                vector::push_back(stack, data_to_u256(data, pos, 32));
                i = i + 1;
                // block.
            }
                //calldatasize
            else if(opcode == 0x36) {
                vector::push_back(stack, (vector::length(&data) as u256));
                i = i + 1;
            }
                //calldatacopy
            else if(opcode == 0x37) {
                let m_pos = vector::pop_back(stack);
                let d_pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                let end = d_pos + len;
                // debug::print(&utf8(b"calldatacopy"));
                // debug::print(&data);
                while (d_pos < end) {
                    // debug::print(&d_pos);
                    // debug::print(&end);
                    let bytes = if(end - d_pos >= 32) {
                        slice(data, d_pos, 32)
                    } else {
                        slice(data, d_pos, end - d_pos)
                    };
                    // debug::print(&bytes);
                    mstore(memory, m_pos, bytes);
                    d_pos = d_pos + 32;
                    m_pos = m_pos + 32;
                };
                i = i + 1
            }
                //codesize
            else if(opcode == 0x38) {
                vector::push_back(stack, (vector::length(&code) as u256));
                i = i + 1
            }
                //codecopy
            else if(opcode == 0x39) {
                let m_pos = vector::pop_back(stack);
                let d_pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                let end = d_pos + len;
                runtime_code = slice(code, d_pos, len);
                while (d_pos < end) {
                    let bytes = if(end - d_pos >= 32) {
                        slice(code, d_pos, 32)
                    } else {
                        slice(code, d_pos, end - d_pos)
                    };
                    mstore(memory, m_pos, bytes);
                    d_pos = d_pos + 32;
                    m_pos = m_pos + 32;
                };
                i = i + 1
            }
                //extcodesize
            else if(opcode == 0x3b) {
                let bytes = u256_to_data(vector::pop_back(stack));
                let addr = to_32bit(slice(bytes, 12, 20));
                if(simple_map::contains_key(&mut global.contracts, &addr)) {
                    let code = simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &addr).runtime;
                    vector::push_back(stack, (vector::length(&code) as u256));
                } else {
                    vector::push_back(stack, 0);
                };

                i = i + 1;
            }
                //returndatacopy
            else if(opcode == 0x3e) {
                // mstore()
                let m_pos = vector::pop_back(stack);
                let d_pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                let bytes = slice(ret_bytes, d_pos, len);
                mstore(memory, m_pos, bytes);
                i = i + 1;
            }
                //returndatasize
            else if(opcode == 0x3d) {
                vector::push_back(stack, ret_size);
                i = i + 1;
            }
                //blockhash
            else if(opcode == 0x40) {
                vector::push_back(stack, 0);
                i = i + 1;
            }
                //coinbase
            else if(opcode == 0x41) {
                vector::push_back(stack, 0);
                i = i + 1;
            }
                //timestamp
            else if(opcode == 0x42) {
                vector::push_back(stack, (now_microseconds() as u256) / 1000000);
                i = i + 1;
            }
                //number
            else if(opcode == 0x43) {
                vector::push_back(stack, (block::get_current_block_height() as u256));
                i = i + 1;
            }
                //difficulty
            else if(opcode == 0x44) {
                vector::push_back(stack, 0);
                i = i + 1;
            }
                //gaslimit
            else if(opcode == 0x45) {
                vector::push_back(stack, 30000000);
                i = i + 1;
            }
                //chainid
            else if(opcode == 0x46) {
                vector::push_back(stack, 1);
                i = i + 1
            }
                //self balance
            else if(opcode == 0x47) {
                let (balance, _nonce) = evmstorage::getAccount(contract_addr);
                vector::push_back(stack, balance);
                i = i + 1;
            }
                // mload
            else if(opcode == 0x51) {
                let pos = vector::pop_back(stack);
                vector::push_back(stack, data_to_u256(slice(*memory, pos, 32), 0, 32));
                i = i + 1;
            }
                // mstore
            else if(opcode == 0x52) {
                let pos = vector::pop_back(stack);
                let value = vector::pop_back(stack);
                mstore(memory, pos, u256_to_data(value));
                // debug::print(memory);
                i = i + 1;

            }
            //mstore8
            else if(opcode == 0x53) {
                let pos = vector::pop_back(stack);
                let value = vector::pop_back(stack);
                *vector::borrow_mut(memory, (pos as u64)) = ((value & 0xff) as u8);
                // mstore(memory, pos, u256_to_data(value & 0xff));
                // debug::print(memory);
                i = i + 1;

            }
                // sload
            else if(opcode == 0x54) {
                let pos = vector::pop_back(stack);
                if(simple_map::contains_key(&mut storage, &pos)) {
                    let value = *simple_map::borrow(&mut storage, &pos);
                    vector::push_back(stack, data_to_u256(value, 0, 32));
                } else {
                    vector::push_back(stack, 0);
                };
                i = i + 1;
            }
                // sstore
            else if(opcode == 0x55) {
                if(readOnly) {
                    assert!(false, CONTRACT_READ_ONLY);
                };
                let pos = vector::pop_back(stack);
                let value = vector::pop_back(stack);
                simple_map::upsert(&mut storage, pos, u256_to_data(value));
                // debug::print(&utf8(b"sstore"));
                // debug::print(&contract_addr);
                // debug::print(&pos);
                // debug::print(&value);
                i = i + 1;
            }
                //dup1 -> dup16
            else if(opcode >= 0x80 && opcode <= 0x8f) {
                let size = vector::length(stack);
                let value = *vector::borrow(stack, size - ((opcode - 0x80 + 1) as u64));
                vector::push_back(stack, value);
                i = i + 1;
            }
                //swap1 -> swap16
            else if(opcode >= 0x90 && opcode <= 0x9f) {
                let size = vector::length(stack);
                vector::swap(stack, size - 1, size - ((opcode - 0x90 + 2) as u64));
                i = i + 1;
            }
                //iszero
            else if(opcode == 0x15) {
                let value = vector::pop_back(stack);
                if(value == 0) {
                    vector::push_back(stack, 1)
                } else {
                    vector::push_back(stack, 0)
                };
                i = i + 1;
            }
                //jump
            else if(opcode == 0x56) {
                let dest = vector::pop_back(stack);
                i = (dest as u64) + 1
            }
                //jumpi
            else if(opcode == 0x57) {
                let dest = vector::pop_back(stack);
                let condition = vector::pop_back(stack);
                if(condition > 0) {
                    i = (dest as u64) + 1
                } else {
                    i = i + 1
                }
            }
                //gas
            else if(opcode == 0x5a) {
                vector::push_back(stack, 0);
                i = i + 1
            }
                //jump dest (no action, continue execution)
            else if(opcode == 0x5b) {
                i = i + 1
            }
                //sha3
            else if(opcode == 0x20) {
                let pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                let bytes = slice(*memory, pos, len);
                // debug::print(&utf8(b"sha3"));
                // debug::print(&bytes);
                let value = data_to_u256(keccak256(bytes), 0, 32);
                // debug::print(&value);
                vector::push_back(stack, value);
                i = i + 1
            }
                //call 0xf1 static call 0xfa delegate call 0xf4
            else if(opcode == 0xf1 || opcode == 0xfa || opcode == 0xf4) {
                let readOnly = if (opcode == 0xfa) true else false;
                let _gas = vector::pop_back(stack);
                let dest_addr = to_32bit(u256_to_data(vector::pop_back(stack)));
                let msg_value = if (opcode == 0xf1) vector::pop_back(stack) else 0;
                let m_pos = vector::pop_back(stack);
                let m_len = vector::pop_back(stack);
                let ret_pos = vector::pop_back(stack);
                let ret_len = vector::pop_back(stack);

                // debug::print(&utf8(b"call 222"));
                // debug::print(&opcode);
                // debug::print(&dest_addr);
                if (simple_map::contains_key(&global.contracts, &dest_addr)) {
                    let ret_end = ret_len + ret_pos;
                    let params = slice(*memory, m_pos, m_len);
                    let runtime = simple_map::borrow(&mut global.contracts, &dest_addr).runtime;
                    let target = if (opcode == 0xf4) contract_addr else dest_addr;
                    let from = if (opcode == 0xf4) sender else contract_addr;
                    // debug::print(&utf8(b"call"));
                    // debug::print(&params);
                    // if(opcode == 0xf4) {
                    //     debug::print(&utf8(b"delegate call"));
                    //     debug::print(&sender);
                    //     debug::print(&target);
                    // };
                    ret_bytes = run(global, from, sender, target, runtime, params, readOnly, msg_value);
                    ret_size = (vector::length(&ret_bytes) as u256);
                    let index = 0;
                    if(opcode == 0xf4) {
                        storage = simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &contract_addr).storage;
                    };
                    while (ret_pos < ret_end) {
                        let bytes = if (ret_end - ret_pos >= 32) {
                            slice(ret_bytes, index, 32)
                        } else {
                            slice(ret_bytes, index, ret_end - ret_pos)
                        };
                        mstore(memory, ret_pos, bytes);
                        ret_pos = ret_pos + 32;
                        index = index + 32;
                    };
                    vector::push_back(stack, 1);
                } else {
                    if (opcode == 0xfa) {
                        vector::push_back(stack, 0);
                    } else {
                        transfer(contract_addr, dest_addr, msg_value);
                    }
                };
                // debug::print(&opcode);
                i = i + 1
            }
                //create
            else if(opcode == 0xf0) {
                if(readOnly) {
                    assert!(false, CONTRACT_READ_ONLY);
                };
                let msg_value = vector::pop_back(stack);
                let pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                let new_codes = slice(*memory, pos, len);
                let nonce = simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &contract_addr).nonce;
                // must be 20 bytes

                let new_contract_addr = get_contract_address(contract_addr, nonce);
                simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &contract_addr).nonce = nonce + 1;

                assert!(!simple_map::contains_key(&mut global.contracts, &new_contract_addr), CONTRACT_DEPLOYED);
                simple_map::add(&mut global.contracts, new_contract_addr,  T {
                    storage: simple_map::create<u256, vector<u8>>(),
                    runtime: x"",
                    nonce: 1
                });
                debug::print(&utf8(b"create start"));
                // debug::print(&nonce);
                let runtime = run(global, copy contract_addr, sender, new_contract_addr, new_codes, x"", false, msg_value);
                debug::print(&new_contract_addr);
                debug::print(&utf8(b"create end"));

                ret_size = 32;
                ret_bytes = new_contract_addr;
                simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &new_contract_addr).runtime = runtime;
                vector::push_back(stack, data_to_u256(new_contract_addr,0, 32));
                i = i + 1
            }
                //create2
            else if(opcode == 0xf5) {
                if(readOnly) {
                    assert!(false, CONTRACT_READ_ONLY);
                };
                let msg_value = vector::pop_back(stack);
                let pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                let salt = u256_to_data(vector::pop_back(stack));
                let new_codes = slice(*memory, pos, len);
                let p = vector::empty<u8>();
                vector::append(&mut p, x"ff");
                // must be 20 bytes
                vector::append(&mut p, slice(contract_addr, 12, 20));
                vector::append(&mut p, salt);
                vector::append(&mut p, keccak256(new_codes));
                let new_contract_addr = to_32bit(slice(keccak256(p), 12, 20));
                // let contracts = &mut borrow_global_mut<S>(@demo).contracts;
                assert!(!simple_map::contains_key(&mut global.contracts, &new_contract_addr), CONTRACT_DEPLOYED);
                simple_map::add(&mut global.contracts, new_contract_addr,  T {
                    storage: simple_map::create<u256, vector<u8>>(),
                    runtime: x"",
                    nonce: 1
                });
                // debug::print(&utf8(b"create2 start"));
                // debug::print(&p);
                // debug::print(&new_codes);
                // debug::print(&new_contract_addr);
                let runtime = run(global, copy contract_addr, sender, new_contract_addr, new_codes, x"", false, msg_value);
                // debug::print(&utf8(b"create2 end"));

                let nonce = simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &contract_addr).nonce;
                simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &contract_addr).nonce = nonce + 1;
                ret_size = 32;
                ret_bytes = new_contract_addr;
                simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &new_contract_addr).runtime = runtime;
                vector::push_back(stack, data_to_u256(new_contract_addr,0, 32));
                i = i + 1
            }
                //revert
            else if(opcode == 0xfd) {
                let pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                let bytes = slice(*memory, pos, len);
                debug::print(&bytes);
                // debug::print(&pos);
                // debug::print(&len);
                // debug::print(memory);
                i = i + 1;
                assert!(false, (opcode as u64));
            }
                //log1
            else if(opcode == 0xa1) {
                let pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                let data = slice(*memory, pos, len);
                let topic0 = u256_to_data(vector::pop_back(stack));
                event::emit_event<Log1Event>(
                    &mut global.log1Event,
                    Log1Event{
                        contract: contract_addr,
                        data,
                        topic0,
                    },
                );
                i = i + 1
            }
                //log2
            else if(opcode == 0xa2) {
                let pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                let data = slice(*memory, pos, len);
                let topic0 = u256_to_data(vector::pop_back(stack));
                let topic1 = u256_to_data(vector::pop_back(stack));
                event::emit_event<Log2Event>(
                    &mut global.log2Event,
                    Log2Event{
                        contract: contract_addr,
                        data,
                        topic0,
                        topic1
                    },
                );
                i = i + 1
            }
                //log3
            else if(opcode == 0xa3) {
                let pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                let data = slice(*memory, pos, len);
                let topic0 = u256_to_data(vector::pop_back(stack));
                let topic1 = u256_to_data(vector::pop_back(stack));
                let topic2 = u256_to_data(vector::pop_back(stack));
                event::emit_event<Log3Event>(
                    &mut global.log3Event,
                    Log3Event{
                        contract: contract_addr,
                        data,
                        topic0,
                        topic1,
                        topic2
                    },
                );
                i = i + 1
            }
            else {
                assert!(false, (opcode as u64));
            };
            // debug::print(stack);
            // debug::print(&vector::length(stack));
        };
        simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &contract_addr).storage = storage;
        ret_bytes
    }

    fun mstore(memory: &mut vector<u8>, pos: u256, data: vector<u8>) {
        let len_m = vector::length(memory);
        let len_d = vector::length(&data);
        let p = (pos as u64);
        while(len_m < p) {
            vector::push_back(memory, 0);
            len_m = len_m + 1
        };

        let i = 0;
        while (i < len_d) {
            if(len_m <= p + i) {
                vector::push_back(memory, *vector::borrow(&data, i));
                len_m = len_m + 1;
            } else {
                *vector::borrow_mut(memory, p + i) = *vector::borrow(&data, i);
            };

            i = i + 1
        };
    }

    fun power(base: u256, exponent: u256): u256 {
        let result = 1;

        let i = 0;
        while (i < exponent) {
            result = result * base;
            i = i + 1;
        };

        result
    }

    fun slice(data: vector<u8>, pos: u256, size: u256): vector<u8> {
        let s = vector::empty<u8>();
        let i = 0;
        let len = vector::length(&data);
        while (i < size) {
            let p = ((pos + i) as u64);
            if(p >= len) {
                vector::push_back(&mut s, 0);
            } else {
                vector::push_back(&mut s, *vector::borrow(&data, (pos + i as u64)));
            };

            i = i + 1;
        };
        s
    }

    fun read_value(map: simple_map::SimpleMap<u256, vector<u8>>, pos: u256): vector<u8> {
        if(simple_map::contains_key(&map, &pos)) {
            *simple_map::borrow(&map, &pos)
        } else {
            ZERO_BYTES
        }
    }

    fun read_bytes(map: simple_map::SimpleMap<u256, vector<u8>>, pos: u256, end: u256): vector<u8> {
        let bytes = vector::empty<u8>();
        let mod = pos % 32;
        // last bit mod...32, next bit 0 ... mod
        if(mod > 0) {
            let last_bit = slice(read_value(map, pos - mod), mod, 32 - mod);
            vector::append(&mut bytes, last_bit);
            pos = pos + 32 - mod
        };
        while(pos < end) {
            if(simple_map::contains_key(&map, &pos)) {
                let value = simple_map::borrow(&map, &pos);
                if(end - pos < 32) {
                    vector::append(&mut bytes, slice(*value, 0, end - pos));
                } else {
                    vector::append(&mut bytes, *value);
                }

            };
            pos = pos + 32;
        };

        bytes
    }

    fun get_contract_address(addr: vector<u8>, nonce: u256): vector<u8> {
        let nonce_bytes = vector::empty<u8>();
        let l = 0;
        while(nonce > 0) {
            l = l + 1;
            vector::push_back(&mut nonce_bytes, ((nonce % 0x100) as u8));
            nonce = nonce / 0x100;
        };
        if(l == 0) {
            vector::push_back(&mut nonce_bytes, 0x80);
            l = 1;
        } else if(l > 1) {
            vector::push_back(&mut nonce_bytes, 0x80 + l);
            l = l + 1;
        };
        vector::reverse(&mut nonce_bytes);

        let salt = vector::empty<u8>();
        vector::push_back(&mut salt, l + 0xc0 + 0x15);
        vector::push_back(&mut salt, 0x94);
        vector::append(&mut salt, slice(addr, 12, 20));
        vector::append(&mut salt, nonce_bytes);
        to_32bit(slice(keccak256(salt), 12, 20))
    }

    fun u256_to_data(num256: u256): vector<u8> {
        let res = vector::empty<u8>();
        let i = 32;
        while(i > 0) {
            i = i - 1;
            let shifted_value = num256 >> (i * 8);
            let byte = ((shifted_value & 0xff) as u8);
            vector::push_back(&mut res, byte);
        };
        res
    }

    fun data_to_u256(data: vector<u8>, p: u256, size: u256): u256 {
        let res = 0;
        let i = 0;
        let len = (vector::length(&data) as u256);
        assert!(size <= 32, 1);
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

    fun to_int256(num: u256): (bool, u256) {
        let neg = false;
        if(num > U255_MAX) {
            neg = true;
            num = U256_MAX - num + 1;
        };
        (neg, num)
    }

    fun to_32bit(data: vector<u8>): vector<u8> {
        let bytes = vector::empty<u8>();
        let len = vector::length(&data);
        // debug::print(&len);
        while(len < 32) {
            vector::push_back(&mut bytes, 0);
            len = len + 1
        };
        vector::append(&mut bytes, data);
        bytes
    }

    #[view]
    public fun getStorageAt(addr: vector<u8>, slot: vector<u8>): vector<u8> acquires S {
        let global = borrow_global<S>(@demo);
        if(simple_map::contains_key(&global.contracts, &addr)) {
            let storage = simple_map::borrow<vector<u8>, T>(&global.contracts, &addr).storage;
            *simple_map::borrow(&storage, &data_to_u256(slot, 0, (vector::length(&slot) as u256)))
        } else {
            vector::empty<u8>()
        }
    }

    #[view]
    public fun getCode(addr: vector<u8>): vector<u8> acquires S {
        let global = borrow_global<S>(@demo);
        if(simple_map::contains_key(&global.contracts, &addr)) {
            simple_map::borrow(&global.contracts, &addr).runtime
        } else {
            vector::empty<u8>()
        }
    }

    #[test_only]
    public fun init_module_for_test(account: &signer) {
        init_module(account);
    }



    #[test(admin = @demo)]
    fun testForge() acquires S {
        debug::print(&get_contract_address(to_32bit(x"892a2b7cF919760e148A0d33C1eb0f44D3b383f8"), 0));

        let sender = to_32bit(x"892a2b7cF919760e148A0d33C1eb0f44D3b383f8");

        let aptos = account::create_account_for_test(@0x1);
        // let evm = account::create_account_for_test(@demo);

        let user = account::create_account_for_test(@signer);
        evmstorage::init_module_for_test(&user);
        set_time_has_started_for_testing(&aptos);
        block::initialize_for_test(&aptos, 500000000);
        init_module(&user);

        let c3_init_code = x"60806040523480156200001157600080fd5b506040805180820190915260048152631d195cdd60e21b602082015233906200003a816200007c565b506001600160a01b0381166200006a57604051631e4fbdf760e01b81526000600482015260240160405180910390fd5b62000075816200008e565b5062000251565b60026200008a828262000185565b5050565b600380546001600160a01b038381166001600160a01b0319831681179093556040519116919082907f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e090600090a35050565b634e487b7160e01b600052604160045260246000fd5b600181811c908216806200010b57607f821691505b6020821081036200012c57634e487b7160e01b600052602260045260246000fd5b50919050565b601f8211156200018057600081815260208120601f850160051c810160208610156200015b5750805b601f850160051c820191505b818110156200017c5782815560010162000167565b5050505b505050565b81516001600160401b03811115620001a157620001a1620000e0565b620001b981620001b28454620000f6565b8462000132565b602080601f831160018114620001f15760008415620001d85750858301515b600019600386901b1c1916600185901b1785556200017c565b600085815260208120601f198616915b82811015620002225788860151825594840194600190910190840162000201565b5085821015620002415787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b6114ff80620002616000396000f3fe6080604052600436106100dc5760003560e01c80634e1273f41161007f578063a22cb46511610059578063a22cb46514610250578063e985e9c514610270578063f242432a14610290578063f2fde38b146102b057600080fd5b80634e1273f4146101e6578063715018a6146102135780638da5cb5b1461022857600080fd5b80631b2ef1ca116100bb5780631b2ef1ca146101715780631f7fdffa146101865780632baf2acb146101a65780632eb2c2d6146101c657600080fd5b8062fdd58e146100e157806301ffc9a7146101145780630e89341c14610144575b600080fd5b3480156100ed57600080fd5b506101016100fc366004610d98565b6102d0565b6040519081526020015b60405180910390f35b34801561012057600080fd5b5061013461012f366004610dd8565b6102f8565b604051901515815260200161010b565b34801561015057600080fd5b5061016461015f366004610dfc565b610348565b60405161010b9190610e5b565b61018461017f366004610e6e565b6103dc565b005b34801561019257600080fd5b506101846101a1366004610fd6565b6103fb565b3480156101b257600080fd5b506101846101c136600461106f565b610415565b3480156101d257600080fd5b506101846101e13660046110a2565b610435565b3480156101f257600080fd5b5061020661020136600461114c565b6104a1565b60405161010b9190611247565b34801561021f57600080fd5b50610184610576565b34801561023457600080fd5b506003546040516001600160a01b03909116815260200161010b565b34801561025c57600080fd5b5061018461026b36600461125a565b61058a565b34801561027c57600080fd5b5061013461028b366004611296565b610595565b34801561029c57600080fd5b506101846102ab3660046112c9565b6105c3565b3480156102bc57600080fd5b506101846102cb36600461132e565b610622565b6000818152602081815260408083206001600160a01b03861684529091529020545b92915050565b60006001600160e01b03198216636cdb3d1360e11b148061032957506001600160e01b031982166303a24d0760e21b145b806102f257506301ffc9a760e01b6001600160e01b03198316146102f2565b60606002805461035790611349565b80601f016020809104026020016040519081016040528092919081815260200182805461038390611349565b80156103d05780601f106103a5576101008083540402835291602001916103d0565b820191906000526020600020905b8154815290600101906020018083116103b357829003601f168201915b50505050509050919050565b6103f733838360405180602001604052806000815250610660565b5050565b6104036106bd565b61040f848484846106ea565b50505050565b61043083838360405180602001604052806000815250610660565b505050565b336001600160a01b038616811480159061045657506104548682610595565b155b1561048c5760405163711bec9160e11b81526001600160a01b038083166004830152871660248201526044015b60405180910390fd5b6104998686868686610722565b505050505050565b606081518351146104d25781518351604051635b05999160e01b815260048101929092526024820152604401610483565b6000835167ffffffffffffffff8111156104ee576104ee610e90565b604051908082528060200260200182016040528015610517578160200160208202803683370190505b50905060005b845181101561056e57602080820286010151610541906020808402870101516102d0565b82828151811061055357610553611383565b6020908102919091010152610567816113af565b905061051d565b509392505050565b61057e6106bd565b6105886000610789565b565b6103f73383836107db565b6001600160a01b03918216600090815260016020908152604080832093909416825291909152205460ff1690565b336001600160a01b03861681148015906105e457506105e28682610595565b155b156106155760405163711bec9160e11b81526001600160a01b03808316600483015287166024820152604401610483565b6104998686868686610871565b61062a6106bd565b6001600160a01b03811661065457604051631e4fbdf760e01b815260006004820152602401610483565b61065d81610789565b50565b6001600160a01b03841661068a57604051632bfa23e760e11b815260006004820152602401610483565b604080516001808252602082018690528183019081526060820185905260808201909252906104996000878484876108ff565b6003546001600160a01b031633146105885760405163118cdaa760e01b8152336004820152602401610483565b6001600160a01b03841661071457604051632bfa23e760e11b815260006004820152602401610483565b61040f6000858585856108ff565b6001600160a01b03841661074c57604051632bfa23e760e11b815260006004820152602401610483565b6001600160a01b03851661077557604051626a0d4560e21b815260006004820152602401610483565b61078285858585856108ff565b5050505050565b600380546001600160a01b038381166001600160a01b0319831681179093556040519116919082907f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e090600090a35050565b6001600160a01b0382166108045760405162ced3e160e81b815260006004820152602401610483565b6001600160a01b03838116600081815260016020908152604080832094871680845294825291829020805460ff191686151590811790915591519182527f17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31910160405180910390a3505050565b6001600160a01b03841661089b57604051632bfa23e760e11b815260006004820152602401610483565b6001600160a01b0385166108c457604051626a0d4560e21b815260006004820152602401610483565b604080516001808252602082018690528183019081526060820185905260808201909252906108f687878484876108ff565b50505050505050565b61090b85858585610952565b6001600160a01b038416156107825782513390600103610944576020848101519084015161093d838989858589610b6f565b5050610499565b610499818787878787610c93565b80518251146109815781518151604051635b05999160e01b815260048101929092526024820152604401610483565b3360005b8351811015610a90576020818102858101820151908501909101516001600160a01b03881615610a38576000828152602081815260408083206001600160a01b038c16845290915290205481811015610a11576040516303dee4c560e01b81526001600160a01b038a166004820152602481018290526044810183905260648101849052608401610483565b6000838152602081815260408083206001600160a01b038d16845290915290209082900390555b6001600160a01b03871615610a7d576000828152602081815260408083206001600160a01b038b16845290915281208054839290610a779084906113c8565b90915550505b505080610a89906113af565b9050610985565b508251600103610b115760208301516000906020840151909150856001600160a01b0316876001600160a01b0316846001600160a01b03167fc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f628585604051610b02929190918252602082015260400190565b60405180910390a45050610782565b836001600160a01b0316856001600160a01b0316826001600160a01b03167f4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb8686604051610b609291906113db565b60405180910390a45050505050565b6001600160a01b0384163b156104995760405163f23a6e6160e01b81526001600160a01b0385169063f23a6e6190610bb39089908990889088908890600401611409565b6020604051808303816000875af1925050508015610bee575060408051601f3d908101601f19168201909252610beb9181019061144e565b60015b610c57573d808015610c1c576040519150601f19603f3d011682016040523d82523d6000602084013e610c21565b606091505b508051600003610c4f57604051632bfa23e760e11b81526001600160a01b0386166004820152602401610483565b805181602001fd5b6001600160e01b0319811663f23a6e6160e01b146108f657604051632bfa23e760e11b81526001600160a01b0386166004820152602401610483565b6001600160a01b0384163b156104995760405163bc197c8160e01b81526001600160a01b0385169063bc197c8190610cd7908990899088908890889060040161146b565b6020604051808303816000875af1925050508015610d12575060408051601f3d908101601f19168201909252610d0f9181019061144e565b60015b610d40573d808015610c1c576040519150601f19603f3d011682016040523d82523d6000602084013e610c21565b6001600160e01b0319811663bc197c8160e01b146108f657604051632bfa23e760e11b81526001600160a01b0386166004820152602401610483565b80356001600160a01b0381168114610d9357600080fd5b919050565b60008060408385031215610dab57600080fd5b610db483610d7c565b946020939093013593505050565b6001600160e01b03198116811461065d57600080fd5b600060208284031215610dea57600080fd5b8135610df581610dc2565b9392505050565b600060208284031215610e0e57600080fd5b5035919050565b6000815180845260005b81811015610e3b57602081850181015186830182015201610e1f565b506000602082860101526020601f19601f83011685010191505092915050565b602081526000610df56020830184610e15565b60008060408385031215610e8157600080fd5b50508035926020909101359150565b634e487b7160e01b600052604160045260246000fd5b604051601f8201601f1916810167ffffffffffffffff81118282101715610ecf57610ecf610e90565b604052919050565b600067ffffffffffffffff821115610ef157610ef1610e90565b5060051b60200190565b600082601f830112610f0c57600080fd5b81356020610f21610f1c83610ed7565b610ea6565b82815260059290921b84018101918181019086841115610f4057600080fd5b8286015b84811015610f5b5780358352918301918301610f44565b509695505050505050565b600082601f830112610f7757600080fd5b813567ffffffffffffffff811115610f9157610f91610e90565b610fa4601f8201601f1916602001610ea6565b818152846020838601011115610fb957600080fd5b816020850160208301376000918101602001919091529392505050565b60008060008060808587031215610fec57600080fd5b610ff585610d7c565b9350602085013567ffffffffffffffff8082111561101257600080fd5b61101e88838901610efb565b9450604087013591508082111561103457600080fd5b61104088838901610efb565b9350606087013591508082111561105657600080fd5b5061106387828801610f66565b91505092959194509250565b60008060006060848603121561108457600080fd5b61108d84610d7c565b95602085013595506040909401359392505050565b600080600080600060a086880312156110ba57600080fd5b6110c386610d7c565b94506110d160208701610d7c565b9350604086013567ffffffffffffffff808211156110ee57600080fd5b6110fa89838a01610efb565b9450606088013591508082111561111057600080fd5b61111c89838a01610efb565b9350608088013591508082111561113257600080fd5b5061113f88828901610f66565b9150509295509295909350565b6000806040838503121561115f57600080fd5b823567ffffffffffffffff8082111561117757600080fd5b818501915085601f83011261118b57600080fd5b8135602061119b610f1c83610ed7565b82815260059290921b840181019181810190898411156111ba57600080fd5b948201945b838610156111df576111d086610d7c565b825294820194908201906111bf565b965050860135925050808211156111f557600080fd5b5061120285828601610efb565b9150509250929050565b600081518084526020808501945080840160005b8381101561123c57815187529582019590820190600101611220565b509495945050505050565b602081526000610df5602083018461120c565b6000806040838503121561126d57600080fd5b61127683610d7c565b91506020830135801515811461128b57600080fd5b809150509250929050565b600080604083850312156112a957600080fd5b6112b283610d7c565b91506112c060208401610d7c565b90509250929050565b600080600080600060a086880312156112e157600080fd5b6112ea86610d7c565b94506112f860208701610d7c565b93506040860135925060608601359150608086013567ffffffffffffffff81111561132257600080fd5b61113f88828901610f66565b60006020828403121561134057600080fd5b610df582610d7c565b600181811c9082168061135d57607f821691505b60208210810361137d57634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b6000600182016113c1576113c1611399565b5060010190565b808201808211156102f2576102f2611399565b6040815260006113ee604083018561120c565b8281036020840152611400818561120c565b95945050505050565b6001600160a01b03868116825285166020820152604081018490526060810183905260a06080820181905260009061144390830184610e15565b979650505050505050565b60006020828403121561146057600080fd5b8151610df581610dc2565b6001600160a01b0386811682528516602082015260a0604082018190526000906114979083018661120c565b82810360608401526114a9818661120c565b905082810360808401526114bd8185610e15565b9897505050505050505056fea264697066735822122054058bdb2d56533137d83859ade84cff8201bb3adbcc217273ef1072846baa2e64736f6c63430008140033";
        let c3_addr = create(sender, 0x0, c3_init_code, 0);
        debug::print(&utf8(b"create c3"));
        debug::print(&c3_addr);

        // let time = now_microseconds();
        // update_global_time_for_test(time + 1000000000 * 1000000);
        //
        // let c3_call_code_1 = x"3ccfd60b";
        // debug::print(&utf8(b"call c3 1"));
        // call(&user, sender, c3_addr, c3_call_code_1, 0);


        //
        //
        // let c3_call_code_2 = x"cdcb760a1ee7f501f3f5533b3d04abb81ad8b353b31acf2eeaaff8b6a421d84fe8710dd700000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000001d80608080604052346100c1576000549060ff8260081c1661006f575060ff80821603610034575b604051611caa90816100c78239f35b60ff90811916176000557f7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498602060405160ff8152a138610025565b62461bcd60e51b815260206004820152602760248201527f496e697469616c697a61626c653a20636f6e747261637420697320696e697469604482015266616c697a696e6760c81b6064820152608490fd5b600080fdfe6040608081526004908136101561001557600080fd5b600091823560e01c8063045f5e19146116605780630487a1f91461057f578063059dfe13146115b957806306fdde03146115845780630cdaf3921461149b5780631008c6ca146113a8578063173b6d901461138b57806335950fed1461134d578063429b62e51461134d5780634ef47cf114611315578063670a6fd91461121a57806370284d191461110f57806379502c55146110e35780637e19275f14610d7157806384da92a714610b3f5780638f449a05146108495780639714378c14610730578063a878f9f81461066c578063ab2c19bb146105bd578063aeb5b9301461057f578063ca0f9c63146102d4578063d2718541146102b5578063d57f966b14610296578063f3fef3a3146101bb578063f56f3eb7146101745763fdbda0ec1461013f57600080fd5b346101705760203660031901126101705735825260056020908152918190205490516001600160a01b039091168152f35b8280fd5b5050346101b75760203660031901126101b7576101b06020926101ab60ff8461019b6116ea565b93338152600888522054166119f9565b611af7565b9051908152f35b5080fd5b5090346101705780600319360112610170576101d56116ea565b6024359233855260086020526101f060ff84872054166119f9565b83471061025357506001600160a01b03169083838382821561024a575b839283928392f11561024157507f884edad9ce6fa2440d8a54cc123490eb96d2768479d49ff9c7366125a94243648380a380f35b513d84823e3d90fd5b506108fc61020d565b606490602084519162461bcd60e51b8352820152601c60248201527f4d757365756d3a20696e73756666696369656e742062616c616e6365000000006044820152fd5b5050346101b757816003193601126101b7576020906003549051908152f35b5050346101b757816003193601126101b7576020906002549051908152f35b509190346101b75760a03660031901126101b75767ffffffffffffffff9183358381116101b7576103089036908601611775565b906103116118f1565b936064359081116101b7576103299036908701611775565b9460843595861515809703610170576103bb903384526020976008895261035560ff88872054166119f9565b6103a7875198899360ff6103878d87019a6318da16cb60e31b8c5230602489015260c0604489015260e48801906118a2565b9216606486015260443560848601528482036023190160a48601526118a2565b9060c483015203601f198101875286611737565b8451832082548551633166ef0160e01b81526001600160a01b03959291899082908690829060101c8a165afa90811561057557906e5af43d82803e903d91602b57fd5bf3918691610548575b50763d602d80600a3d3981f3363d3d373d3d3d363d7300000062ffffff8260881c1617865260781b1788526037600985f59384169586156105055783918291519082875af13d15610500573d61045c81611759565b9061046987519283611737565b815283883d92013e5b156104ad575090837fadfce766758cc4c5f09e2c4eb407adf4e52e07425240b614192262fd9bd90ddf836104a694a2611af7565b5051908152f35b835162461bcd60e51b8152908101869052602760248201527f4d757365756d3a206661696c656420746f20696e697469616c697a6520636f6c6044820152663632b1ba34b7b760c91b6064820152608490fd5b610472565b855162461bcd60e51b8152808401899052601760248201527f455243313136373a2063726561746532206661696c65640000000000000000006044820152606490fd5b61056891508a3d8c1161056e575b6105608183611737565b810190611a5e565b38610407565b503d610556565b87513d87823e3d90fd5b5050346101b75760203660031901126101b75760209160ff9082906001600160a01b036105aa6116ea565b1681526009855220541690519015158152f35b50346101705760203660031901126101705780359033845260086020526105e960ff84862054166119f9565b81156106295750907fef5cc5a2e67e9391dd239d5f4449dc600fe7ecbb5dfa639ef4db0a903d888f0c91600254908060025582519182526020820152a180f35b606490602084519162461bcd60e51b8352820152602060248201527f4d757365756d3a20696e76616c69642076616c7565506572426c6f636b4665656044820152fd5b509190346101b757806003193601126101b757823567ffffffffffffffff81116101705761069d9036908501611775565b6106a56118f1565b92338152602094600886526106bf60ff85842054166119f9565b6103bb6106ca611a3a565b61071b865197889260ff6106fc8c8601996318da16cb60e31b8b5230602488015260c0604488015260e48701906118a2565b92166064850152600160848501528382036023190160a48501526118a2565b600160c483015203601f198101875286611737565b5090602080600319360112610845578235926002549061075282341015611b82565b61076561075f8334611bce565b15611bee565b84865260068352838620546001600160a01b03161561080257506001929161078f60069234611c30565b85875282825284848820019081544381106000146107f157506107b3915043611ad4565b8587528282528484882001555b848652528320015433917fb6064ad24cce9e22efde7b4d2e482c7dac0b4247d311545dbd97cc684e5b0bc78480a480f35b906107fb91611ad4565b90556107c0565b835162461bcd60e51b8152908101839052601c60248201527f4d757365756d3a20696e76616c696420737562736372697074696f6e000000006044820152606490fd5b8380fd5b509190816003193601126101b7576002549261086784341015611b82565b61087461075f8534611bce565b33835260209360078552828420600181015415908115610b21575b5015610adf576108a26108a89134611c30565b43611ad4565b908251916108b583611705565b3383528583019081528154855260068652600184862091818060a01b03809551166bffffffffffffffffffffffff60a01b8454161783555191015580548351906108fe82611705565b8152600186820142815233875260078852858720925183555191015580549460018601808711610a7657825585855260068152600184862001549584519681337f4614f8a9907ae69d017525a0d85be89c0321d65d51f2e88e42a5caed59c3a0a38980a4337f939a71706a68cf386c2bf838a39a42d40513dc244377b286608cea04c7ed3ae18780a382855460101c1695634ce46aab60e11b808252828285818b5afa918215610ab6578792610ac0575b5061ffff8092166109be578680f35b8551908152828185818b5afa908115610ab6578791610a89575b501695863402963488041434151715610a765781612710879897969704918751948580926361d027b360e01b82525afa8015610a6c578594859485948593610a4d575b505083918315610a43575b1690f115610a3957808080808086958680f35b51903d90823e3d90fd5b6108fc9250610a26565b610a64929350803d1061056e576105608183611737565b903880610a1b565b86513d87823e3d90fd5b634e487b7160e01b865260118352602486fd5b610aa99150833d8511610aaf575b610aa18183611737565b810190611c3a565b386109d8565b503d610a97565b86513d89823e3d90fd5b610ad8919250833d8511610aaf57610aa18183611737565b90386109af565b5083606492519162461bcd60e51b8352820152601a60248201527f4d757365756d3a20616c726561647920737562736372696265640000000000006044820152fd5b5485525060068552828420546001600160a01b03163314153861088f565b508290346101b757602092836003193601126101705767ffffffffffffffff8235818111610d6d57610b749036908501611775565b9033855260088652610b8b60ff84872054166119f9565b815115610d3357610b9a6117f6565b938251918211610d205750600190610bb282546117bc565b601f8111610cce575b5086601f8211600114610c3e579181610c2d94928899947fde2e313cac65b91f714c12b8f3e9da81fb6d46d2eeb0ecda986a4356a554cff89991610c33575b50600019600383901b1c191690821b1790555b610c2084519585879687528601906118a2565b91848303908501526118a2565b0390a180f35b90508301518a610bfa565b828752600080516020611c5583398151915290601f198316885b818110610cb957509284927fde2e313cac65b91f714c12b8f3e9da81fb6d46d2eeb0ecda986a4356a554cff8999a959282610c2d989610610ca0575b5050811b019055610c0d565b85015160001960f88460031b161c191690558a80610c94565b86830151845592850192918a01918a01610c58565b828752600080516020611c55833981519152601f830160051c810191898410610d16575b601f0160051c019083905b828110610d0b575050610bbb565b888155018390610cfd565b9091508190610cf2565b634e487b7160e01b865260419052602485fd5b825162461bcd60e51b815280850187905260146024820152734d757365756d3a20696e76616c6964206e616d6560601b6044820152606490fd5b8480fd5b50346101705760a036600319011261017057610d8b6116ea565b6024356001600160a01b03818116939092918490036110df57604435838116908181036110db5767ffffffffffffffff916064358381116110d757610dd39036908601611775565b9189549660ff8860081c1615968780986110ca575b80156110b3575b1561105957908b9392916001998960ff19968c888416179055611048575b501691610e1b831515611901565b610e268a151561194d565b15611005578a5490610e4660ff8360081c16610e4181611999565b611999565b62010000600160b01b031990911660109190911b62010000600160b01b0316178a55895260086020908152888a208054831688179055968952600987528789208054909116861790558051918211610ff25790849291610ea684546117bc565b601f8111610f99575b508690601f8311600114610f2b5789919083610f20575b5050600019600383901b1c191690831b1782555b60843560025555610ee9578380f35b7f7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb38474024989261ff0019855416855551908152a13880808380f35b015190503880610ec6565b848a52600080516020611c558339815191529190601f1984168b5b8a828210610f835750509084879594939210610f6a575b505050811b018255610eda565b015160001960f88460031b161c19169055388080610f5d565b8385015186558a98909501949384019301610f46565b909192938952600080516020611c55833981519152601f840160051c810191888510610fe8575b90601f8896959493920160051c01905b818110610fdd5750610eaf565b8a8155879501610fd0565b9091508190610fc0565b634e487b7160e01b885260418352602488fd5b895162461bcd60e51b8152602081880152601e60248201527f4d757365756d3a20696e76616c696420636f6e666967206164647265737300006044820152606490fd5b61ffff1916610101178d5538610e0d565b8a5162461bcd60e51b8152602081890152602e60248201527f496e697469616c697a61626c653a20636f6e747261637420697320616c72656160448201526d191e481a5b9a5d1a585b1a5e995960921b6064820152608490fd5b50303b158015610def5750600160ff8a1614610def565b50600160ff8a1610610de8565b8980fd5b8780fd5b8580fd5b5050346101b757816003193601126101b7579054905160109190911c6001600160a01b03168152602090f35b50903461017057602091826003193601126108455761112c6116ea565b338086526007855283862054865260068552838620546001600160a01b039391908416036111ba5750600190338652600785526007848720549385519461117286611705565b8552868501924284521695868852528386209251835551910155338352822054907f939a71706a68cf386c2bf838a39a42d40513dc244377b286608cea04c7ed3ae18380a380f35b835162461bcd60e51b8152908101859052603460248201527f4d757365756d3a206f6e6c7920737562736372697074696f6e206f776e65722060448201527331b0b71033b930b73a103b34b9b4ba30ba34b7b760611b6064820152608490fd5b50346101705781600319360112610170576112336116ea565b9161123c6118e2565b92338552600860205261125460ff83872054166119f9565b6001600160a01b031692611269841515611901565b838552600860205260ff82862054169281151580941515146112d25750916020916112ca7fae0a768e1f5a7943e3f1bb8a4d503c6fbfea4c9bbbded6b463e48bebd28ef72594868852600885528288209060ff801983541691151516179055565b51908152a280f35b606490602084519162461bcd60e51b8352820152601960248201527f4d757365756d3a2073616d652061646d696e20737461747573000000000000006044820152fd5b5050346101b75760203660031901126101b75760209181906001600160a01b0361133d6116ea565b1681526007845220549051908152f35b5050346101b75760203660031901126101b75760209160ff9082906001600160a01b036113786116ea565b1681526008855220541690519015158152f35b503461017057826003193601126101705760209250549051908152f35b50346101705781600319360112610170576113c16116ea565b916113ca6118e2565b9233855260086020526113e260ff83872054166119f9565b6001600160a01b0316926113f784151561194d565b838552600960205260ff82862054169281151580941515146114585750916020916112ca7f6b8c72479a43774feae4b90316dc470d066706bf99b8925bdaa0993b03903fa694868852600985528288209060ff801983541691151516179055565b606490602084519162461bcd60e51b8352820152601b60248201527f4d757365756d3a2073616d652063757261746f722073746174757300000000006044820152fd5b82843461158157602091826003193601126101b7576114b86116ea565b918092600254158015611564575b8015611547575b61153e575b6001600160a01b031681526007845281812082519091839186906114f581611705565b60018554958683520154918291015215159283611526575b50505061151d575b519015158152f35b60019150611515565b6001935081526006865220015443111581858061150d565b600193506114d2565b506001600160a01b0381168252600985528282205460ff166114cd565b506001600160a01b0381168252600885528282205460ff166114c6565b80fd5b5050346101b757816003193601126101b7576115b5906115a26117f6565b90519182916020835260208301906118a2565b0390f35b509034610170576020918260031936011261084557803567ffffffffffffffff8111610d6d57936115f161071b949536908401611775565b913382526008865261160860ff85842054166119f9565b6103bb611613611a3a565b85519687916116408a8401976318da16cb60e31b895230602486015260c0604486015260e48501906118a2565b60126064850152600160848501528381036023190160a4850152906118a2565b5034610170576020366003190112610170573590338352600860205261168b60ff82852054166119f9565b8183526005602052808320546116ab906001600160a01b03161515611a7d565b8183526005602052822080546001600160a01b03191690557fd745c701dcd5fb8a6f0e7ab698b6ddc5df0667b93e608eb80b72021148b9d1eb8280a280f35b600435906001600160a01b038216820361170057565b600080fd5b6040810190811067ffffffffffffffff82111761172157604052565b634e487b7160e01b600052604160045260246000fd5b90601f8019910116810190811067ffffffffffffffff82111761172157604052565b67ffffffffffffffff811161172157601f01601f191660200190565b81601f820112156117005780359061178c82611759565b9261179a6040519485611737565b8284526020838301011161170057816000926020809301838601378301015290565b90600182811c921680156117ec575b60208310146117d657565b634e487b7160e01b600052602260045260246000fd5b91607f16916117cb565b6040519060008260019182549261180c846117bc565b9081845260209481811690816000146118825750600114611838575b505061183692500383611737565b565b6000818152600080516020611c5583398151915295935091905b81831061186a57505061183693508201013880611828565b85548884018501529485019487945091830191611852565b91505061183694925060ff191682840152151560051b8201013880611828565b919082519283825260005b8481106118ce575050826000602080949584010152601f8019910116010190565b6020818301810151848301820152016118ad565b60243590811515820361170057565b6024359060ff8216820361170057565b1561190857565b60405162461bcd60e51b815260206004820152601d60248201527f4d757365756d3a20696e76616c69642061646d696e20616464726573730000006044820152606490fd5b1561195457565b60405162461bcd60e51b815260206004820152601f60248201527f4d757365756d3a20696e76616c69642063757261746f722061646472657373006044820152606490fd5b156119a057565b60405162461bcd60e51b815260206004820152602b60248201527f496e697469616c697a61626c653a20636f6e7472616374206973206e6f74206960448201526a6e697469616c697a696e6760a81b6064820152608490fd5b15611a0057565b60405162461bcd60e51b815260206004820152601260248201527126bab9b2bab69d1037b7363c9030b236b4b760711b6044820152606490fd5b60405190611a4782611705565b600882526728696e743235362960c01b6020830152565b9081602091031261170057516001600160a01b03811681036117005790565b15611a8457565b60405162461bcd60e51b815260206004820152602260248201527f4d757365756d3a20696e76616c696420636f6c6c656374696f6e206164647265604482015261737360f01b6064820152608490fd5b91908201809211611ae157565b634e487b7160e01b600052601160045260246000fd5b6001600160a01b031690611b0c821515611a7d565b600354916000838152600560205260408120826bffffffffffffffffffffffff60a01b82541617905560035460018101809111611b6e5784917f50fe088fb7bafa8b968b3058d9ee4a35001d6cbdf58defdfc4a428baa7a17a619160035580a3565b634e487b7160e01b82526011600452602482fd5b15611b8957565b60405162461bcd60e51b815260206004820152601860248201527f4d757365756d3a20696e73756666696369656e742066656500000000000000006044820152606490fd5b8115611bd8570690565b634e487b7160e01b600052601260045260246000fd5b15611bf557565b60405162461bcd60e51b81526020600482015260136024820152724d757365756d3a20696e76616c69642066656560681b6044820152606490fd5b8115611bd8570490565b90816020910312611700575161ffff81168103611700579056feb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6a2646970667358221220646a3b0be22309e496956ce00e742d56184651e7e7220e5d11429b277722743764736f6c63430008150033000000000000000000000000000000";
        // debug::print(&utf8(b"call c3 2"));
        // call(&user, sender, c3_addr, c3_call_code_2, 0);
        //
        // let c3_call_code_3 = x"cdcb760aaddc1d1ba24827ccfd9cf4ce45b45d438f55f4cc171238166b9785118ff974e30000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000109660803461020157601f61101638819003918201601f191683019291906001600160401b038411838510176102065781608092849260409687528339810103126102015780519061ffff82168092036102015761005d6020820161021c565b610074606061006d86850161021c565b930161021c565b916001600160a01b0390828216156101b3578116928315610163571692831561010f576000549162010000600160b01b039060101b169160018060b01b031916171760005560018060a01b031990816001541617600155600254161760025533638b78c6d819553360007f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e08180a351610de590816102318239f35b845162461bcd60e51b815260206004820152602760248201527f536869627579613a20696e76616c696420636f6c6c656374696f6e496d706c206044820152666164647265737360c81b6064820152608490fd5b855162461bcd60e51b815260206004820152602360248201527f536869627579613a20696e76616c6964206d757365756d496d706c206164647260448201526265737360e81b6064820152608490fd5b855162461bcd60e51b815260206004820152602160248201527f536869627579613a20696e76616c6964207472656173757279206164647265736044820152607360f81b6064820152608490fd5b600080fd5b634e487b7160e01b600052604160045260246000fd5b51906001600160a01b03821682036102015756fe608060408181526004918236101561001657600080fd5b600092833560e01c9182630294762b14610a375750816325692962146109ec5781632fa64b9c1461097f5781633166ef01146109565781633d20db161461092d57816340c618b4146108695781634d454772146107ba57816354d1f13d1461077457816361d027b314610748578163686ff55114610680578163698fa4841461062d578163715018a6146105e75781637f51bb1f146105145781638da5cb5b146104e75781638f06af1d146104c857816399c8d556146104a7578163c86f186c14610224578163f04e283e146101a4578163f2fde38b14610137575063fee81cf41461010157600080fd5b346101335760203660031901126101335760209161011d610a63565b9063389a75e1600c525281600c20549051908152f35b5080fd5b839060203660031901126101335761014d610a63565b90610156610b19565b8160601b15610199575060018060a01b0316638b78c6d8198181547f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e08580a35580f35b637448fbae8352601cfd5b83906020366003190112610133576101ba610a63565b906101c3610b19565b63389a75e1600c528183526020600c209081544211610219575082905560018060a01b0316638b78c6d8198181547f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e08580a35580f35b636f5e88188452601cfd5b919050346104a357602092836003193601126104a057823567ffffffffffffffff8111610133576102589036908501610ad2565b9282519385850190637e19275f60e01b825233602487015233604487015230606487015260a0608487015280518060c48801526102bf60e4888a8501936102a28184840187610b36565b8860a4830152601f801991011681010360c481018a520188610a7e565b6103016068875180936102eb8c8301963360601b88523060601b60348501525180926048850190610b36565b8101886048820152036048810184520182610a7e565b519020600154608881901c62ffffff16763d602d80600a3d3981f3363d3d373d3d3d363d7300000017855260781b6effffffffffffffffffffffffffffff19166e5af43d82803e903d91602b57fd5bf31787526037600985f56001600160a01b0381169590919086156104635751849283929083905af13d1561045e573d61038881610ab6565b9061039586519283610a7e565b815283873d92013e5b1561040f5760038054835281865283832080546001600160a01b031916861790555460018101919082106103fc575083917f0ecdb52f586bd4d76cb2225a7e79bdefa3cb5f1975557ba8356bc22baa371a8f9160035580a251908152f35b634e487b7160e01b835260119052602482fd5b825162461bcd60e51b81529081018590526024808201527f536869627579613a206661696c656420746f20696e697469616c697a65206d756044820152637365756d60e01b6064820152608490fd5b61039e565b855162461bcd60e51b81528085018990526017602482015276115490cc4c4d8dce8818dc99585d194c8819985a5b1959604a1b6044820152606490fd5b80fd5b8280fd5b50503461013357816003193601126101335761ffff60209254169051908152f35b5050346101335781600319360112610133576020906003549051908152f35b505034610133578160031936011261013357638b78c6d8195490516001600160a01b039091168152602090f35b9050346104a35760203660031901126104a35761052f610a63565b610537610b19565b6001600160a01b0381811693909290841561059a575050835462010000600160b01b03198116601092831b62010000600160b01b0316178555901c167fd101a15f9e9364a1c0a7c4cc8eb4cd9220094e83353915b0c74e09f72ec73edb8380a380f35b906020608492519162461bcd60e51b8352820152602160248201527f536869627579613a20696e76616c6964207472656173757279206164647265736044820152607360f81b6064820152fd5b83806003193601126104a0576105fb610b19565b80638b78c6d8198181547f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e08280a35580f35b8284346104a057816003193601126104a05782359067ffffffffffffffff82116104a0575061066460209361066f92369101610ad2565b602435903333610b59565b90516001600160a01b039091168152f35b9050346104a35760203660031901126104a35761069b610a63565b906106a4610b19565b6001600160a01b039182169283156106f5575050600254826001600160601b0360a01b821617600255167f2dc58fb34d2935b3eec15ab10d1526f16b95678b200b6280e165b74dd9814c018380a380f35b906020608492519162461bcd60e51b8352820152602760248201527f536869627579613a20696e76616c696420636f6c6c656374696f6e496d706c206044820152666164647265737360c81b6064820152fd5b5050346101335781600319360112610133579054905160109190911c6001600160a01b03168152602090f35b83806003193601126104a05763389a75e1600c52338152806020600c2055337ffa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c928280a280f35b8383346101335760203660031901126101335782359261ffff93848116809103610865576107e6610b19565b83549485169182821461082e5750807f14df4da0210168c899c94e75bb5fc62cbed8e5e0a9222920b796d99497b0d8a2949561ffff191617855582519182526020820152a180f35b606490602085519162461bcd60e51b835282015260116024820152700a6d0d2c4eaf2c27440e6c2daca40e8c2f607b1b6044820152fd5b8380fd5b9050346104a35760203660031901126104a357610884610a63565b9061088d610b19565b6001600160a01b039182169283156108de575050600154826001600160601b0360a01b821617600155167f72aa2f74b738795a5dc3d5fc2b0d0baee224ba4c95eed0eb3a4a466182de0a8e8380a380f35b906020608492519162461bcd60e51b8352820152602360248201527f536869627579613a20696e76616c6964206d757365756d496d706c206164647260448201526265737360e81b6064820152fd5b50503461013357816003193601126101335760015490516001600160a01b039091168152602090f35b50503461013357816003193601126101335760025490516001600160a01b039091168152602090f35b8284346104a05760803660031901126104a05761099a610a63565b926001600160a01b0391602435919083831683036104a0576044359067ffffffffffffffff82116104a05750916109da602096926109e494369101610ad2565b9060643592610b59565b915191168152f35b83806003193601126104a05763389a75e1600c523381526202a30042016020600c2055337fdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d8280a280f35b848434610133576020366003190112610133578335825260209384529020546001600160a01b03168152f35b600435906001600160a01b0382168203610a7957565b600080fd5b90601f8019910116810190811067ffffffffffffffff821117610aa057604052565b634e487b7160e01b600052604160045260246000fd5b67ffffffffffffffff8111610aa057601f01601f191660200190565b81601f82011215610a7957803590610ae982610ab6565b92610af76040519485610a7e565b82845260208383010111610a7957816000926020809301838601378301015290565b638b78c6d819543303610b2857565b6382b429006000526004601cfd5b60005b838110610b495750506000910152565b8181015183820152602001610b39565b91939260409081519560209182880195637e19275f60e01b875260018060a01b03958680921660248b015216604489015230606489015260a06084890152610c17606883518060c48c0152610bd960e48c88880193610bbb8184840187610b36565b8760a4830152601f80199101168101038d60c482019052018c610a7e565b8651938491610c01888401973360601b89523060601b60348601525180926048860190610b36565b8201906048820152036048810184520182610a7e565b51902092600154936e5af43d82803e903d91602b57fd5bf3600095763d602d80600a3d3981f3363d3d373d3d3d363d7300000062ffffff8260881c161787526effffffffffffffffffffffffffffff199060781b161783526037600986f5908116948515610d7157818592918380939a51925af13d15610d6c573d610c9b81610ab6565b90610ca885519283610a7e565b815284833d92013e5b15610d1e576004906003548452528120826001600160601b0360a01b82541617905560035460018101809111610d0a576003557f0ecdb52f586bd4d76cb2225a7e79bdefa3cb5f1975557ba8356bc22baa371a8f9080a2565b634e487b7160e01b82526011600452602482fd5b608491519062461bcd60e51b825260048201526024808201527f536869627579613a206661696c656420746f20696e697469616c697a65206d756044820152637365756d60e01b6064820152fd5b610cb1565b835162461bcd60e51b8152600481018490526017602482015276115490cc4c4d8dce8818dc99585d194c8819985a5b1959604a1b6044820152606490fdfea2646970667358221220b885aae008da8144785a5a210b554745b9f82979d5de2ce1bea18be6084451a864736f6c6343000815003300000000000000000000000000000000000000000000000000000000000001f400000000000000000000000023e810e8184b125c9bcf0081aa3a9bb9ae891ae1000000000000000000000000ec0481a1f0f45cf19ae116a46ce8736936090f1400000000000000000000000023e810e8184b125c9bcf0081aa3a9bb9ae891ae100000000000000000000";
        // debug::print(&utf8(b"call c3 3"));
        // call(&user, sender, c3_addr, c3_call_code_3, 0);
        //
        // let a = x"000000000000000000000000f7075e47b207bc6a3291d36409d8bad81b6aec70";
        // let c3_call_code_4 = x"c86f186c000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000224f726967616d69205072696d61727920417272616e67656d656e74204d757365756d000000000000000000000000000000000000000000000000000000000000";
        // debug::print(&utf8(b"call 4"));
        // call(&user, sender, a, c3_call_code_4, 0);
        // //
        //
        // // debug::print(&borrow_global<S>(@demo).contracts);
        // let b = x"0000000000000000000000004bb77546574f42fb967172b78c02e7dbe22e877c";
        // let c3_call_code_5 = x"ca0f9c6300000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000074254432d55534400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000828696e7432353629000000000000000000000000000000000000000000000000";
        // debug::print(&utf8(b"call 5"));
        // call(&user, sender, b, c3_call_code_5, 0);
    }


    #[test(admin = @demo)]
    fun testUniswap() acquires S {
        let sender = to_32bit(x"892a2b7cF919760e148A0d33C1eb0f44D3b383f8");
        // createAccount(sender, false);
        let aptos = account::create_account_for_test(@0x1);
        // let evm = account::create_account_for_test(@demo);
        let user = account::create_account_for_test(@signer);
        set_time_has_started_for_testing(&aptos);
        block::initialize_for_test(&aptos, 500000000);
        init_module(&user);
        evmstorage::init_module_for_test(&user);

        //USDC
        let init_code = x"60806040526005805460ff191660121790553480156200001d575f80fd5b5060405162000c6a38038062000c6a83398101604081905262000040916200013e565b8282600362000050838262000249565b5060046200005f828262000249565b50506005805460ff191660ff93909316929092179091555062000311915050565b634e487b7160e01b5f52604160045260245ffd5b5f82601f830112620000a4575f80fd5b81516001600160401b0380821115620000c157620000c162000080565b604051601f8301601f19908116603f01168101908282118183101715620000ec57620000ec62000080565b8160405283815260209250868385880101111562000108575f80fd5b5f91505b838210156200012b57858201830151818301840152908201906200010c565b5f93810190920192909252949350505050565b5f805f6060848603121562000151575f80fd5b83516001600160401b038082111562000168575f80fd5b620001768783880162000094565b945060208601519150808211156200018c575f80fd5b506200019b8682870162000094565b925050604084015160ff81168114620001b2575f80fd5b809150509250925092565b600181811c90821680620001d257607f821691505b602082108103620001f157634e487b7160e01b5f52602260045260245ffd5b50919050565b601f82111562000244575f81815260208120601f850160051c810160208610156200021f5750805b601f850160051c820191505b8181101562000240578281556001016200022b565b5050505b505050565b81516001600160401b0381111562000265576200026562000080565b6200027d81620002768454620001bd565b84620001f7565b602080601f831160018114620002b3575f84156200029b5750858301515b5f19600386901b1c1916600185901b17855562000240565b5f85815260208120601f198616915b82811015620002e357888601518255948401946001909101908401620002c2565b50858210156200030157878501515f19600388901b60f8161c191681555b5050505050600190811b01905550565b61094b806200031f5f395ff3fe608060405234801561000f575f80fd5b50600436106100cb575f3560e01c806340c10f1911610088578063a457c2d711610063578063a457c2d7146101a6578063a9059cbb146101b9578063ace28fa5146101cc578063dd62ed3e146101d9575f80fd5b806340c10f191461016157806370a082311461017657806395d89b411461019e575f80fd5b806306fdde03146100cf578063095ea7b3146100ed57806318160ddd1461011057806323b872dd14610122578063313ce56714610135578063395093511461014e575b5f80fd5b6100d76101ec565b6040516100e491906107a6565b60405180910390f35b6101006100fb36600461080c565b61027c565b60405190151581526020016100e4565b6002545b6040519081526020016100e4565b610100610130366004610834565b610295565b60055460ff165b60405160ff90911681526020016100e4565b61010061015c36600461080c565b6102b8565b61017461016f36600461080c565b6102d9565b005b61011461018436600461086d565b6001600160a01b03165f9081526020819052604090205490565b6100d76102e7565b6101006101b436600461080c565b6102f6565b6101006101c736600461080c565b610375565b60055461013c9060ff1681565b6101146101e736600461088d565b610382565b6060600380546101fb906108be565b80601f0160208091040260200160405190810160405280929190818152602001828054610227906108be565b80156102725780601f1061024957610100808354040283529160200191610272565b820191905f5260205f20905b81548152906001019060200180831161025557829003601f168201915b5050505050905090565b5f336102898185856103ac565b60019150505b92915050565b5f336102a28582856104cf565b6102ad858585610547565b506001949350505050565b5f336102898185856102ca8383610382565b6102d491906108f6565b6103ac565b6102e382826106e9565b5050565b6060600480546101fb906108be565b5f33816103038286610382565b9050838110156103685760405162461bcd60e51b815260206004820152602560248201527f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f77604482015264207a65726f60d81b60648201526084015b60405180910390fd5b6102ad82868684036103ac565b5f33610289818585610547565b6001600160a01b039182165f90815260016020908152604080832093909416825291909152205490565b6001600160a01b03831661040e5760405162461bcd60e51b8152602060048201526024808201527f45524332303a20617070726f76652066726f6d20746865207a65726f206164646044820152637265737360e01b606482015260840161035f565b6001600160a01b03821661046f5760405162461bcd60e51b815260206004820152602260248201527f45524332303a20617070726f766520746f20746865207a65726f206164647265604482015261737360f01b606482015260840161035f565b6001600160a01b038381165f8181526001602090815260408083209487168084529482529182902085905590518481527f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925910160405180910390a3505050565b5f6104da8484610382565b90505f19811461054157818110156105345760405162461bcd60e51b815260206004820152601d60248201527f45524332303a20696e73756666696369656e7420616c6c6f77616e6365000000604482015260640161035f565b61054184848484036103ac565b50505050565b6001600160a01b0383166105ab5760405162461bcd60e51b815260206004820152602560248201527f45524332303a207472616e736665722066726f6d20746865207a65726f206164604482015264647265737360d81b606482015260840161035f565b6001600160a01b03821661060d5760405162461bcd60e51b815260206004820152602360248201527f45524332303a207472616e7366657220746f20746865207a65726f206164647260448201526265737360e81b606482015260840161035f565b6001600160a01b0383165f90815260208190526040902054818110156106845760405162461bcd60e51b815260206004820152602660248201527f45524332303a207472616e7366657220616d6f756e7420657863656564732062604482015265616c616e636560d01b606482015260840161035f565b6001600160a01b038481165f81815260208181526040808320878703905593871680835291849020805487019055925185815290927fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef910160405180910390a3610541565b6001600160a01b03821661073f5760405162461bcd60e51b815260206004820152601f60248201527f45524332303a206d696e7420746f20746865207a65726f206164647265737300604482015260640161035f565b8060025f82825461075091906108f6565b90915550506001600160a01b0382165f81815260208181526040808320805486019055518481527fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef910160405180910390a35050565b5f6020808352835180828501525f5b818110156107d1578581018301518582016040015282016107b5565b505f604082860101526040601f19601f8301168501019250505092915050565b80356001600160a01b0381168114610807575f80fd5b919050565b5f806040838503121561081d575f80fd5b610826836107f1565b946020939093013593505050565b5f805f60608486031215610846575f80fd5b61084f846107f1565b925061085d602085016107f1565b9150604084013590509250925092565b5f6020828403121561087d575f80fd5b610886826107f1565b9392505050565b5f806040838503121561089e575f80fd5b6108a7836107f1565b91506108b5602084016107f1565b90509250929050565b600181811c908216806108d257607f821691505b6020821081036108f057634e487b7160e01b5f52602260045260245ffd5b50919050565b8082018082111561028f57634e487b7160e01b5f52601160045260245ffdfea2646970667358221220a6d822ba29fb8310dc1aa94585bb37b546b3f28c10c4154952d71f49fb0d992264736f6c63430008150033000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000004555344430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045553444300000000000000000000000000000000000000000000000000000000";
        let usdc_addr = create(sender, 0, init_code, 0);
        debug::print(&utf8(b"create usdc"));
        debug::print(&usdc_addr);
        //
        //USDT
        let init_code = x"60806040526005805460ff191660121790553480156200001d575f80fd5b5060405162000c6a38038062000c6a83398101604081905262000040916200013e565b8282600362000050838262000249565b5060046200005f828262000249565b50506005805460ff191660ff93909316929092179091555062000311915050565b634e487b7160e01b5f52604160045260245ffd5b5f82601f830112620000a4575f80fd5b81516001600160401b0380821115620000c157620000c162000080565b604051601f8301601f19908116603f01168101908282118183101715620000ec57620000ec62000080565b8160405283815260209250868385880101111562000108575f80fd5b5f91505b838210156200012b57858201830151818301840152908201906200010c565b5f93810190920192909252949350505050565b5f805f6060848603121562000151575f80fd5b83516001600160401b038082111562000168575f80fd5b620001768783880162000094565b945060208601519150808211156200018c575f80fd5b506200019b8682870162000094565b925050604084015160ff81168114620001b2575f80fd5b809150509250925092565b600181811c90821680620001d257607f821691505b602082108103620001f157634e487b7160e01b5f52602260045260245ffd5b50919050565b601f82111562000244575f81815260208120601f850160051c810160208610156200021f5750805b601f850160051c820191505b8181101562000240578281556001016200022b565b5050505b505050565b81516001600160401b0381111562000265576200026562000080565b6200027d81620002768454620001bd565b84620001f7565b602080601f831160018114620002b3575f84156200029b5750858301515b5f19600386901b1c1916600185901b17855562000240565b5f85815260208120601f198616915b82811015620002e357888601518255948401946001909101908401620002c2565b50858210156200030157878501515f19600388901b60f8161c191681555b5050505050600190811b01905550565b61094b806200031f5f395ff3fe608060405234801561000f575f80fd5b50600436106100cb575f3560e01c806340c10f1911610088578063a457c2d711610063578063a457c2d7146101a6578063a9059cbb146101b9578063ace28fa5146101cc578063dd62ed3e146101d9575f80fd5b806340c10f191461016157806370a082311461017657806395d89b411461019e575f80fd5b806306fdde03146100cf578063095ea7b3146100ed57806318160ddd1461011057806323b872dd14610122578063313ce56714610135578063395093511461014e575b5f80fd5b6100d76101ec565b6040516100e491906107a6565b60405180910390f35b6101006100fb36600461080c565b61027c565b60405190151581526020016100e4565b6002545b6040519081526020016100e4565b610100610130366004610834565b610295565b60055460ff165b60405160ff90911681526020016100e4565b61010061015c36600461080c565b6102b8565b61017461016f36600461080c565b6102d9565b005b61011461018436600461086d565b6001600160a01b03165f9081526020819052604090205490565b6100d76102e7565b6101006101b436600461080c565b6102f6565b6101006101c736600461080c565b610375565b60055461013c9060ff1681565b6101146101e736600461088d565b610382565b6060600380546101fb906108be565b80601f0160208091040260200160405190810160405280929190818152602001828054610227906108be565b80156102725780601f1061024957610100808354040283529160200191610272565b820191905f5260205f20905b81548152906001019060200180831161025557829003601f168201915b5050505050905090565b5f336102898185856103ac565b60019150505b92915050565b5f336102a28582856104cf565b6102ad858585610547565b506001949350505050565b5f336102898185856102ca8383610382565b6102d491906108f6565b6103ac565b6102e382826106e9565b5050565b6060600480546101fb906108be565b5f33816103038286610382565b9050838110156103685760405162461bcd60e51b815260206004820152602560248201527f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f77604482015264207a65726f60d81b60648201526084015b60405180910390fd5b6102ad82868684036103ac565b5f33610289818585610547565b6001600160a01b039182165f90815260016020908152604080832093909416825291909152205490565b6001600160a01b03831661040e5760405162461bcd60e51b8152602060048201526024808201527f45524332303a20617070726f76652066726f6d20746865207a65726f206164646044820152637265737360e01b606482015260840161035f565b6001600160a01b03821661046f5760405162461bcd60e51b815260206004820152602260248201527f45524332303a20617070726f766520746f20746865207a65726f206164647265604482015261737360f01b606482015260840161035f565b6001600160a01b038381165f8181526001602090815260408083209487168084529482529182902085905590518481527f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925910160405180910390a3505050565b5f6104da8484610382565b90505f19811461054157818110156105345760405162461bcd60e51b815260206004820152601d60248201527f45524332303a20696e73756666696369656e7420616c6c6f77616e6365000000604482015260640161035f565b61054184848484036103ac565b50505050565b6001600160a01b0383166105ab5760405162461bcd60e51b815260206004820152602560248201527f45524332303a207472616e736665722066726f6d20746865207a65726f206164604482015264647265737360d81b606482015260840161035f565b6001600160a01b03821661060d5760405162461bcd60e51b815260206004820152602360248201527f45524332303a207472616e7366657220746f20746865207a65726f206164647260448201526265737360e81b606482015260840161035f565b6001600160a01b0383165f90815260208190526040902054818110156106845760405162461bcd60e51b815260206004820152602660248201527f45524332303a207472616e7366657220616d6f756e7420657863656564732062604482015265616c616e636560d01b606482015260840161035f565b6001600160a01b038481165f81815260208181526040808320878703905593871680835291849020805487019055925185815290927fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef910160405180910390a3610541565b6001600160a01b03821661073f5760405162461bcd60e51b815260206004820152601f60248201527f45524332303a206d696e7420746f20746865207a65726f206164647265737300604482015260640161035f565b8060025f82825461075091906108f6565b90915550506001600160a01b0382165f81815260208181526040808320805486019055518481527fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef910160405180910390a35050565b5f6020808352835180828501525f5b818110156107d1578581018301518582016040015282016107b5565b505f604082860101526040601f19601f8301168501019250505092915050565b80356001600160a01b0381168114610807575f80fd5b919050565b5f806040838503121561081d575f80fd5b610826836107f1565b946020939093013593505050565b5f805f60608486031215610846575f80fd5b61084f846107f1565b925061085d602085016107f1565b9150604084013590509250925092565b5f6020828403121561087d575f80fd5b610886826107f1565b9392505050565b5f806040838503121561089e575f80fd5b6108a7836107f1565b91506108b5602084016107f1565b90509250929050565b600181811c908216806108d257607f821691505b6020821081036108f057634e487b7160e01b5f52602260045260245ffd5b50919050565b8082018082111561028f57634e487b7160e01b5f52601160045260245ffdfea2646970667358221220a6d822ba29fb8310dc1aa94585bb37b546b3f28c10c4154952d71f49fb0d992264736f6c63430008150033000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000004555344540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045553445400000000000000000000000000000000000000000000000000000000";
        let usdt_addr = create(sender, 1, init_code, 0);
        debug::print(&utf8(b"create usdt"));
        debug::print(&usdt_addr);

        //WETH9
        let init_code = x"60c0604052600d60808190526c2bb930b83832b21022ba3432b960991b60a090815261002e916000919061007a565b50604080518082019091526004808252630ae8aa8960e31b602090920191825261005a9160019161007a565b506002805460ff1916601217905534801561007457600080fd5b50610115565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106100bb57805160ff19168380011785556100e8565b828001600101855582156100e8579182015b828111156100e85782518255916020019190600101906100cd565b506100f49291506100f8565b5090565b61011291905b808211156100f457600081556001016100fe565b90565b61074f806101246000396000f3fe60806040526004361061009c5760003560e01c8063313ce56711610064578063313ce5671461020e57806370a082311461023957806395d89b411461026c578063a9059cbb14610281578063d0e30db0146102ba578063dd62ed3e146102c25761009c565b806306fdde03146100a1578063095ea7b31461012b57806318160ddd1461017857806323b872dd1461019f5780632e1a7d4d146101e2575b600080fd5b3480156100ad57600080fd5b506100b66102fd565b6040805160208082528351818301528351919283929083019185019080838360005b838110156100f05781810151838201526020016100d8565b50505050905090810190601f16801561011d5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34801561013757600080fd5b506101646004803603604081101561014e57600080fd5b506001600160a01b03813516906020013561038b565b604080519115158252519081900360200190f35b34801561018457600080fd5b5061018d6103f1565b60408051918252519081900360200190f35b3480156101ab57600080fd5b50610164600480360360608110156101c257600080fd5b506001600160a01b038135811691602081013590911690604001356103f5565b3480156101ee57600080fd5b5061020c6004803603602081101561020557600080fd5b503561056d565b005b34801561021a57600080fd5b50610223610624565b6040805160ff9092168252519081900360200190f35b34801561024557600080fd5b5061018d6004803603602081101561025c57600080fd5b50356001600160a01b031661062d565b34801561027857600080fd5b506100b661063f565b34801561028d57600080fd5b50610164600480360360408110156102a457600080fd5b506001600160a01b038135169060200135610699565b61020c6106ad565b3480156102ce57600080fd5b5061018d600480360360408110156102e557600080fd5b506001600160a01b03813581169160200135166106fc565b6000805460408051602060026001851615610100026000190190941693909304601f810184900484028201840190925281815292918301828280156103835780601f1061035857610100808354040283529160200191610383565b820191906000526020600020905b81548152906001019060200180831161036657829003601f168201915b505050505081565b3360008181526004602090815260408083206001600160a01b038716808552908352818420869055815186815291519394909390927f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925928290030190a350600192915050565b4790565b6001600160a01b03831660009081526003602052604081205482111561043c576040805162461bcd60e51b8152602060048201526000602482015290519081900360640190fd5b6001600160a01b038416331480159061047a57506001600160a01b038416600090815260046020908152604080832033845290915290205460001914155b156104fc576001600160a01b03841660009081526004602090815260408083203384529091529020548211156104d1576040805162461bcd60e51b8152602060048201526000602482015290519081900360640190fd5b6001600160a01b03841660009081526004602090815260408083203384529091529020805483900390555b6001600160a01b03808516600081815260036020908152604080832080548890039055938716808352918490208054870190558351868152935191937fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef929081900390910190a35060019392505050565b336000908152600360205260409020548111156105ab576040805162461bcd60e51b8152602060048201526000602482015290519081900360640190fd5b33600081815260036020526040808220805485900390555183156108fc0291849190818181858888f193505050501580156105ea573d6000803e3d6000fd5b5060408051828152905133917f7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b65919081900360200190a250565b60025460ff1681565b60036020526000908152604090205481565b60018054604080516020600284861615610100026000190190941693909304601f810184900484028201840190925281815292918301828280156103835780601f1061035857610100808354040283529160200191610383565b60006106a63384846103f5565b9392505050565b33600081815260036020908152604091829020805434908101909155825190815291517fe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c9281900390910190a2565b60046020908152600092835260408084209091529082529020548156fea2646970667358221220da9c3a111ff307bcc21a489b63cc555d04d91b6d0ff23237180b67a42b605beb64736f6c63430006060033";
        let weth_addr = create(sender, 2, init_code, 0);
        debug::print(&utf8(b"create weth"));
        debug::print(&weth_addr);

        let factory_code = x"608060405234801561001057600080fd5b50604051612aa9380380612aa98339818101604052602081101561003357600080fd5b5051600180546001600160a01b0319166001600160a01b03909216919091179055612a46806100636000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c8063a2e74af61161005b578063a2e74af6146100f0578063c9c6539614610118578063e6a4390514610146578063f46901ed1461017457610088565b8063017e7e581461008d578063094b7415146100b15780631e3dd18b146100b9578063574f2ba3146100d6575b600080fd5b61009561019a565b604080516001600160a01b039092168252519081900360200190f35b6100956101a9565b610095600480360360208110156100cf57600080fd5b50356101b8565b6100de6101df565b60408051918252519081900360200190f35b6101166004803603602081101561010657600080fd5b50356001600160a01b03166101e5565b005b6100956004803603604081101561012e57600080fd5b506001600160a01b038135811691602001351661025d565b6100956004803603604081101561015c57600080fd5b506001600160a01b038135811691602001351661058e565b6101166004803603602081101561018a57600080fd5b50356001600160a01b03166105b4565b6000546001600160a01b031681565b6001546001600160a01b031681565b600381815481106101c557fe5b6000918252602090912001546001600160a01b0316905081565b60035490565b6001546001600160a01b0316331461023b576040805162461bcd60e51b81526020600482015260146024820152732ab734b9bbb0b82b191d102327a92124a22222a760611b604482015290519081900360640190fd5b600180546001600160a01b0319166001600160a01b0392909216919091179055565b6000816001600160a01b0316836001600160a01b031614156102c6576040805162461bcd60e51b815260206004820152601e60248201527f556e697377617056323a204944454e544943414c5f4144445245535345530000604482015290519081900360640190fd5b600080836001600160a01b0316856001600160a01b0316106102e95783856102ec565b84845b90925090506001600160a01b03821661034c576040805162461bcd60e51b815260206004820152601760248201527f556e697377617056323a205a45524f5f41444452455353000000000000000000604482015290519081900360640190fd5b6001600160a01b038281166000908152600260209081526040808320858516845290915290205416156103bf576040805162461bcd60e51b8152602060048201526016602482015275556e697377617056323a20504149525f45584953545360501b604482015290519081900360640190fd5b6060604051806020016103d19061062c565b6020820181038252601f19601f8201166040525090506000838360405160200180836001600160a01b03166001600160a01b031660601b8152601401826001600160a01b03166001600160a01b031660601b815260140192505050604051602081830303815290604052805190602001209050808251602084016000f56040805163485cc95560e01b81526001600160a01b038781166004830152868116602483015291519297509087169163485cc9559160448082019260009290919082900301818387803b1580156104a457600080fd5b505af11580156104b8573d6000803e3d6000fd5b505050506001600160a01b0384811660008181526002602081815260408084208987168086529083528185208054978d166001600160a01b031998891681179091559383528185208686528352818520805488168517905560038054600181018255958190527fc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b90950180549097168417909655925483519283529082015281517f0d3648bd0f6ba80134a33ba9275ac585d9d315f0ad8355cddefde31afa28d0e9929181900390910190a35050505092915050565b60026020908152600092835260408084209091529082529020546001600160a01b031681565b6001546001600160a01b0316331461060a576040805162461bcd60e51b81526020600482015260146024820152732ab734b9bbb0b82b191d102327a92124a22222a760611b604482015290519081900360640190fd5b600080546001600160a01b0319166001600160a01b0392909216919091179055565b6123d88061063a8339019056fe60806040526001600c5534801561001557600080fd5b5060405146908060526123868239604080519182900360520182208282018252600a8352692ab734b9bbb0b8102b1960b11b6020938401528151808301835260018152603160f81b908401528151808401919091527fbfcc8ef98ffbf7b6c3fec7bf5185b566b9863e35a9d83acd49ad6824b5969738818301527fc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6606082015260808101949094523060a0808601919091528151808603909101815260c09094019052825192019190912060035550600580546001600160a01b03191633179055612281806101056000396000f3fe608060405234801561001057600080fd5b50600436106101a95760003560e01c80636a627842116100f9578063ba9a7a5611610097578063d21220a711610071578063d21220a714610534578063d505accf1461053c578063dd62ed3e1461058d578063fff6cae9146105bb576101a9565b8063ba9a7a56146104fe578063bc25cf7714610506578063c45a01551461052c576101a9565b80637ecebe00116100d35780637ecebe001461046557806389afcb441461048b57806395d89b41146104ca578063a9059cbb146104d2576101a9565b80636a6278421461041157806370a08231146104375780637464fc3d1461045d576101a9565b806323b872dd116101665780633644e515116101405780633644e515146103cb578063485cc955146103d35780635909c0d5146104015780635a3d549314610409576101a9565b806323b872dd1461036f57806330adf81f146103a5578063313ce567146103ad576101a9565b8063022c0d9f146101ae57806306fdde031461023c5780630902f1ac146102b9578063095ea7b3146102f15780630dfe16811461033157806318160ddd14610355575b600080fd5b61023a600480360360808110156101c457600080fd5b8135916020810135916001600160a01b0360408301351691908101906080810160608201356401000000008111156101fb57600080fd5b82018360208201111561020d57600080fd5b8035906020019184600183028401116401000000008311171561022f57600080fd5b5090925090506105c3565b005b610244610afe565b6040805160208082528351818301528351919283929083019185019080838360005b8381101561027e578181015183820152602001610266565b50505050905090810190601f1680156102ab5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b6102c1610b24565b604080516001600160701b03948516815292909316602083015263ffffffff168183015290519081900360600190f35b61031d6004803603604081101561030757600080fd5b506001600160a01b038135169060200135610b4e565b604080519115158252519081900360200190f35b610339610b65565b604080516001600160a01b039092168252519081900360200190f35b61035d610b74565b60408051918252519081900360200190f35b61031d6004803603606081101561038557600080fd5b506001600160a01b03813581169160208101359091169060400135610b7a565b61035d610c14565b6103b5610c38565b6040805160ff9092168252519081900360200190f35b61035d610c3d565b61023a600480360360408110156103e957600080fd5b506001600160a01b0381358116916020013516610c43565b61035d610cc7565b61035d610ccd565b61035d6004803603602081101561042757600080fd5b50356001600160a01b0316610cd3565b61035d6004803603602081101561044d57600080fd5b50356001600160a01b0316610fd3565b61035d610fe5565b61035d6004803603602081101561047b57600080fd5b50356001600160a01b0316610feb565b6104b1600480360360208110156104a157600080fd5b50356001600160a01b0316610ffd565b6040805192835260208301919091528051918290030190f35b6102446113a3565b61031d600480360360408110156104e857600080fd5b506001600160a01b0381351690602001356113c5565b61035d6113d2565b61023a6004803603602081101561051c57600080fd5b50356001600160a01b03166113d8565b610339611543565b610339611552565b61023a600480360360e081101561055257600080fd5b506001600160a01b03813581169160208101359091169060408101359060608101359060ff6080820135169060a08101359060c00135611561565b61035d600480360360408110156105a357600080fd5b506001600160a01b0381358116916020013516611763565b61023a611780565b600c5460011461060e576040805162461bcd60e51b8152602060048201526011602482015270155b9a5cddd85c158c8e881313d0d2d151607a1b604482015290519081900360640190fd5b6000600c55841515806106215750600084115b61065c5760405162461bcd60e51b81526004018080602001828103825260258152602001806121936025913960400191505060405180910390fd5b600080610667610b24565b5091509150816001600160701b03168710801561068c5750806001600160701b031686105b6106c75760405162461bcd60e51b81526004018080602001828103825260218152602001806121dc6021913960400191505060405180910390fd5b60065460075460009182916001600160a01b039182169190811690891682148015906107055750806001600160a01b0316896001600160a01b031614155b61074e576040805162461bcd60e51b8152602060048201526015602482015274556e697377617056323a20494e56414c49445f544f60581b604482015290519081900360640190fd5b8a1561075f5761075f828a8d6118e2565b891561077057610770818a8c6118e2565b861561082b57886001600160a01b03166310d1e85c338d8d8c8c6040518663ffffffff1660e01b815260040180866001600160a01b03166001600160a01b03168152602001858152602001848152602001806020018281038252848482818152602001925080828437600081840152601f19601f8201169050808301925050509650505050505050600060405180830381600087803b15801561081257600080fd5b505af1158015610826573d6000803e3d6000fd5b505050505b604080516370a0823160e01b815230600482015290516001600160a01b038416916370a08231916024808301926020929190829003018186803b15801561087157600080fd5b505afa158015610885573d6000803e3d6000fd5b505050506040513d602081101561089b57600080fd5b5051604080516370a0823160e01b815230600482015290519195506001600160a01b038316916370a0823191602480820192602092909190829003018186803b1580156108e757600080fd5b505afa1580156108fb573d6000803e3d6000fd5b505050506040513d602081101561091157600080fd5b5051925060009150506001600160701b0385168a90038311610934576000610943565b89856001600160701b03160383035b9050600089856001600160701b031603831161096057600061096f565b89856001600160701b03160383035b905060008211806109805750600081115b6109bb5760405162461bcd60e51b81526004018080602001828103825260248152602001806121b86024913960400191505060405180910390fd5b60006109ef6109d184600363ffffffff611a7c16565b6109e3876103e863ffffffff611a7c16565b9063ffffffff611adf16565b90506000610a076109d184600363ffffffff611a7c16565b9050610a38620f4240610a2c6001600160701b038b8116908b1663ffffffff611a7c16565b9063ffffffff611a7c16565b610a48838363ffffffff611a7c16565b1015610a8a576040805162461bcd60e51b815260206004820152600c60248201526b556e697377617056323a204b60a01b604482015290519081900360640190fd5b5050610a9884848888611b2f565b60408051838152602081018390528082018d9052606081018c905290516001600160a01b038b169133917fd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d8229181900360800190a350506001600c55505050505050505050565b6040518060400160405280600a8152602001692ab734b9bbb0b8102b1960b11b81525081565b6008546001600160701b0380821692600160701b830490911691600160e01b900463ffffffff1690565b6000610b5b338484611cf4565b5060015b92915050565b6006546001600160a01b031681565b60005481565b6001600160a01b038316600090815260026020908152604080832033845290915281205460001914610bff576001600160a01b0384166000908152600260209081526040808320338452909152902054610bda908363ffffffff611adf16565b6001600160a01b03851660009081526002602090815260408083203384529091529020555b610c0a848484611d56565b5060019392505050565b7f6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c981565b601281565b60035481565b6005546001600160a01b03163314610c99576040805162461bcd60e51b81526020600482015260146024820152732ab734b9bbb0b82b191d102327a92124a22222a760611b604482015290519081900360640190fd5b600680546001600160a01b039384166001600160a01b03199182161790915560078054929093169116179055565b60095481565b600a5481565b6000600c54600114610d20576040805162461bcd60e51b8152602060048201526011602482015270155b9a5cddd85c158c8e881313d0d2d151607a1b604482015290519081900360640190fd5b6000600c81905580610d30610b24565b50600654604080516370a0823160e01b815230600482015290519395509193506000926001600160a01b03909116916370a08231916024808301926020929190829003018186803b158015610d8457600080fd5b505afa158015610d98573d6000803e3d6000fd5b505050506040513d6020811015610dae57600080fd5b5051600754604080516370a0823160e01b815230600482015290519293506000926001600160a01b03909216916370a0823191602480820192602092909190829003018186803b158015610e0157600080fd5b505afa158015610e15573d6000803e3d6000fd5b505050506040513d6020811015610e2b57600080fd5b505190506000610e4a836001600160701b03871663ffffffff611adf16565b90506000610e67836001600160701b03871663ffffffff611adf16565b90506000610e758787611e10565b60005490915080610eb257610e9e6103e86109e3610e99878763ffffffff611a7c16565b611f6e565b9850610ead60006103e8611fc0565b610f01565b610efe6001600160701b038916610ecf868463ffffffff611a7c16565b81610ed657fe5b046001600160701b038916610ef1868563ffffffff611a7c16565b81610ef857fe5b04612056565b98505b60008911610f405760405162461bcd60e51b81526004018080602001828103825260288152602001806122256028913960400191505060405180910390fd5b610f4a8a8a611fc0565b610f5686868a8a611b2f565b8115610f8657600854610f82906001600160701b0380821691600160701b90041663ffffffff611a7c16565b600b555b6040805185815260208101859052815133927f4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f928290030190a250506001600c5550949695505050505050565b60016020526000908152604090205481565b600b5481565b60046020526000908152604090205481565b600080600c5460011461104b576040805162461bcd60e51b8152602060048201526011602482015270155b9a5cddd85c158c8e881313d0d2d151607a1b604482015290519081900360640190fd5b6000600c8190558061105b610b24565b50600654600754604080516370a0823160e01b815230600482015290519496509294506001600160a01b039182169391169160009184916370a08231916024808301926020929190829003018186803b1580156110b757600080fd5b505afa1580156110cb573d6000803e3d6000fd5b505050506040513d60208110156110e157600080fd5b5051604080516370a0823160e01b815230600482015290519192506000916001600160a01b038516916370a08231916024808301926020929190829003018186803b15801561112f57600080fd5b505afa158015611143573d6000803e3d6000fd5b505050506040513d602081101561115957600080fd5b5051306000908152600160205260408120549192506111788888611e10565b6000549091508061118f848763ffffffff611a7c16565b8161119657fe5b049a50806111aa848663ffffffff611a7c16565b816111b157fe5b04995060008b1180156111c4575060008a115b6111ff5760405162461bcd60e51b81526004018080602001828103825260288152602001806121fd6028913960400191505060405180910390fd5b611209308461206e565b611214878d8d6118e2565b61121f868d8c6118e2565b604080516370a0823160e01b815230600482015290516001600160a01b038916916370a08231916024808301926020929190829003018186803b15801561126557600080fd5b505afa158015611279573d6000803e3d6000fd5b505050506040513d602081101561128f57600080fd5b5051604080516370a0823160e01b815230600482015290519196506001600160a01b038816916370a0823191602480820192602092909190829003018186803b1580156112db57600080fd5b505afa1580156112ef573d6000803e3d6000fd5b505050506040513d602081101561130557600080fd5b5051935061131585858b8b611b2f565b811561134557600854611341906001600160701b0380821691600160701b90041663ffffffff611a7c16565b600b555b604080518c8152602081018c905281516001600160a01b038f169233927fdccd412f0b1252819cb1fd330b93224ca42612892bb3f4f789976e6d81936496929081900390910190a35050505050505050506001600c81905550915091565b604051806040016040528060068152602001652aa72496ab1960d11b81525081565b6000610b5b338484611d56565b6103e881565b600c54600114611423576040805162461bcd60e51b8152602060048201526011602482015270155b9a5cddd85c158c8e881313d0d2d151607a1b604482015290519081900360640190fd5b6000600c55600654600754600854604080516370a0823160e01b815230600482015290516001600160a01b0394851694909316926114d292859287926114cd926001600160701b03169185916370a0823191602480820192602092909190829003018186803b15801561149557600080fd5b505afa1580156114a9573d6000803e3d6000fd5b505050506040513d60208110156114bf57600080fd5b50519063ffffffff611adf16565b6118e2565b600854604080516370a0823160e01b8152306004820152905161153992849287926114cd92600160701b90046001600160701b0316916001600160a01b038616916370a0823191602480820192602092909190829003018186803b15801561149557600080fd5b50506001600c5550565b6005546001600160a01b031681565b6007546001600160a01b031681565b428410156115ab576040805162461bcd60e51b8152602060048201526012602482015271155b9a5cddd85c158c8e881156141254915160721b604482015290519081900360640190fd5b6003546001600160a01b0380891660008181526004602090815260408083208054600180820190925582517f6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c98186015280840196909652958d166060860152608085018c905260a085019590955260c08085018b90528151808603909101815260e08501825280519083012061190160f01b6101008601526101028501969096526101228085019690965280518085039096018652610142840180825286519683019690962095839052610162840180825286905260ff89166101828501526101a284018890526101c28401879052519193926101e280820193601f1981019281900390910190855afa1580156116c6573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b038116158015906116fc5750886001600160a01b0316816001600160a01b0316145b61174d576040805162461bcd60e51b815260206004820152601c60248201527f556e697377617056323a20494e56414c49445f5349474e415455524500000000604482015290519081900360640190fd5b611758898989611cf4565b505050505050505050565b600260209081526000928352604080842090915290825290205481565b600c546001146117cb576040805162461bcd60e51b8152602060048201526011602482015270155b9a5cddd85c158c8e881313d0d2d151607a1b604482015290519081900360640190fd5b6000600c55600654604080516370a0823160e01b815230600482015290516118db926001600160a01b0316916370a08231916024808301926020929190829003018186803b15801561181c57600080fd5b505afa158015611830573d6000803e3d6000fd5b505050506040513d602081101561184657600080fd5b5051600754604080516370a0823160e01b815230600482015290516001600160a01b03909216916370a0823191602480820192602092909190829003018186803b15801561189357600080fd5b505afa1580156118a7573d6000803e3d6000fd5b505050506040513d60208110156118bd57600080fd5b50516008546001600160701b0380821691600160701b900416611b2f565b6001600c55565b604080518082018252601981527f7472616e7366657228616464726573732c75696e74323536290000000000000060209182015281516001600160a01b0385811660248301526044808301869052845180840390910181526064909201845291810180516001600160e01b031663a9059cbb60e01b1781529251815160009460609489169392918291908083835b6020831061198f5780518252601f199092019160209182019101611970565b6001836020036101000a0380198251168184511680821785525050505050509050019150506000604051808303816000865af19150503d80600081146119f1576040519150601f19603f3d011682016040523d82523d6000602084013e6119f6565b606091505b5091509150818015611a24575080511580611a245750808060200190516020811015611a2157600080fd5b50515b611a75576040805162461bcd60e51b815260206004820152601a60248201527f556e697377617056323a205452414e534645525f4641494c4544000000000000604482015290519081900360640190fd5b5050505050565b6000811580611a9757505080820282828281611a9457fe5b04145b610b5f576040805162461bcd60e51b815260206004820152601460248201527364732d6d6174682d6d756c2d6f766572666c6f7760601b604482015290519081900360640190fd5b80820382811115610b5f576040805162461bcd60e51b815260206004820152601560248201527464732d6d6174682d7375622d756e646572666c6f7760581b604482015290519081900360640190fd5b6001600160701b038411801590611b4d57506001600160701b038311155b611b94576040805162461bcd60e51b8152602060048201526013602482015272556e697377617056323a204f564552464c4f5760681b604482015290519081900360640190fd5b60085463ffffffff42811691600160e01b90048116820390811615801590611bc457506001600160701b03841615155b8015611bd857506001600160701b03831615155b15611c49578063ffffffff16611c0685611bf18661210c565b6001600160e01b03169063ffffffff61211e16565b600980546001600160e01b03929092169290920201905563ffffffff8116611c3184611bf18761210c565b600a80546001600160e01b0392909216929092020190555b600880546dffffffffffffffffffffffffffff19166001600160701b03888116919091176dffffffffffffffffffffffffffff60701b1916600160701b8883168102919091176001600160e01b0316600160e01b63ffffffff871602179283905560408051848416815291909304909116602082015281517f1c411e9a96e071241c2f21f7726b17ae89e3cab4c78be50e062b03a9fffbbad1929181900390910190a1505050505050565b6001600160a01b03808416600081815260026020908152604080832094871680845294825291829020859055815185815291517f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9259281900390910190a3505050565b6001600160a01b038316600090815260016020526040902054611d7f908263ffffffff611adf16565b6001600160a01b038085166000908152600160205260408082209390935590841681522054611db4908263ffffffff61214316565b6001600160a01b0380841660008181526001602090815260409182902094909455805185815290519193928716927fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef92918290030190a3505050565b600080600560009054906101000a90046001600160a01b03166001600160a01b031663017e7e586040518163ffffffff1660e01b815260040160206040518083038186803b158015611e6157600080fd5b505afa158015611e75573d6000803e3d6000fd5b505050506040513d6020811015611e8b57600080fd5b5051600b546001600160a01b038216158015945091925090611f5a578015611f55576000611ece610e996001600160701b0388811690881663ffffffff611a7c16565b90506000611edb83611f6e565b905080821115611f52576000611f09611efa848463ffffffff611adf16565b6000549063ffffffff611a7c16565b90506000611f2e83611f2286600563ffffffff611a7c16565b9063ffffffff61214316565b90506000818381611f3b57fe5b0490508015611f4e57611f4e8782611fc0565b5050505b50505b611f66565b8015611f66576000600b555b505092915050565b60006003821115611fb1575080600160028204015b81811015611fab57809150600281828581611f9a57fe5b040181611fa357fe5b049050611f83565b50611fbb565b8115611fbb575060015b919050565b600054611fd3908263ffffffff61214316565b60009081556001600160a01b038316815260016020526040902054611ffe908263ffffffff61214316565b6001600160a01b03831660008181526001602090815260408083209490945583518581529351929391927fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9281900390910190a35050565b60008183106120655781612067565b825b9392505050565b6001600160a01b038216600090815260016020526040902054612097908263ffffffff611adf16565b6001600160a01b038316600090815260016020526040812091909155546120c4908263ffffffff611adf16565b60009081556040805183815290516001600160a01b038516917fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef919081900360200190a35050565b6001600160701b0316600160701b0290565b60006001600160701b0382166001600160e01b0384168161213b57fe5b049392505050565b80820182811015610b5f576040805162461bcd60e51b815260206004820152601460248201527364732d6d6174682d6164642d6f766572666c6f7760601b604482015290519081900360640190fdfe556e697377617056323a20494e53554646494349454e545f4f55545055545f414d4f554e54556e697377617056323a20494e53554646494349454e545f494e5055545f414d4f554e54556e697377617056323a20494e53554646494349454e545f4c4951554944495459556e697377617056323a20494e53554646494349454e545f4c49515549444954595f4255524e4544556e697377617056323a20494e53554646494349454e545f4c49515549444954595f4d494e544544a265627a7a72315820ddcc57c37b5af411a8f0477680f3c9c1d3f65881aa751b2a5e1dcb9b7abe963464736f6c63430005100032454950373132446f6d61696e28737472696e67206e616d652c737472696e672076657273696f6e2c75696e7432353620636861696e49642c6164647265737320766572696679696e67436f6e747261637429a265627a7a723158205492bb75ed46914d8f5645fbd2cb22555ee464d2419f2ab29a7bb623b124926b64736f6c63430005100032";
        vector::append(&mut factory_code, sender);
        let factory_addr = create(sender, 3, factory_code, 0);
        debug::print(&utf8(b"create factory"));
        debug::print(&factory_addr);

        // x"c9c65396" + usdc_addr + usdt_addr
        let params = vector::empty<u8>();
        vector::append(&mut params, x"c9c65396");
        vector::append(&mut params, to_32bit(usdc_addr));
        vector::append(&mut params, to_32bit(usdt_addr));
        debug::print(&params);
        debug::print(&utf8(b"create pair"));
        debug::print(&utf8(b"params"));
        call(&user, sender, factory_addr, params, 0);
        // allpair 0
        let calldata = x"1e3dd18b0000000000000000000000000000000000000000000000000000000000000000";
        debug::print(&view(x"", factory_addr, calldata));

        debug::print(&utf8(b"get pair"));
        let params = vector::empty<u8>();
        vector::append(&mut params, x"e6a43905");
        vector::append(&mut params, to_32bit(usdt_addr));
        vector::append(&mut params, to_32bit(usdc_addr));
        let pair_addr = view(x"", factory_addr, params);
        debug::print(&pair_addr);

        debug::print(&utf8(b"deploy router"));
        let router_code = x"60c060405234801561001057600080fd5b506040516200479d3803806200479d8339818101604052604081101561003557600080fd5b5080516020909101516001600160601b0319606092831b8116608052911b1660a05260805160601c60a05160601c614618620001856000398061015f5280610ce45280610d1f5280610e16528061103452806113be528061152452806118eb52806119e55280611a9b5280611b695280611caf5280611d375280611f7c5280611ff752806120a652806121725280612207528061227b528061277952806129ec5280612a425280612a765280612aea5280612c8a5280612dcd5280612e55525080610ea45280610f7b52806110fa5280611133528061126e528061144c528061150252806116725280611bfc5280611d695280611ecc52806122ad528061250652806126fe5280612727528061275752806128c45280612a205280612d1d5280612e875280613718528061375b5280613a3e5280613bbd5280613fed528061409b528061411b52506146186000f3fe60806040526004361061014f5760003560e01c80638803dbee116100b6578063c45a01551161006f578063c45a015514610a10578063d06ca61f14610a25578063ded9382a14610ada578063e8e3370014610b4d578063f305d71914610bcd578063fb3bdb4114610c1357610188565b80638803dbee146107df578063ad5c464814610875578063ad615dec146108a6578063af2979eb146108dc578063b6f9de951461092f578063baa2abde146109b357610188565b80634a25d94a116101085780634a25d94a146104f05780635b0d5984146105865780635c11d795146105f9578063791ac9471461068f5780637ff36ab51461072557806385f8c259146107a957610188565b806302751cec1461018d578063054d50d4146101f957806318cbafe5146102415780631f00ca74146103275780632195995c146103dc57806338ed17391461045a57610188565b3661018857336001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000161461018657fe5b005b600080fd5b34801561019957600080fd5b506101e0600480360360c08110156101b057600080fd5b506001600160a01b0381358116916020810135916040820135916060810135916080820135169060a00135610c97565b6040805192835260208301919091528051918290030190f35b34801561020557600080fd5b5061022f6004803603606081101561021c57600080fd5b5080359060208101359060400135610db1565b60408051918252519081900360200190f35b34801561024d57600080fd5b506102d7600480360360a081101561026457600080fd5b813591602081013591810190606081016040820135600160201b81111561028a57600080fd5b82018360208201111561029c57600080fd5b803590602001918460208302840111600160201b831117156102bd57600080fd5b91935091506001600160a01b038135169060200135610dc6565b60408051602080825283518183015283519192839290830191858101910280838360005b838110156103135781810151838201526020016102fb565b505050509050019250505060405180910390f35b34801561033357600080fd5b506102d76004803603604081101561034a57600080fd5b81359190810190604081016020820135600160201b81111561036b57600080fd5b82018360208201111561037d57600080fd5b803590602001918460208302840111600160201b8311171561039e57600080fd5b9190808060200260200160405190810160405280939291908181526020018383602002808284376000920191909152509295506110f3945050505050565b3480156103e857600080fd5b506101e0600480360361016081101561040057600080fd5b506001600160a01b038135811691602081013582169160408201359160608101359160808201359160a08101359091169060c08101359060e081013515159060ff6101008201351690610120810135906101400135611129565b34801561046657600080fd5b506102d7600480360360a081101561047d57600080fd5b813591602081013591810190606081016040820135600160201b8111156104a357600080fd5b8201836020820111156104b557600080fd5b803590602001918460208302840111600160201b831117156104d657600080fd5b91935091506001600160a01b038135169060200135611223565b3480156104fc57600080fd5b506102d7600480360360a081101561051357600080fd5b813591602081013591810190606081016040820135600160201b81111561053957600080fd5b82018360208201111561054b57600080fd5b803590602001918460208302840111600160201b8311171561056c57600080fd5b91935091506001600160a01b03813516906020013561136e565b34801561059257600080fd5b5061022f60048036036101408110156105aa57600080fd5b506001600160a01b0381358116916020810135916040820135916060810135916080820135169060a08101359060c081013515159060ff60e082013516906101008101359061012001356114fa565b34801561060557600080fd5b50610186600480360360a081101561061c57600080fd5b813591602081013591810190606081016040820135600160201b81111561064257600080fd5b82018360208201111561065457600080fd5b803590602001918460208302840111600160201b8311171561067557600080fd5b91935091506001600160a01b038135169060200135611608565b34801561069b57600080fd5b50610186600480360360a08110156106b257600080fd5b813591602081013591810190606081016040820135600160201b8111156106d857600080fd5b8201836020820111156106ea57600080fd5b803590602001918460208302840111600160201b8311171561070b57600080fd5b91935091506001600160a01b03813516906020013561189d565b6102d76004803603608081101561073b57600080fd5b81359190810190604081016020820135600160201b81111561075c57600080fd5b82018360208201111561076e57600080fd5b803590602001918460208302840111600160201b8311171561078f57600080fd5b91935091506001600160a01b038135169060200135611b21565b3480156107b557600080fd5b5061022f600480360360608110156107cc57600080fd5b5080359060208101359060400135611e74565b3480156107eb57600080fd5b506102d7600480360360a081101561080257600080fd5b813591602081013591810190606081016040820135600160201b81111561082857600080fd5b82018360208201111561083a57600080fd5b803590602001918460208302840111600160201b8311171561085b57600080fd5b91935091506001600160a01b038135169060200135611e81565b34801561088157600080fd5b5061088a611f7a565b604080516001600160a01b039092168252519081900360200190f35b3480156108b257600080fd5b5061022f600480360360608110156108c957600080fd5b5080359060208101359060400135611f9e565b3480156108e857600080fd5b5061022f600480360360c08110156108ff57600080fd5b506001600160a01b0381358116916020810135916040820135916060810135916080820135169060a00135611fab565b6101866004803603608081101561094557600080fd5b81359190810190604081016020820135600160201b81111561096657600080fd5b82018360208201111561097857600080fd5b803590602001918460208302840111600160201b8311171561099957600080fd5b91935091506001600160a01b03813516906020013561212c565b3480156109bf57600080fd5b506101e0600480360360e08110156109d657600080fd5b506001600160a01b038135811691602081013582169160408201359160608101359160808201359160a08101359091169060c001356124b8565b348015610a1c57600080fd5b5061088a6126fc565b348015610a3157600080fd5b506102d760048036036040811015610a4857600080fd5b81359190810190604081016020820135600160201b811115610a6957600080fd5b820183602082011115610a7b57600080fd5b803590602001918460208302840111600160201b83111715610a9c57600080fd5b919080806020026020016040519081016040528093929190818152602001838360200280828437600092019190915250929550612720945050505050565b348015610ae657600080fd5b506101e06004803603610140811015610afe57600080fd5b506001600160a01b0381358116916020810135916040820135916060810135916080820135169060a08101359060c081013515159060ff60e0820135169061010081013590610120013561274d565b348015610b5957600080fd5b50610baf6004803603610100811015610b7157600080fd5b506001600160a01b038135811691602081013582169160408201359160608101359160808201359160a08101359160c0820135169060e00135612861565b60408051938452602084019290925282820152519081900360600190f35b610baf600480360360c0811015610be357600080fd5b506001600160a01b0381358116916020810135916040820135916060810135916080820135169060a0013561299d565b6102d760048036036080811015610c2957600080fd5b81359190810190604081016020820135600160201b811115610c4a57600080fd5b820183602082011115610c5c57600080fd5b803590602001918460208302840111600160201b83111715610c7d57600080fd5b91935091506001600160a01b038135169060200135612c42565b6000808242811015610cde576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b610d0d897f00000000000000000000000000000000000000000000000000000000000000008a8a8a308a6124b8565b9093509150610d1d898685612fc4565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316632e1a7d4d836040518263ffffffff1660e01b815260040180828152602001915050600060405180830381600087803b158015610d8357600080fd5b505af1158015610d97573d6000803e3d6000fd5b50505050610da58583613118565b50965096945050505050565b6000610dbe848484613210565b949350505050565b60608142811015610e0c576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b6001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001686866000198101818110610e4657fe5b905060200201356001600160a01b03166001600160a01b031614610e9f576040805162461bcd60e51b815260206004820152601d60248201526000805160206144fa833981519152604482015290519081900360640190fd5b610efd7f00000000000000000000000000000000000000000000000000000000000000008988888080602002602001604051908101604052809392919081815260200183836020028082843760009201919091525061330092505050565b91508682600184510381518110610f1057fe5b60200260200101511015610f555760405162461bcd60e51b815260040180806020018281038252602b815260200180614540602b913960400191505060405180910390fd5b610ff386866000818110610f6557fe5b905060200201356001600160a01b031633610fd97f00000000000000000000000000000000000000000000000000000000000000008a8a6000818110610fa757fe5b905060200201356001600160a01b03168b8b6001818110610fc457fe5b905060200201356001600160a01b031661344c565b85600081518110610fe657fe5b602002602001015161350c565b61103282878780806020026020016040519081016040528093929190818152602001838360200280828437600092019190915250309250613669915050565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316632e1a7d4d8360018551038151811061107157fe5b60200260200101516040518263ffffffff1660e01b815260040180828152602001915050600060405180830381600087803b1580156110af57600080fd5b505af11580156110c3573d6000803e3d6000fd5b505050506110e884836001855103815181106110db57fe5b6020026020010151613118565b509695505050505050565b60606111207f000000000000000000000000000000000000000000000000000000000000000084846138af565b90505b92915050565b60008060006111597f00000000000000000000000000000000000000000000000000000000000000008f8f61344c565b9050600087611168578c61116c565b6000195b6040805163d505accf60e01b815233600482015230602482015260448101839052606481018c905260ff8a16608482015260a4810189905260c4810188905290519192506001600160a01b0384169163d505accf9160e48082019260009290919082900301818387803b1580156111e257600080fd5b505af11580156111f6573d6000803e3d6000fd5b505050506112098f8f8f8f8f8f8f6124b8565b809450819550505050509b509b9950505050505050505050565b60608142811015611269576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b6112c77f00000000000000000000000000000000000000000000000000000000000000008988888080602002602001604051908101604052809392919081815260200183836020028082843760009201919091525061330092505050565b915086826001845103815181106112da57fe5b6020026020010151101561131f5760405162461bcd60e51b815260040180806020018281038252602b815260200180614540602b913960400191505060405180910390fd5b61132f86866000818110610f6557fe5b6110e882878780806020026020016040519081016040528093929190818152602001838360200280828437600092019190915250899250613669915050565b606081428110156113b4576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b6001600160a01b037f000000000000000000000000000000000000000000000000000000000000000016868660001981018181106113ee57fe5b905060200201356001600160a01b03166001600160a01b031614611447576040805162461bcd60e51b815260206004820152601d60248201526000805160206144fa833981519152604482015290519081900360640190fd5b6114a57f0000000000000000000000000000000000000000000000000000000000000000898888808060200260200160405190810160405280939291908181526020018383602002808284376000920191909152506138af92505050565b915086826000815181106114b557fe5b60200260200101511115610f555760405162461bcd60e51b81526004018080602001828103825260278152602001806144d36027913960400191505060405180910390fd5b6000806115487f00000000000000000000000000000000000000000000000000000000000000008d7f000000000000000000000000000000000000000000000000000000000000000061344c565b9050600086611557578b61155b565b6000195b6040805163d505accf60e01b815233600482015230602482015260448101839052606481018b905260ff8916608482015260a4810188905260c4810187905290519192506001600160a01b0384169163d505accf9160e48082019260009290919082900301818387803b1580156115d157600080fd5b505af11580156115e5573d6000803e3d6000fd5b505050506115f78d8d8d8d8d8d611fab565b9d9c50505050505050505050505050565b804281101561164c576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b6116c18585600081811061165c57fe5b905060200201356001600160a01b0316336116bb7f00000000000000000000000000000000000000000000000000000000000000008989600081811061169e57fe5b905060200201356001600160a01b03168a8a6001818110610fc457fe5b8a61350c565b6000858560001981018181106116d357fe5b905060200201356001600160a01b03166001600160a01b03166370a08231856040518263ffffffff1660e01b815260040180826001600160a01b03166001600160a01b0316815260200191505060206040518083038186803b15801561173857600080fd5b505afa15801561174c573d6000803e3d6000fd5b505050506040513d602081101561176257600080fd5b505160408051602088810282810182019093528882529293506117a49290918991899182918501908490808284376000920191909152508892506139e7915050565b8661185682888860001981018181106117b957fe5b905060200201356001600160a01b03166001600160a01b03166370a08231886040518263ffffffff1660e01b815260040180826001600160a01b03166001600160a01b0316815260200191505060206040518083038186803b15801561181e57600080fd5b505afa158015611832573d6000803e3d6000fd5b505050506040513d602081101561184857600080fd5b50519063ffffffff613cf216565b10156118935760405162461bcd60e51b815260040180806020018281038252602b815260200180614540602b913960400191505060405180910390fd5b5050505050505050565b80428110156118e1576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b6001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000168585600019810181811061191b57fe5b905060200201356001600160a01b03166001600160a01b031614611974576040805162461bcd60e51b815260206004820152601d60248201526000805160206144fa833981519152604482015290519081900360640190fd5b6119848585600081811061165c57fe5b6119c28585808060200260200160405190810160405280939291908181526020018383602002808284376000920191909152503092506139e7915050565b604080516370a0823160e01b815230600482015290516000916001600160a01b037f000000000000000000000000000000000000000000000000000000000000000016916370a0823191602480820192602092909190829003018186803b158015611a2c57600080fd5b505afa158015611a40573d6000803e3d6000fd5b505050506040513d6020811015611a5657600080fd5b5051905086811015611a995760405162461bcd60e51b815260040180806020018281038252602b815260200180614540602b913960400191505060405180910390fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316632e1a7d4d826040518263ffffffff1660e01b815260040180828152602001915050600060405180830381600087803b158015611aff57600080fd5b505af1158015611b13573d6000803e3d6000fd5b505050506118938482613118565b60608142811015611b67576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031686866000818110611b9e57fe5b905060200201356001600160a01b03166001600160a01b031614611bf7576040805162461bcd60e51b815260206004820152601d60248201526000805160206144fa833981519152604482015290519081900360640190fd5b611c557f00000000000000000000000000000000000000000000000000000000000000003488888080602002602001604051908101604052809392919081815260200183836020028082843760009201919091525061330092505050565b91508682600184510381518110611c6857fe5b60200260200101511015611cad5760405162461bcd60e51b815260040180806020018281038252602b815260200180614540602b913960400191505060405180910390fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663d0e30db083600081518110611ce957fe5b60200260200101516040518263ffffffff1660e01b81526004016000604051808303818588803b158015611d1c57600080fd5b505af1158015611d30573d6000803e3d6000fd5b50505050507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663a9059cbb611d957f00000000000000000000000000000000000000000000000000000000000000008989600081811061169e57fe5b84600081518110611da257fe5b60200260200101516040518363ffffffff1660e01b815260040180836001600160a01b03166001600160a01b0316815260200182815260200192505050602060405180830381600087803b158015611df957600080fd5b505af1158015611e0d573d6000803e3d6000fd5b505050506040513d6020811015611e2357600080fd5b5051611e2b57fe5b611e6a82878780806020026020016040519081016040528093929190818152602001838360200280828437600092019190915250899250613669915050565b5095945050505050565b6000610dbe848484613d42565b60608142811015611ec7576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b611f257f0000000000000000000000000000000000000000000000000000000000000000898888808060200260200160405190810160405280939291908181526020018383602002808284376000920191909152506138af92505050565b91508682600081518110611f3557fe5b6020026020010151111561131f5760405162461bcd60e51b81526004018080602001828103825260278152602001806144d36027913960400191505060405180910390fd5b7f000000000000000000000000000000000000000000000000000000000000000081565b6000610dbe848484613e32565b60008142811015611ff1576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b612020887f000000000000000000000000000000000000000000000000000000000000000089898930896124b8565b604080516370a0823160e01b815230600482015290519194506120a492508a9187916001600160a01b038416916370a0823191602480820192602092909190829003018186803b15801561207357600080fd5b505afa158015612087573d6000803e3d6000fd5b505050506040513d602081101561209d57600080fd5b5051612fc4565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316632e1a7d4d836040518263ffffffff1660e01b815260040180828152602001915050600060405180830381600087803b15801561210a57600080fd5b505af115801561211e573d6000803e3d6000fd5b505050506110e88483613118565b8042811015612170576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316858560008181106121a757fe5b905060200201356001600160a01b03166001600160a01b031614612200576040805162461bcd60e51b815260206004820152601d60248201526000805160206144fa833981519152604482015290519081900360640190fd5b60003490507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663d0e30db0826040518263ffffffff1660e01b81526004016000604051808303818588803b15801561226057600080fd5b505af1158015612274573d6000803e3d6000fd5b50505050507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663a9059cbb6122d97f00000000000000000000000000000000000000000000000000000000000000008989600081811061169e57fe5b836040518363ffffffff1660e01b815260040180836001600160a01b03166001600160a01b0316815260200182815260200192505050602060405180830381600087803b15801561232957600080fd5b505af115801561233d573d6000803e3d6000fd5b505050506040513d602081101561235357600080fd5b505161235b57fe5b60008686600019810181811061236d57fe5b905060200201356001600160a01b03166001600160a01b03166370a08231866040518263ffffffff1660e01b815260040180826001600160a01b03166001600160a01b0316815260200191505060206040518083038186803b1580156123d257600080fd5b505afa1580156123e6573d6000803e3d6000fd5b505050506040513d60208110156123fc57600080fd5b5051604080516020898102828101820190935289825292935061243e9290918a918a9182918501908490808284376000920191909152508992506139e7915050565b87611856828989600019810181811061245357fe5b905060200201356001600160a01b03166001600160a01b03166370a08231896040518263ffffffff1660e01b815260040180826001600160a01b03166001600160a01b0316815260200191505060206040518083038186803b15801561181e57600080fd5b60008082428110156124ff576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b600061252c7f00000000000000000000000000000000000000000000000000000000000000008c8c61344c565b604080516323b872dd60e01b81523360048201526001600160a01b03831660248201819052604482018d9052915192935090916323b872dd916064808201926020929091908290030181600087803b15801561258757600080fd5b505af115801561259b573d6000803e3d6000fd5b505050506040513d60208110156125b157600080fd5b50506040805163226bf2d160e21b81526001600160a01b03888116600483015282516000938493928616926389afcb44926024808301939282900301818787803b1580156125fe57600080fd5b505af1158015612612573d6000803e3d6000fd5b505050506040513d604081101561262857600080fd5b508051602090910151909250905060006126428e8e613ede565b509050806001600160a01b03168e6001600160a01b031614612665578183612668565b82825b90975095508a8710156126ac5760405162461bcd60e51b815260040180806020018281038252602681526020018061451a6026913960400191505060405180910390fd5b898610156126eb5760405162461bcd60e51b81526004018080602001828103825260268152602001806144606026913960400191505060405180910390fd5b505050505097509795505050505050565b7f000000000000000000000000000000000000000000000000000000000000000081565b60606111207f00000000000000000000000000000000000000000000000000000000000000008484613300565b600080600061279d7f00000000000000000000000000000000000000000000000000000000000000008e7f000000000000000000000000000000000000000000000000000000000000000061344c565b90506000876127ac578c6127b0565b6000195b6040805163d505accf60e01b815233600482015230602482015260448101839052606481018c905260ff8a16608482015260a4810189905260c4810188905290519192506001600160a01b0384169163d505accf9160e48082019260009290919082900301818387803b15801561282657600080fd5b505af115801561283a573d6000803e3d6000fd5b5050505061284c8e8e8e8e8e8e610c97565b909f909e509c50505050505050505050505050565b600080600083428110156128aa576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b6128b88c8c8c8c8c8c613fbc565b909450925060006128ea7f00000000000000000000000000000000000000000000000000000000000000008e8e61344c565b90506128f88d33838861350c565b6129048c33838761350c565b806001600160a01b0316636a627842886040518263ffffffff1660e01b815260040180826001600160a01b03166001600160a01b03168152602001915050602060405180830381600087803b15801561295c57600080fd5b505af1158015612970573d6000803e3d6000fd5b505050506040513d602081101561298657600080fd5b5051949d939c50939a509198505050505050505050565b600080600083428110156129e6576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b612a148a7f00000000000000000000000000000000000000000000000000000000000000008b348c8c613fbc565b90945092506000612a667f00000000000000000000000000000000000000000000000000000000000000008c7f000000000000000000000000000000000000000000000000000000000000000061344c565b9050612a748b33838861350c565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663d0e30db0856040518263ffffffff1660e01b81526004016000604051808303818588803b158015612acf57600080fd5b505af1158015612ae3573d6000803e3d6000fd5b50505050507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663a9059cbb82866040518363ffffffff1660e01b815260040180836001600160a01b03166001600160a01b0316815260200182815260200192505050602060405180830381600087803b158015612b6857600080fd5b505af1158015612b7c573d6000803e3d6000fd5b505050506040513d6020811015612b9257600080fd5b5051612b9a57fe5b806001600160a01b0316636a627842886040518263ffffffff1660e01b815260040180826001600160a01b03166001600160a01b03168152602001915050602060405180830381600087803b158015612bf257600080fd5b505af1158015612c06573d6000803e3d6000fd5b505050506040513d6020811015612c1c57600080fd5b5051925034841015612c3457612c3433853403613118565b505096509650969350505050565b60608142811015612c88576040805162461bcd60e51b815260206004820152601860248201526000805160206145c3833981519152604482015290519081900360640190fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031686866000818110612cbf57fe5b905060200201356001600160a01b03166001600160a01b031614612d18576040805162461bcd60e51b815260206004820152601d60248201526000805160206144fa833981519152604482015290519081900360640190fd5b612d767f0000000000000000000000000000000000000000000000000000000000000000888888808060200260200160405190810160405280939291908181526020018383602002808284376000920191909152506138af92505050565b91503482600081518110612d8657fe5b60200260200101511115612dcb5760405162461bcd60e51b81526004018080602001828103825260278152602001806144d36027913960400191505060405180910390fd5b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663d0e30db083600081518110612e0757fe5b60200260200101516040518263ffffffff1660e01b81526004016000604051808303818588803b158015612e3a57600080fd5b505af1158015612e4e573d6000803e3d6000fd5b50505050507f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663a9059cbb612eb37f00000000000000000000000000000000000000000000000000000000000000008989600081811061169e57fe5b84600081518110612ec057fe5b60200260200101516040518363ffffffff1660e01b815260040180836001600160a01b03166001600160a01b0316815260200182815260200192505050602060405180830381600087803b158015612f1757600080fd5b505af1158015612f2b573d6000803e3d6000fd5b505050506040513d6020811015612f4157600080fd5b5051612f4957fe5b612f8882878780806020026020016040519081016040528093929190818152602001838360200280828437600092019190915250899250613669915050565b81600081518110612f9557fe5b6020026020010151341115611e6a57611e6a3383600081518110612fb557fe5b60200260200101513403613118565b604080516001600160a01b038481166024830152604480830185905283518084039091018152606490920183526020820180516001600160e01b031663a9059cbb60e01b178152925182516000946060949389169392918291908083835b602083106130415780518252601f199092019160209182019101613022565b6001836020036101000a0380198251168184511680821785525050505050509050019150506000604051808303816000865af19150503d80600081146130a3576040519150601f19603f3d011682016040523d82523d6000602084013e6130a8565b606091505b50915091508180156130d65750805115806130d657508080602001905160208110156130d357600080fd5b50515b6131115760405162461bcd60e51b815260040180806020018281038252602d81526020018061456b602d913960400191505060405180910390fd5b5050505050565b604080516000808252602082019092526001600160a01b0384169083906040518082805190602001908083835b602083106131645780518252601f199092019160209182019101613145565b6001836020036101000a03801982511681845116808217855250505050505090500191505060006040518083038185875af1925050503d80600081146131c6576040519150601f19603f3d011682016040523d82523d6000602084013e6131cb565b606091505b505090508061320b5760405162461bcd60e51b81526004018080602001828103825260348152602001806144076034913960400191505060405180910390fd5b505050565b60008084116132505760405162461bcd60e51b815260040180806020018281038252602b815260200180614598602b913960400191505060405180910390fd5b6000831180156132605750600082115b61329b5760405162461bcd60e51b81526004018080602001828103825260288152602001806144866028913960400191505060405180910390fd5b60006132af856103e563ffffffff61423016565b905060006132c3828563ffffffff61423016565b905060006132e9836132dd886103e863ffffffff61423016565b9063ffffffff61429316565b90508082816132f457fe5b04979650505050505050565b6060600282511015613359576040805162461bcd60e51b815260206004820152601e60248201527f556e697377617056324c6962726172793a20494e56414c49445f504154480000604482015290519081900360640190fd5b815167ffffffffffffffff8111801561337157600080fd5b5060405190808252806020026020018201604052801561339b578160200160208202803683370190505b50905082816000815181106133ac57fe5b60200260200101818152505060005b6001835103811015613444576000806133fe878685815181106133da57fe5b60200260200101518786600101815181106133f157fe5b60200260200101516142e2565b9150915061342084848151811061341157fe5b60200260200101518383613210565b84846001018151811061342f57fe5b602090810291909101015250506001016133bb565b509392505050565b600080600061345b8585613ede565b604080516bffffffffffffffffffffffff19606094851b811660208084019190915293851b81166034830152825160288184030181526048830184528051908501206001600160f81b031960688401529a90941b9093166069840152607d8301989098527f7e94d55cb675b314384bbad42db81f28d6e23765aeb5e4f4d9fc32c135dba2d4609d808401919091528851808403909101815260bd909201909752805196019590952095945050505050565b604080516001600160a01b0385811660248301528481166044830152606480830185905283518084039091018152608490920183526020820180516001600160e01b03166323b872dd60e01b17815292518251600094606094938a169392918291908083835b602083106135915780518252601f199092019160209182019101613572565b6001836020036101000a0380198251168184511680821785525050505050509050019150506000604051808303816000865af19150503d80600081146135f3576040519150601f19603f3d011682016040523d82523d6000602084013e6135f8565b606091505b5091509150818015613626575080511580613626575080806020019051602081101561362357600080fd5b50515b6136615760405162461bcd60e51b81526004018080602001828103825260318152602001806143d66031913960400191505060405180910390fd5b505050505050565b60005b60018351038110156138a95760008084838151811061368757fe5b602002602001015185846001018151811061369e57fe5b60200260200101519150915060006136b68383613ede565b50905060008785600101815181106136ca57fe5b60200260200101519050600080836001600160a01b0316866001600160a01b0316146136f8578260006136fc565b6000835b91509150600060028a510388106137135788613754565b6137547f0000000000000000000000000000000000000000000000000000000000000000878c8b6002018151811061374757fe5b602002602001015161344c565b90506137817f0000000000000000000000000000000000000000000000000000000000000000888861344c565b6001600160a01b031663022c0d9f84848460006040519080825280601f01601f1916602001820160405280156137be576020820181803683370190505b506040518563ffffffff1660e01b815260040180858152602001848152602001836001600160a01b03166001600160a01b0316815260200180602001828103825283818151815260200191508051906020019080838360005b8381101561382f578181015183820152602001613817565b50505050905090810190601f16801561385c5780820380516001836020036101000a031916815260200191505b5095505050505050600060405180830381600087803b15801561387e57600080fd5b505af1158015613892573d6000803e3d6000fd5b50506001909901985061366c975050505050505050565b50505050565b6060600282511015613908576040805162461bcd60e51b815260206004820152601e60248201527f556e697377617056324c6962726172793a20494e56414c49445f504154480000604482015290519081900360640190fd5b815167ffffffffffffffff8111801561392057600080fd5b5060405190808252806020026020018201604052801561394a578160200160208202803683370190505b509050828160018351038151811061395e57fe5b60209081029190910101528151600019015b8015613444576000806139a08786600186038151811061398c57fe5b60200260200101518786815181106133f157fe5b915091506139c28484815181106139b357fe5b60200260200101518383613d42565b8460018503815181106139d157fe5b6020908102919091010152505060001901613970565b60005b600183510381101561320b57600080848381518110613a0557fe5b6020026020010151858460010181518110613a1c57fe5b6020026020010151915091506000613a348383613ede565b5090506000613a647f0000000000000000000000000000000000000000000000000000000000000000858561344c565b9050600080600080846001600160a01b0316630902f1ac6040518163ffffffff1660e01b815260040160606040518083038186803b158015613aa557600080fd5b505afa158015613ab9573d6000803e3d6000fd5b505050506040513d6060811015613acf57600080fd5b5080516020909101516001600160701b0391821693501690506000806001600160a01b038a811690891614613b05578284613b08565b83835b91509150613b66828b6001600160a01b03166370a082318a6040518263ffffffff1660e01b815260040180826001600160a01b03166001600160a01b0316815260200191505060206040518083038186803b15801561181e57600080fd5b9550613b73868383613210565b945050505050600080856001600160a01b0316886001600160a01b031614613b9d57826000613ba1565b6000835b91509150600060028c51038a10613bb8578a613bec565b613bec7f0000000000000000000000000000000000000000000000000000000000000000898e8d6002018151811061374757fe5b604080516000808252602082019283905263022c0d9f60e01b835260248201878152604483018790526001600160a01b038086166064850152608060848501908152845160a48601819052969750908c169563022c0d9f958a958a958a9591949193919260c486019290918190849084905b83811015613c76578181015183820152602001613c5e565b50505050905090810190601f168015613ca35780820380516001836020036101000a031916815260200191505b5095505050505050600060405180830381600087803b158015613cc557600080fd5b505af1158015613cd9573d6000803e3d6000fd5b50506001909b019a506139ea9950505050505050505050565b80820382811115611123576040805162461bcd60e51b815260206004820152601560248201527464732d6d6174682d7375622d756e646572666c6f7760581b604482015290519081900360640190fd5b6000808411613d825760405162461bcd60e51b815260040180806020018281038252602c8152602001806143aa602c913960400191505060405180910390fd5b600083118015613d925750600082115b613dcd5760405162461bcd60e51b81526004018080602001828103825260288152602001806144866028913960400191505060405180910390fd5b6000613df16103e8613de5868863ffffffff61423016565b9063ffffffff61423016565b90506000613e0b6103e5613de5868963ffffffff613cf216565b9050613e286001828481613e1b57fe5b049063ffffffff61429316565b9695505050505050565b6000808411613e725760405162461bcd60e51b81526004018080602001828103825260258152602001806144ae6025913960400191505060405180910390fd5b600083118015613e825750600082115b613ebd5760405162461bcd60e51b81526004018080602001828103825260288152602001806144866028913960400191505060405180910390fd5b82613ece858463ffffffff61423016565b81613ed557fe5b04949350505050565b600080826001600160a01b0316846001600160a01b03161415613f325760405162461bcd60e51b815260040180806020018281038252602581526020018061443b6025913960400191505060405180910390fd5b826001600160a01b0316846001600160a01b031610613f52578284613f55565b83835b90925090506001600160a01b038216613fb5576040805162461bcd60e51b815260206004820152601e60248201527f556e697377617056324c6962726172793a205a45524f5f414444524553530000604482015290519081900360640190fd5b9250929050565b6040805163e6a4390560e01b81526001600160a01b03888116600483015287811660248301529151600092839283927f00000000000000000000000000000000000000000000000000000000000000009092169163e6a4390591604480820192602092909190829003018186803b15801561403657600080fd5b505afa15801561404a573d6000803e3d6000fd5b505050506040513d602081101561406057600080fd5b50516001600160a01b0316141561411357604080516364e329cb60e11b81526001600160a01b038a81166004830152898116602483015291517f00000000000000000000000000000000000000000000000000000000000000009092169163c9c65396916044808201926020929091908290030181600087803b1580156140e657600080fd5b505af11580156140fa573d6000803e3d6000fd5b505050506040513d602081101561411057600080fd5b50505b6000806141417f00000000000000000000000000000000000000000000000000000000000000008b8b6142e2565b91509150816000148015614153575080155b1561416357879350869250614223565b6000614170898484613e32565b90508781116141c357858110156141b85760405162461bcd60e51b81526004018080602001828103825260268152602001806144606026913960400191505060405180910390fd5b889450925082614221565b60006141d0898486613e32565b9050898111156141dc57fe5b8781101561421b5760405162461bcd60e51b815260040180806020018281038252602681526020018061451a6026913960400191505060405180910390fd5b94508793505b505b5050965096945050505050565b600081158061424b5750508082028282828161424857fe5b04145b611123576040805162461bcd60e51b815260206004820152601460248201527364732d6d6174682d6d756c2d6f766572666c6f7760601b604482015290519081900360640190fd5b80820182811015611123576040805162461bcd60e51b815260206004820152601460248201527364732d6d6174682d6164642d6f766572666c6f7760601b604482015290519081900360640190fd5b60008060006142f18585613ede565b50905060008061430288888861344c565b6001600160a01b0316630902f1ac6040518163ffffffff1660e01b815260040160606040518083038186803b15801561433a57600080fd5b505afa15801561434e573d6000803e3d6000fd5b505050506040513d606081101561436457600080fd5b5080516020909101516001600160701b0391821693501690506001600160a01b038781169084161461439757808261439a565b81815b9099909850965050505050505056fe556e697377617056324c6962726172793a20494e53554646494349454e545f4f55545055545f414d4f554e545472616e7366657248656c7065723a3a7472616e7366657246726f6d3a207472616e7366657246726f6d206661696c65645472616e7366657248656c7065723a3a736166655472616e736665724554483a20455448207472616e73666572206661696c6564556e697377617056324c6962726172793a204944454e544943414c5f414444524553534553556e69737761705632526f757465723a20494e53554646494349454e545f425f414d4f554e54556e697377617056324c6962726172793a20494e53554646494349454e545f4c4951554944495459556e697377617056324c6962726172793a20494e53554646494349454e545f414d4f554e54556e69737761705632526f757465723a204558434553534956455f494e5055545f414d4f554e54556e69737761705632526f757465723a20494e56414c49445f50415448000000556e69737761705632526f757465723a20494e53554646494349454e545f415f414d4f554e54556e69737761705632526f757465723a20494e53554646494349454e545f4f55545055545f414d4f554e545472616e7366657248656c7065723a3a736166655472616e736665723a207472616e73666572206661696c6564556e697377617056324c6962726172793a20494e53554646494349454e545f494e5055545f414d4f554e54556e69737761705632526f757465723a20455850495245440000000000000000a264697066735822122047df80f1a7c10914f638b3ecbee2089fbb2c5a1561204f4fefca475be6a9b23964736f6c63430006060033";
        vector::append(&mut router_code, to_32bit(factory_addr));
        vector::append(&mut router_code, to_32bit(weth_addr));
        // debug::print(&router_code);
        let router_addr = create(sender, 5, router_code, 0);
        debug::print(&router_addr);

        debug::print(&utf8(b"approve usdc"));
        //095ea7b3 + router address
        let approve_usdc_params = vector::empty<u8>();
        vector::append(&mut approve_usdc_params, x"095ea7b3");
        vector::append(&mut approve_usdc_params, router_addr);
        // 1000000 * 1e18
        vector::append(&mut approve_usdc_params, u256_to_data(1000000000000000000000000));
        debug::print(&approve_usdc_params);
        call(&user, sender, usdc_addr, approve_usdc_params, 0);

        debug::print(&utf8(b"approve usdt"));
        //095ea7b3 + router address
        let approve_usdt_params = vector::empty<u8>();
        vector::append(&mut approve_usdt_params, x"095ea7b3");
        // 1000000 * 1e18
        vector::append(&mut approve_usdt_params, router_addr);
        vector::append(&mut approve_usdt_params, u256_to_data(1000000000000000000000000));
        debug::print(&approve_usdt_params);
        call(&user, sender, usdt_addr, approve_usdt_params, 0);

        debug::print(&utf8(b"mint usdc"));
        //40c10f19 + to address
        let mint_usdc_params = vector::empty<u8>();
        vector::append(&mut mint_usdc_params, x"40c10f19");
        vector::append(&mut mint_usdc_params, sender);
        // 200 * 1e18
        vector::append(&mut mint_usdc_params, u256_to_data(500000000000000000000));
        debug::print(&mint_usdc_params);
        call(&user, sender, usdc_addr, mint_usdc_params, 0);

        debug::print(&utf8(b"mint usdt"));
        //40c10f19 + to address
        let mint_usdt_params = vector::empty<u8>();
        vector::append(&mut mint_usdt_params, x"40c10f19");
        vector::append(&mut mint_usdt_params, sender);
        // 200 * 1e18
        vector::append(&mut mint_usdt_params, u256_to_data(500000000000000000000));
        call(&user, sender, usdt_addr, mint_usdt_params, 0);
        debug::print(&mint_usdc_params);

        let deadline = 1697746917;

        debug::print(&utf8(b"add liquidity"));
        //e8e33700 + tokenA + tokenB + amountADesired + amountBDesired + amountAMin + amountBMin + to + deadline
        let add_liquidity_params = vector::empty<u8>();
        vector::append(&mut add_liquidity_params, x"e8e33700");
        vector::append(&mut add_liquidity_params, to_32bit(usdc_addr));
        vector::append(&mut add_liquidity_params, to_32bit(usdt_addr));
        // 100 * 1e18
        vector::append(&mut add_liquidity_params, u256_to_data(100000000000000000000));
        vector::append(&mut add_liquidity_params, u256_to_data(100000000000000000000));
        //0
        vector::append(&mut add_liquidity_params, u256_to_data(0));
        vector::append(&mut add_liquidity_params, u256_to_data(0));

        vector::append(&mut add_liquidity_params, sender);
        vector::append(&mut add_liquidity_params, u256_to_data(deadline));
        debug::print(&add_liquidity_params);
        call(&user, sender, router_addr, add_liquidity_params, 0);

        debug::print(&utf8(b"get balance of USDC"));
        let params = vector::empty<u8>();
        vector::append(&mut params, x"70a08231");
        vector::append(&mut params, sender);
        debug::print(&params);
        debug::print(&view(x"", usdc_addr, params));

        debug::print(&utf8(b"get balance of USDT"));
        let params = vector::empty<u8>();
        vector::append(&mut params, x"70a08231");
        vector::append(&mut params, sender);
        debug::print(&view(x"", usdt_addr, params));
        //
        debug::print(&utf8(b"swap usdc for usdt"));
        //38ed1739 + amountIn + amountOutMin + path + to + deadline
        let swap_params = vector::empty<u8>();
        vector::append(&mut swap_params, x"38ed1739");
        vector::append(&mut swap_params, u256_to_data(100000000000000000000));
        vector::append(&mut swap_params, u256_to_data(0));
        // array pointer
        vector::append(&mut swap_params, to_32bit(x"a0"));
        vector::append(&mut swap_params, to_32bit(sender));
        vector::append(&mut swap_params, u256_to_data(deadline));
        //address[] array
        vector::append(&mut swap_params, u256_to_data(2));// array size
        vector::append(&mut swap_params, to_32bit(usdt_addr));
        vector::append(&mut swap_params, to_32bit(usdc_addr));
        debug::print(&swap_params);
        call(&user, sender, router_addr, swap_params, 0);

        debug::print(&utf8(b"approve pair"));
        //095ea7b3 + router address
        let approve_usdt_params = vector::empty<u8>();
        vector::append(&mut approve_usdt_params, x"095ea7b3");
        // 1000000 * 1e18
        vector::append(&mut approve_usdt_params, router_addr);
        vector::append(&mut approve_usdt_params, u256_to_data(10000000000000000000000));
        debug::print(&approve_usdt_params);
        call(&user, sender, pair_addr, approve_usdt_params, 0);

        debug::print(&utf8(b"remove liquidity"));
        //095ea7b3 + router address
        let remove_params = vector::empty<u8>();
        vector::append(&mut remove_params, x"baa2abde");
        // 1000000 * 1e18
        vector::append(&mut remove_params, usdc_addr);
        vector::append(&mut remove_params, usdt_addr);
        vector::append(&mut remove_params, u256_to_data(1000000000000000000));
        vector::append(&mut remove_params, u256_to_data(0));
        vector::append(&mut remove_params, u256_to_data(0));
        vector::append(&mut remove_params, to_32bit(sender));
        vector::append(&mut remove_params, u256_to_data(deadline));
        debug::print(&remove_params);
        call(&user, sender, router_addr, remove_params, 0);

        debug::print(&utf8(b"get balance of USDC"));
        let params = vector::empty<u8>();
        vector::append(&mut params, x"70a08231");
        vector::append(&mut params, sender);
        debug::print(&view(x"", usdc_addr, params));

        debug::print(&utf8(b"get balance of USDT"));
        let params = vector::empty<u8>();
        vector::append(&mut params, x"70a08231");
        vector::append(&mut params, sender);
        debug::print(&view(x"", usdt_addr, params));
        //get balance of lp token

        // debug::print(&borrow_global_mut<S>(@demo).contracts);

        let multicall_bytecode = x"608060405234801561001057600080fd5b5061066e806100206000396000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c806372425d9d1161005b57806372425d9d146100e757806386d516e8146100ef578063a8b0574e146100f7578063ee82ac5e1461010c57610088565b80630f28c97d1461008d578063252dba42146100ab57806327e86d6e146100cc5780634d2301cc146100d4575b600080fd5b61009561011f565b6040516100a2919061051e565b60405180910390f35b6100be6100b93660046103b6565b610123565b6040516100a292919061052c565b610095610231565b6100956100e2366004610390565b61023a565b610095610247565b61009561024b565b6100ff61024f565b6040516100a2919061050a565b61009561011a3660046103eb565b610253565b4290565b60006060439150825160405190808252806020026020018201604052801561015f57816020015b606081526020019060019003908161014a5790505b50905060005b835181101561022b576000606085838151811061017e57fe5b6020026020010151600001516001600160a01b031686848151811061019f57fe5b6020026020010151602001516040516101b891906104fe565b6000604051808303816000865af19150503d80600081146101f5576040519150601f19603f3d011682016040523d82523d6000602084013e6101fa565b606091505b50915091508161020957600080fd5b8084848151811061021657fe5b60209081029190910101525050600101610165565b50915091565b60001943014090565b6001600160a01b03163190565b4490565b4590565b4190565b4090565b600061026382356105d4565b9392505050565b600082601f83011261027b57600080fd5b813561028e61028982610573565b61054c565b81815260209384019390925082018360005b838110156102cc57813586016102b68882610325565b84525060209283019291909101906001016102a0565b5050505092915050565b600082601f8301126102e757600080fd5b81356102f561028982610594565b9150808252602083016020830185838301111561031157600080fd5b61031c8382846105ee565b50505092915050565b60006040828403121561033757600080fd5b610341604061054c565b9050600061034f8484610257565b825250602082013567ffffffffffffffff81111561036c57600080fd5b610378848285016102d6565b60208301525092915050565b600061026382356105df565b6000602082840312156103a257600080fd5b60006103ae8484610257565b949350505050565b6000602082840312156103c857600080fd5b813567ffffffffffffffff8111156103df57600080fd5b6103ae8482850161026a565b6000602082840312156103fd57600080fd5b60006103ae8484610384565b60006102638383610497565b61041e816105d4565b82525050565b600061042f826105c2565b61043981856105c6565b93508360208202850161044b856105bc565b60005b84811015610482578383038852610466838351610409565b9250610471826105bc565b60209890980197915060010161044e565b50909695505050505050565b61041e816105df565b60006104a2826105c2565b6104ac81856105c6565b93506104bc8185602086016105fa565b6104c58161062a565b9093019392505050565b60006104da826105c2565b6104e481856105cf565b93506104f48185602086016105fa565b9290920192915050565b600061026382846104cf565b602081016105188284610415565b92915050565b60208101610518828461048e565b6040810161053a828561048e565b81810360208301526103ae8184610424565b60405181810167ffffffffffffffff8111828210171561056b57600080fd5b604052919050565b600067ffffffffffffffff82111561058a57600080fd5b5060209081020190565b600067ffffffffffffffff8211156105ab57600080fd5b506020601f91909101601f19160190565b60200190565b5190565b90815260200190565b919050565b6000610518826105e2565b90565b6001600160a01b031690565b82818337506000910152565b60005b838110156106155781810151838201526020016105fd565b83811115610624576000848401525b50505050565b601f01601f19169056fea265627a7a72305820978cd44d5ce226bebdf172bdf24918753b9e111e3803cb6249d3ca2860b7a47f6c6578706572696d656e74616cf50037";
        let multicall_addr = create(sender, 6, multicall_bytecode, 0);
        debug::print(&multicall_addr);
        let mulicall_params = x"252dba420000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000009c4aae49118b26f5f4efa5865e6bfcc2cfd6a94b0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000002470a08231000000000000000000000000892a2b7cf919760e148a0d33c1eb0f44d3b383f800000000000000000000000000000000000000000000000000000000";
        debug::print(&utf8(b"call multicall"));
        debug::print(&view(x"", multicall_addr, mulicall_params));

        // debug::print(&view(x"", multicall_addr, mulicall_params));
        // call(x"40c10f19000000000000000000000000892a2b7cf919760e148a0d33c1eb0f44d3b383f80000000000000000000000000000000000000000000000000000000000000064");
    }

}
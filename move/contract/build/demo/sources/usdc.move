module demo::usdc {
    use std::vector;
    use std::signer;
    use aptos_std::simple_map;
    use aptos_std::simple_map::SimpleMap;
    #[test_only]
    use aptos_framework::account;
    use aptos_std::debug;
    use aptos_std::aptos_hash::keccak256;
    use aptos_framework::event::EventHandle;
    use aptos_framework::account::new_event_handle;
    use aptos_framework::event;

    const U256_MAX: u256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    struct Log3Event has drop, store {
        data: vector<u8>,
        topic0: u256,
        topic1: u256,
        topic2: u256
    }

    struct T has key {
        storage: SimpleMap<u256, u256>,
        runtime: vector<u8>,
        construct: vector<u8>,
        log3Event: EventHandle<Log3Event>
    }

    entry fun init_module(account: &signer) {
        move_to(account, T {
            storage: simple_map::create<u256, u256>(),
            runtime: vector::empty(),
            construct: vector::empty(),
            log3Event: new_event_handle<Log3Event>(account)
        });
    }

    entry fun init_runcode(account: &signer, runtime: vector<u8>, construct: vector<u8>) acquires T {
        assert!(signer::address_of(account) == @demo, 0);
        let global = borrow_global_mut<T>(@demo);
        global.runtime = runtime;
        global.construct = construct;
        run(construct, x"");
    }

    public entry fun call(data: vector<u8>) acquires T  {
        let code = borrow_global<T>(@demo).runtime;
        run(code, data);
    }

    #[view]
    public fun view(data: vector<u8>): vector<u8> acquires T  {
        run(borrow_global<T>(@demo).runtime, data)
    }


    fun run(code: vector<u8>, data: vector<u8>): vector<u8> acquires T {
        let stack = &mut vector::empty<u256>();
        let move_ret = vector::empty<u8>();
        let memory = &mut simple_map::create<u256, u256>();
        let global = borrow_global_mut<T>(@demo);
        let len = vector::length(&code);
        let i = 0;
        // debug::print(&global.storage);

        while (i < len) {
            let opcode = *vector::borrow(&code, i);
            // debug::print(&opcode);
            // stop
            if(opcode == 0x00) {
                break
            }
            else if(opcode == 0xf3) {
                let pos = vector::pop_back(stack);
                let end = vector::pop_back(stack) + pos;
                move_ret = readBytes(memory, pos, end);
                break
            }
                //add
            else if(opcode == 0x01) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, a + b);
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
                    vector::push_back(stack, U256_MAX - b + a);
                };
                i = i + 1;
            }
                //div
            else if(opcode == 0x04) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, a / b);
                i = i + 1;
            }
                // callvalue
            else if(opcode == 0x34) {
                vector::push_back(stack, 0);
                i = i + 1;
            }
                //push0
            else if(opcode == 0x5f) {
                vector::push_back(stack, 0);
                i = i + 1;
            }
                // push1
            else if(opcode == 0x60)  {
                let number = *vector::borrow(&code, i + 1);
                vector::push_back(stack, (number as u256));
                i = i + 2;
            }
                // push2
            else if(opcode == 0x61)  {
                let number = dataToU256(code, ((i + 1) as u256), 2);
                vector::push_back(stack, number);
                i = i + 3;
            }
                // push3
            else if(opcode == 0x62)  {
                let number = dataToU256(code, ((i + 1) as u256), 3);
                vector::push_back(stack, number);
                i = i + 4;
            }
                // push4
            else if(opcode == 0x63)  {
                let number = dataToU256(code, ((i + 1) as u256), 4);
                vector::push_back(stack, number);
                i = i + 5;
            }
                // push5
            else if(opcode == 0x64)  {
                let number = dataToU256(code, ((i + 1) as u256), 5);
                vector::push_back(stack, number);
                i = i + 6;
            }
                // push32
            else if(opcode == 0x7f)  {
                let number = dataToU256(code, ((i + 1) as u256), 32);
                vector::push_back(stack, number);
                i = i + 33;
            }
                // pop
            else if(opcode == 0x50) {
                vector::pop_back(stack);
                i = i + 1
            }
                //calldataload
            else if(opcode == 0x35) {
                let pos = vector::pop_back(stack);
                vector::push_back(stack, dataToU256(data, pos, 32));
                i = i + 1;
            }
                //calldatasize
            else if(opcode == 0x36) {
                vector::push_back(stack, (vector::length(&data) as u256));
                i = i + 1;
            }
                // mload
            else if(opcode == 0x51) {
                let pos = vector::pop_back(stack);
                if(simple_map::contains_key(memory, &pos)) {
                    vector::push_back(stack, *simple_map::borrow(memory, &pos));
                } else {
                    vector::push_back(stack, 0);
                };
                i = i + 1;
            }
                // mstore
            else if(opcode == 0x52) {
                let pos = vector::pop_back(stack);
                let value = vector::pop_back(stack);
                simple_map::upsert(memory, pos, value);
                i = i + 1;

            }
                // sload
            else if(opcode == 0x54) {
                let pos = vector::pop_back(stack);
                if(simple_map::contains_key(&mut global.storage, &pos)) {
                    vector::push_back(stack, *simple_map::borrow(&mut global.storage, &pos));
                } else {
                    vector::push_back(stack, 0);
                };
                i = i + 1;
            }
                // sstore
            else if(opcode == 0x55) {
                let pos = vector::pop_back(stack);
                let value = vector::pop_back(stack);
                simple_map::upsert(&mut global.storage, pos, value);
                i = i + 1;
            }
                //dup1
            else if(opcode == 0x80) {
                let size = vector::length(stack);
                let value = *vector::borrow(stack, size - 1);
                vector::push_back(stack, value);
                i = i + 1;
            }
                //dup2
            else if(opcode == 0x81) {
                let size = vector::length(stack);
                let value = *vector::borrow(stack, size - 2);
                vector::push_back(stack, value);
                i = i + 1;
            }
                //dup3
            else if(opcode == 0x82) {
                let size = vector::length(stack);
                let value = *vector::borrow(stack, size - 3);
                vector::push_back(stack, value);

                i = i + 1;
            }
                //dup4
            else if(opcode == 0x83) {
                let size = vector::length(stack);
                let value = *vector::borrow(stack, size - 4);
                vector::push_back(stack, value);

                i = i + 1;
            }
                //dup5
            else if(opcode == 0x84) {
                let size = vector::length(stack);
                let value = *vector::borrow(stack, size - 5);
                vector::push_back(stack, value);
                i = i + 1;
            }
                //dup6
            else if(opcode == 0x85) {
                let size = vector::length(stack);
                let value = *vector::borrow(stack, size - 6);
                vector::push_back(stack, value);
                i = i + 1;
            }
                //dup7
            else if(opcode == 0x86) {
                let size = vector::length(stack);
                let value = *vector::borrow(stack, size - 7);
                vector::push_back(stack, value);
                i = i + 1;
            }
                //dup8
            else if(opcode == 0x87) {
                let size = vector::length(stack);
                let value = *vector::borrow(stack, size - 8);
                vector::push_back(stack, value);
                i = i + 1;
            }
                //dup9
            else if(opcode == 0x88) {
                let size = vector::length(stack);
                let value = *vector::borrow(stack, size - 9);
                vector::push_back(stack, value);
                i = i + 1;
            }
                //swap1
            else if(opcode == 0x90) {
                let size = vector::length(stack);
                vector::swap(stack, size - 1, size - 2);
                i = i + 1;
            }
                //swap2
            else if(opcode == 0x91) {
                let size = vector::length(stack);
                vector::swap(stack, size - 1, size - 3);
                i = i + 1;
            }
                //swap3
            else if(opcode == 0x92) {
                let size = vector::length(stack);
                vector::swap(stack, size - 1, size - 4);
                i = i + 1;
            }
                //swap4
            else if(opcode == 0x93) {
                let size = vector::length(stack);
                vector::swap(stack, size - 1, size - 5);
                i = i + 1;
            }
                //swap5
            else if(opcode == 0x94) {
                let size = vector::length(stack);
                vector::swap(stack, size - 1, size - 6);
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
                //slt
            else if(opcode == 0x12) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                if(a < b) {
                    vector::push_back(stack, 1)
                } else {
                    vector::push_back(stack, 0)
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
                vector::push_back(stack, a << (b as u8));
                i = i + 1;
            }
                //shr
            else if(opcode == 0x1c) {
                let b = vector::pop_back(stack);
                let a = vector::pop_back(stack);
                vector::push_back(stack, a >> (b as u8));
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
                //jump dest (no action, continue execution)
            else if(opcode == 0x5b) {
                i = i + 1
            }
                //sha3
            else if(opcode == 0x20) {
                let pos = vector::pop_back(stack);
                let offset = vector::pop_back(stack);
                let bytes = readBytes(memory, pos, pos + offset);
                let value = dataToU256(keccak256(bytes), 0, 32);
                vector::push_back(stack, value);
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
                while (d_pos < end) {
                    let bytes = slice(global.construct, d_pos, 32);
                    simple_map::upsert(memory, m_pos, dataToU256(bytes, 0, 32));
                    d_pos = d_pos + 32;
                    m_pos = m_pos + 32;
                };
                i = i + 1
            }
                //log3
            else if(opcode == 0xa3) {
                let pos = vector::pop_back(stack);
                let offset = vector::pop_back(stack);
                let data = readBytes(memory, pos, pos + offset);
                let topic0 = vector::pop_back(stack);
                let topic1 = vector::pop_back(stack);
                let topic2 = vector::pop_back(stack);
                event::emit_event<Log3Event>(
                    &mut global.log3Event,
                    Log3Event{
                        data,
                        topic0,
                        topic1,
                        topic2
                    },
                );
                i = i + 1
            }
            else {
                assert!(false, 1111);
            };
            // debug::print(stack);
        };
        move_ret
    }

    fun slice(data: vector<u8>, pos: u256, size: u256): vector<u8> {
        let s = vector::empty<u8>();
        let i = 0;
        while (i < size) {
            vector::push_back(&mut s, *vector::borrow(&data, (pos + i as u64)));
            i = i + 1;
        };
        s
    }

    fun readBytes(memory: &mut simple_map::SimpleMap<u256, u256>, pos: u256, end: u256): vector<u8> {
        let bytes = vector::empty<u8>();
        while(pos < end) {
            if(simple_map::contains_key(memory, &pos)) {
                let value = simple_map::borrow(memory, &pos);
                vector::append(&mut bytes, U256ToData(*value));
            }
            else {
                vector::append(&mut bytes, U256ToData(0));
            };
            pos = pos + 32;
        };

        bytes
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

    // #[test(admin = @0x123)]
    // fun testCounter() acquires T {
    //     let user = account::create_account_for_test(@demo);
    //     let construct = x"608060405234801561000f575f80fd5b5060de8061001c5f395ff3fe6080604052348015600e575f80fd5b50600436106030575f3560e01c806306661abd14603457806330f3f0db14604d575b5f80fd5b603b5f5481565b60405190815260200160405180910390f35b605c6058366004606e565b605e565b005b805f54606991906084565b5f5550565b5f60208284031215607d575f80fd5b5035919050565b8082018082111560a257634e487b7160e01b5f52601160045260245ffd5b9291505056fea264697066735822122020fee9e9a58815f53f03beb2e542711538b6d18b8131d9338035182b27f328e464736f6c63430008150033";
    //     let bytecode = x"6080604052348015600e575f80fd5b50600436106030575f3560e01c806306661abd14603457806330f3f0db14604d575b5f80fd5b603b5f5481565b60405190815260200160405180910390f35b605c6058366004606e565b605e565b005b805f54606991906084565b5f5550565b5f60208284031215607d575f80fd5b5035919050565b8082018082111560a257634e487b7160e01b5f52601160045260245ffd5b9291505056fea264697066735822122020fee9e9a58815f53f03beb2e542711538b6d18b8131d9338035182b27f328e464736f6c63430008150033";
    //     init_module(&user);
    //     initRuncode(&user, bytecode, construct);
    //
    //     call(x"30f3f0db000000000000000000000000000000000000000000000000000000000000000a");
    //     call(x"30f3f0db000000000000000000000000000000000000000000000000000000000000000a");
    //     let res = view(x"06661abd");
    //     debug::print(&res);
    // }

    #[test(admin = @0x123)]
    fun testERC20() acquires T {
        let user = account::create_account_for_test(@demo);
        let construct = x"60806040526005805460ff191660121790553480156200001d575f80fd5b5060405162000c6a38038062000c6a83398101604081905262000040916200013e565b8282600362000050838262000249565b5060046200005f828262000249565b50506005805460ff191660ff93909316929092179091555062000311915050565b634e487b7160e01b5f52604160045260245ffd5b5f82601f830112620000a4575f80fd5b81516001600160401b0380821115620000c157620000c162000080565b604051601f8301601f19908116603f01168101908282118183101715620000ec57620000ec62000080565b8160405283815260209250868385880101111562000108575f80fd5b5f91505b838210156200012b57858201830151818301840152908201906200010c565b5f93810190920192909252949350505050565b5f805f6060848603121562000151575f80fd5b83516001600160401b038082111562000168575f80fd5b620001768783880162000094565b945060208601519150808211156200018c575f80fd5b506200019b8682870162000094565b925050604084015160ff81168114620001b2575f80fd5b809150509250925092565b600181811c90821680620001d257607f821691505b602082108103620001f157634e487b7160e01b5f52602260045260245ffd5b50919050565b601f82111562000244575f81815260208120601f850160051c810160208610156200021f5750805b601f850160051c820191505b8181101562000240578281556001016200022b565b5050505b505050565b81516001600160401b0381111562000265576200026562000080565b6200027d81620002768454620001bd565b84620001f7565b602080601f831160018114620002b3575f84156200029b5750858301515b5f19600386901b1c1916600185901b17855562000240565b5f85815260208120601f198616915b82811015620002e357888601518255948401946001909101908401620002c2565b50858210156200030157878501515f19600388901b60f8161c191681555b5050505050600190811b01905550565b61094b806200031f5f395ff3fe608060405234801561000f575f80fd5b50600436106100cb575f3560e01c806340c10f1911610088578063a457c2d711610063578063a457c2d7146101a6578063a9059cbb146101b9578063ace28fa5146101cc578063dd62ed3e146101d9575f80fd5b806340c10f191461016157806370a082311461017657806395d89b411461019e575f80fd5b806306fdde03146100cf578063095ea7b3146100ed57806318160ddd1461011057806323b872dd14610122578063313ce56714610135578063395093511461014e575b5f80fd5b6100d76101ec565b6040516100e491906107a6565b60405180910390f35b6101006100fb36600461080c565b61027c565b60405190151581526020016100e4565b6002545b6040519081526020016100e4565b610100610130366004610834565b610295565b60055460ff165b60405160ff90911681526020016100e4565b61010061015c36600461080c565b6102b8565b61017461016f36600461080c565b6102d9565b005b61011461018436600461086d565b6001600160a01b03165f9081526020819052604090205490565b6100d76102e7565b6101006101b436600461080c565b6102f6565b6101006101c736600461080c565b610375565b60055461013c9060ff1681565b6101146101e736600461088d565b610382565b6060600380546101fb906108be565b80601f0160208091040260200160405190810160405280929190818152602001828054610227906108be565b80156102725780601f1061024957610100808354040283529160200191610272565b820191905f5260205f20905b81548152906001019060200180831161025557829003601f168201915b5050505050905090565b5f336102898185856103ac565b60019150505b92915050565b5f336102a28582856104cf565b6102ad858585610547565b506001949350505050565b5f336102898185856102ca8383610382565b6102d491906108f6565b6103ac565b6102e382826106e9565b5050565b6060600480546101fb906108be565b5f33816103038286610382565b9050838110156103685760405162461bcd60e51b815260206004820152602560248201527f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f77604482015264207a65726f60d81b60648201526084015b60405180910390fd5b6102ad82868684036103ac565b5f33610289818585610547565b6001600160a01b039182165f90815260016020908152604080832093909416825291909152205490565b6001600160a01b03831661040e5760405162461bcd60e51b8152602060048201526024808201527f45524332303a20617070726f76652066726f6d20746865207a65726f206164646044820152637265737360e01b606482015260840161035f565b6001600160a01b03821661046f5760405162461bcd60e51b815260206004820152602260248201527f45524332303a20617070726f766520746f20746865207a65726f206164647265604482015261737360f01b606482015260840161035f565b6001600160a01b038381165f8181526001602090815260408083209487168084529482529182902085905590518481527f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925910160405180910390a3505050565b5f6104da8484610382565b90505f19811461054157818110156105345760405162461bcd60e51b815260206004820152601d60248201527f45524332303a20696e73756666696369656e7420616c6c6f77616e6365000000604482015260640161035f565b61054184848484036103ac565b50505050565b6001600160a01b0383166105ab5760405162461bcd60e51b815260206004820152602560248201527f45524332303a207472616e736665722066726f6d20746865207a65726f206164604482015264647265737360d81b606482015260840161035f565b6001600160a01b03821661060d5760405162461bcd60e51b815260206004820152602360248201527f45524332303a207472616e7366657220746f20746865207a65726f206164647260448201526265737360e81b606482015260840161035f565b6001600160a01b0383165f90815260208190526040902054818110156106845760405162461bcd60e51b815260206004820152602660248201527f45524332303a207472616e7366657220616d6f756e7420657863656564732062604482015265616c616e636560d01b606482015260840161035f565b6001600160a01b038481165f81815260208181526040808320878703905593871680835291849020805487019055925185815290927fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef910160405180910390a3610541565b6001600160a01b03821661073f5760405162461bcd60e51b815260206004820152601f60248201527f45524332303a206d696e7420746f20746865207a65726f206164647265737300604482015260640161035f565b8060025f82825461075091906108f6565b90915550506001600160a01b0382165f81815260208181526040808320805486019055518481527fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef910160405180910390a35050565b5f6020808352835180828501525f5b818110156107d1578581018301518582016040015282016107b5565b505f604082860101526040601f19601f8301168501019250505092915050565b80356001600160a01b0381168114610807575f80fd5b919050565b5f806040838503121561081d575f80fd5b610826836107f1565b946020939093013593505050565b5f805f60608486031215610846575f80fd5b61084f846107f1565b925061085d602085016107f1565b9150604084013590509250925092565b5f6020828403121561087d575f80fd5b610886826107f1565b9392505050565b5f806040838503121561089e575f80fd5b6108a7836107f1565b91506108b5602084016107f1565b90509250929050565b600181811c908216806108d257607f821691505b6020821081036108f057634e487b7160e01b5f52602260045260245ffd5b50919050565b8082018082111561028f57634e487b7160e01b5f52601160045260245ffdfea2646970667358221220a6d822ba29fb8310dc1aa94585bb37b546b3f28c10c4154952d71f49fb0d992264736f6c63430008150033000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000004555344430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045553444300000000000000000000000000000000000000000000000000000000";
        let bytecode = x"608060405234801561000f575f80fd5b50600436106100cb575f3560e01c806340c10f1911610088578063a457c2d711610063578063a457c2d7146101a6578063a9059cbb146101b9578063ace28fa5146101cc578063dd62ed3e146101d9575f80fd5b806340c10f191461016157806370a082311461017657806395d89b411461019e575f80fd5b806306fdde03146100cf578063095ea7b3146100ed57806318160ddd1461011057806323b872dd14610122578063313ce56714610135578063395093511461014e575b5f80fd5b6100d76101ec565b6040516100e491906107a6565b60405180910390f35b6101006100fb36600461080c565b61027c565b60405190151581526020016100e4565b6002545b6040519081526020016100e4565b610100610130366004610834565b610295565b60055460ff165b60405160ff90911681526020016100e4565b61010061015c36600461080c565b6102b8565b61017461016f36600461080c565b6102d9565b005b61011461018436600461086d565b6001600160a01b03165f9081526020819052604090205490565b6100d76102e7565b6101006101b436600461080c565b6102f6565b6101006101c736600461080c565b610375565b60055461013c9060ff1681565b6101146101e736600461088d565b610382565b6060600380546101fb906108be565b80601f0160208091040260200160405190810160405280929190818152602001828054610227906108be565b80156102725780601f1061024957610100808354040283529160200191610272565b820191905f5260205f20905b81548152906001019060200180831161025557829003601f168201915b5050505050905090565b5f336102898185856103ac565b60019150505b92915050565b5f336102a28582856104cf565b6102ad858585610547565b506001949350505050565b5f336102898185856102ca8383610382565b6102d491906108f6565b6103ac565b6102e382826106e9565b5050565b6060600480546101fb906108be565b5f33816103038286610382565b9050838110156103685760405162461bcd60e51b815260206004820152602560248201527f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f77604482015264207a65726f60d81b60648201526084015b60405180910390fd5b6102ad82868684036103ac565b5f33610289818585610547565b6001600160a01b039182165f90815260016020908152604080832093909416825291909152205490565b6001600160a01b03831661040e5760405162461bcd60e51b8152602060048201526024808201527f45524332303a20617070726f76652066726f6d20746865207a65726f206164646044820152637265737360e01b606482015260840161035f565b6001600160a01b03821661046f5760405162461bcd60e51b815260206004820152602260248201527f45524332303a20617070726f766520746f20746865207a65726f206164647265604482015261737360f01b606482015260840161035f565b6001600160a01b038381165f8181526001602090815260408083209487168084529482529182902085905590518481527f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925910160405180910390a3505050565b5f6104da8484610382565b90505f19811461054157818110156105345760405162461bcd60e51b815260206004820152601d60248201527f45524332303a20696e73756666696369656e7420616c6c6f77616e6365000000604482015260640161035f565b61054184848484036103ac565b50505050565b6001600160a01b0383166105ab5760405162461bcd60e51b815260206004820152602560248201527f45524332303a207472616e736665722066726f6d20746865207a65726f206164604482015264647265737360d81b606482015260840161035f565b6001600160a01b03821661060d5760405162461bcd60e51b815260206004820152602360248201527f45524332303a207472616e7366657220746f20746865207a65726f206164647260448201526265737360e81b606482015260840161035f565b6001600160a01b0383165f90815260208190526040902054818110156106845760405162461bcd60e51b815260206004820152602660248201527f45524332303a207472616e7366657220616d6f756e7420657863656564732062604482015265616c616e636560d01b606482015260840161035f565b6001600160a01b038481165f81815260208181526040808320878703905593871680835291849020805487019055925185815290927fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef910160405180910390a3610541565b6001600160a01b03821661073f5760405162461bcd60e51b815260206004820152601f60248201527f45524332303a206d696e7420746f20746865207a65726f206164647265737300604482015260640161035f565b8060025f82825461075091906108f6565b90915550506001600160a01b0382165f81815260208181526040808320805486019055518481527fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef910160405180910390a35050565b5f6020808352835180828501525f5b818110156107d1578581018301518582016040015282016107b5565b505f604082860101526040601f19601f8301168501019250505092915050565b80356001600160a01b0381168114610807575f80fd5b919050565b5f806040838503121561081d575f80fd5b610826836107f1565b946020939093013593505050565b5f805f60608486031215610846575f80fd5b61084f846107f1565b925061085d602085016107f1565b9150604084013590509250925092565b5f6020828403121561087d575f80fd5b610886826107f1565b9392505050565b5f806040838503121561089e575f80fd5b6108a7836107f1565b91506108b5602084016107f1565b90509250929050565b600181811c908216806108d257607f821691505b6020821081036108f057634e487b7160e01b5f52602260045260245ffd5b50919050565b8082018082111561028f57634e487b7160e01b5f52601160045260245ffdfea2646970667358221220d7549521aaf644d675c91eae2e52c085ce91172884c9ca9058be9160633a935664736f6c63430008150033";
        init_module(&user);
        init_runcode(&user, bytecode, construct);

        debug::print(&view(x"06fdde03"));
        // call(x"40c10f19000000000000000000000000892a2b7cf919760e148a0d33c1eb0f44d3b383f80000000000000000000000000000000000000000000000000000000000000064");
    }
}

module demo::ERC20Mock {
    use std::vector;
    use std::signer;
    use aptos_std::simple_map;
    use aptos_std::simple_map::SimpleMap;
    use std::string::utf8;
    use aptos_framework::account;
    use aptos_std::debug;
    use aptos_std::aptos_hash::keccak256;
    use aptos_framework::event::EventHandle;
    use aptos_framework::account::new_event_handle;
    use aptos_framework::event;
    use aptos_framework::timestamp::now_microseconds;

    const INVALID_CALLER: u64 = 1;
    const INVALID_SENDER: u64 = 1;

    const CONTRACT_DEPLOYED: u64 = 100;
    const CONTRACT_READ_ONLY: u64 = 101;
    const CALL_CONTRACT_NOT_EXIST: u64 = 102;
    const U256_MAX: u256 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    const ZERO_BYTES: vector<u8> = x"0000000000000000000000000000000000000000000000000000000000000000";
    const INIT_CODE: vector<u8> = x"60806040526005805460ff191660121790553480156200001e57600080fd5b5060405162000ca738038062000ca7833981016040819052620000419162000146565b828260036200005183826200025a565b5060046200006082826200025a565b50506005805460ff191660ff93909316929092179091555062000326915050565b634e487b7160e01b600052604160045260246000fd5b600082601f830112620000a957600080fd5b81516001600160401b0380821115620000c657620000c662000081565b604051601f8301601f19908116603f01168101908282118183101715620000f157620000f162000081565b816040528381526020925086838588010111156200010e57600080fd5b600091505b8382101562000132578582018301518183018401529082019062000113565b600093810190920192909252949350505050565b6000806000606084860312156200015c57600080fd5b83516001600160401b03808211156200017457600080fd5b620001828783880162000097565b945060208601519150808211156200019957600080fd5b50620001a88682870162000097565b925050604084015160ff81168114620001c057600080fd5b809150509250925092565b600181811c90821680620001e057607f821691505b6020821081036200020157634e487b7160e01b600052602260045260246000fd5b50919050565b601f8211156200025557600081815260208120601f850160051c81016020861015620002305750805b601f850160051c820191505b8181101562000251578281556001016200023c565b5050505b505050565b81516001600160401b0381111562000276576200027662000081565b6200028e81620002878454620001cb565b8462000207565b602080601f831160018114620002c65760008415620002ad5750858301515b600019600386901b1c1916600185901b17855562000251565b600085815260208120601f198616915b82811015620002f757888601518255948401946001909101908401620002d6565b5085821015620003165787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b61097180620003366000396000f3fe608060405234801561001057600080fd5b50600436106100cf5760003560e01c806340c10f191161008c578063a457c2d711610066578063a457c2d7146101ac578063a9059cbb146101bf578063ace28fa5146101d2578063dd62ed3e146101df57600080fd5b806340c10f191461016657806370a082311461017b57806395d89b41146101a457600080fd5b806306fdde03146100d4578063095ea7b3146100f257806318160ddd1461011557806323b872dd14610127578063313ce5671461013a5780633950935114610153575b600080fd5b6100dc6101f2565b6040516100e991906107bb565b60405180910390f35b610105610100366004610825565b610284565b60405190151581526020016100e9565b6002545b6040519081526020016100e9565b61010561013536600461084f565b61029e565b60055460ff165b60405160ff90911681526020016100e9565b610105610161366004610825565b6102c2565b610179610174366004610825565b6102e4565b005b61011961018936600461088b565b6001600160a01b031660009081526020819052604090205490565b6100dc6102f2565b6101056101ba366004610825565b610301565b6101056101cd366004610825565b610381565b6005546101419060ff1681565b6101196101ed3660046108ad565b61038f565b606060038054610201906108e0565b80601f016020809104026020016040519081016040528092919081815260200182805461022d906108e0565b801561027a5780601f1061024f5761010080835404028352916020019161027a565b820191906000526020600020905b81548152906001019060200180831161025d57829003601f168201915b5050505050905090565b6000336102928185856103ba565b60019150505b92915050565b6000336102ac8582856104de565b6102b7858585610558565b506001949350505050565b6000336102928185856102d5838361038f565b6102df919061091a565b6103ba565b6102ee82826106fc565b5050565b606060048054610201906108e0565b6000338161030f828661038f565b9050838110156103745760405162461bcd60e51b815260206004820152602560248201527f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f77604482015264207a65726f60d81b60648201526084015b60405180910390fd5b6102b782868684036103ba565b600033610292818585610558565b6001600160a01b03918216600090815260016020908152604080832093909416825291909152205490565b6001600160a01b03831661041c5760405162461bcd60e51b8152602060048201526024808201527f45524332303a20617070726f76652066726f6d20746865207a65726f206164646044820152637265737360e01b606482015260840161036b565b6001600160a01b03821661047d5760405162461bcd60e51b815260206004820152602260248201527f45524332303a20617070726f766520746f20746865207a65726f206164647265604482015261737360f01b606482015260840161036b565b6001600160a01b0383811660008181526001602090815260408083209487168084529482529182902085905590518481527f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925910160405180910390a3505050565b60006104ea848461038f565b9050600019811461055257818110156105455760405162461bcd60e51b815260206004820152601d60248201527f45524332303a20696e73756666696369656e7420616c6c6f77616e6365000000604482015260640161036b565b61055284848484036103ba565b50505050565b6001600160a01b0383166105bc5760405162461bcd60e51b815260206004820152602560248201527f45524332303a207472616e736665722066726f6d20746865207a65726f206164604482015264647265737360d81b606482015260840161036b565b6001600160a01b03821661061e5760405162461bcd60e51b815260206004820152602360248201527f45524332303a207472616e7366657220746f20746865207a65726f206164647260448201526265737360e81b606482015260840161036b565b6001600160a01b038316600090815260208190526040902054818110156106965760405162461bcd60e51b815260206004820152602660248201527f45524332303a207472616e7366657220616d6f756e7420657863656564732062604482015265616c616e636560d01b606482015260840161036b565b6001600160a01b03848116600081815260208181526040808320878703905593871680835291849020805487019055925185815290927fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef910160405180910390a3610552565b6001600160a01b0382166107525760405162461bcd60e51b815260206004820152601f60248201527f45524332303a206d696e7420746f20746865207a65726f206164647265737300604482015260640161036b565b8060026000828254610764919061091a565b90915550506001600160a01b038216600081815260208181526040808320805486019055518481527fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef910160405180910390a35050565b600060208083528351808285015260005b818110156107e8578581018301518582016040015282016107cc565b506000604082860101526040601f19601f8301168501019250505092915050565b80356001600160a01b038116811461082057600080fd5b919050565b6000806040838503121561083857600080fd5b61084183610809565b946020939093013593505050565b60008060006060848603121561086457600080fd5b61086d84610809565b925061087b60208501610809565b9150604084013590509250925092565b60006020828403121561089d57600080fd5b6108a682610809565b9392505050565b600080604083850312156108c057600080fd5b6108c983610809565b91506108d760208401610809565b90509250929050565b600181811c908216806108f457607f821691505b60208210810361091457634e487b7160e01b600052602260045260246000fd5b50919050565b8082018082111561029857634e487b7160e01b600052601160045260246000fdfea264697066735822122085eff32723bcb76041d78f7a5e898b2a59ca3931a236ea2e3d6ed9c2ea4afb3264736f6c63430008110033000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000004555344430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045553444300000000000000000000000000000000000000000000000000000000";
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
        runtime: vector<u8>
    }

    struct S has key {
        contracts: simple_map::SimpleMap<vector<u8>, T>,
        log1Event: EventHandle<Log1Event>,
        log2Event: EventHandle<Log2Event>,
        log3Event: EventHandle<Log3Event>
    }

    entry fun init_module(account: &signer) {
        move_to(account, S {
            contracts: simple_map::create<vector<u8>, T>(),
            log1Event: new_event_handle<Log1Event>(account),
            log2Event: new_event_handle<Log2Event>(account),
            log3Event: new_event_handle<Log3Event>(account)
        });
    }

    public entry fun deploy(account: &signer, sender: vector<u8>, nonce: u256, value: u256) acquires S {
        assert!(signer::address_of(account) == @demo, INVALID_CALLER);
        create(sender, nonce, INIT_CODE, value);
    }


    fun create(sender: vector<u8>, nonce: u256, construct: vector<u8>, value: u256): vector<u8> acquires S {
        let global = borrow_global_mut<S>(@demo);

        let bytes = copy sender;
        vector::append(&mut bytes, u256_to_data(nonce));
        let contract_addr = to_32bit(slice(keccak256(bytes), 12, 20));
        assert!(!simple_map::contains_key(&global.contracts, &contract_addr), CONTRACT_DEPLOYED);
        simple_map::add(&mut global.contracts, contract_addr, T {
            storage: simple_map::create<u256, vector<u8>>(),
            runtime: x""
        });

        let runtime = run(global, sender, contract_addr, construct, x"", false, value);
        simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &contract_addr).runtime = runtime;
        contract_addr
    }

    public fun call(_account: &signer, sender: vector<u8>, contract_addr: vector<u8>, data: vector<u8>, value: u256) acquires S {
        let global = borrow_global_mut<S>(@demo);
        assert!(vector::length(&sender) == 32, INVALID_SENDER);
        if(simple_map::contains_key(&global.contracts, &contract_addr)) {
            let contract = simple_map::borrow<vector<u8>, T>(&global.contracts, &contract_addr);
            run(global, sender, copy contract_addr, contract.runtime, data, false, value);
        };
    }

    #[view]
    public fun view(sender:vector<u8>, contract_addr: vector<u8>, data: vector<u8>): vector<u8> acquires S {
        let global = borrow_global_mut<S>(@demo);
        let contract = simple_map::borrow<vector<u8>, T>(&global.contracts, &contract_addr);
        run(global, sender, copy contract_addr, contract.runtime, data, true, 0)
    }

    fun run(global: &mut S, sender: vector<u8>, contract_addr: vector<u8>, code: vector<u8>, data: vector<u8>, readOnly: bool, value: u256): vector<u8> {
        let stack = &mut vector::empty<u256>();
        let move_ret = vector::empty<u8>();
        let memory = &mut vector::empty<u8>();
        let storage = simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &contract_addr).storage;
        let len = vector::length(&code);
        let runtime_code = vector::empty<u8>();
        let i = 0;
        let ret_size = 0;

        while (i < len) {
            let opcode = *vector::borrow(&code, i);
            // debug::print(&i);
            // debug::print(&opcode);
            // stop
            if(opcode == 0x00) {
                move_ret = runtime_code;
                break
            }
            else if(opcode == 0xf3) {
                let pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                // move_ret = read_bytes(*memory, pos, end);
                move_ret = slice(*memory, pos, len);
                break
            }
                //add
            else if(opcode == 0x01) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                if(a > 0 && b > (U256_MAX - a + 1)) {
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
                //div
            else if(opcode == 0x04) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, a / b);
                i = i + 1;
            }
                //exp
            else if(opcode == 0x0a) {
                let a = vector::pop_back(stack);
                let b = vector::pop_back(stack);
                vector::push_back(stack, power(a, b));
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
                //EXTCODESIZE
            else if(opcode == 0x3b) {
                let addr = to_32bit(u256_to_data(vector::pop_back(stack)));
                // debug::print(&addr);
                if(simple_map::contains_key(&mut global.contracts, &addr)) {
                    let code = simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &addr).runtime;
                    vector::push_back(stack, (vector::length(&code) as u256));
                } else {
                    assert!(false, 999);
                    vector::push_back(stack, 0);
                };

                i = i + 1;
            }
                //RETURNDATASIZE
            else if(opcode == 0x3d) {
                // debug::print(&utf8(b"data size"));
                // debug::print(&ret_size);
                vector::push_back(stack, ret_size);
                i = i + 1;
            }
            else if(opcode == 0x42) {
                vector::push_back(stack, (now_microseconds() as u256) / 1000000);
                i = i + 1;
            }
                //chainid
            else if(opcode == 0x46) {
                vector::push_back(stack, 1);
                i = i + 1
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
                // debug::print(&offset);
                // debug::print(&bytes);
                let value = data_to_u256(keccak256(bytes), 0, 32);
                vector::push_back(stack, value);
                i = i + 1
            }
                //call 0xf1 static call 0xfa
            else if(opcode == 0xf1 || opcode == 0xfa) {
                let readOnly = if(opcode == 0xf1) false else true;
                let _gas = vector::pop_back(stack);
                let dest_addr = to_32bit(u256_to_data(vector::pop_back(stack)));
                let msg_value = if(opcode == 0xf1) vector::pop_back(stack) else 0;
                let m_pos = vector::pop_back(stack);
                let m_len = vector::pop_back(stack);
                let ret_pos = vector::pop_back(stack);
                let ret_len = vector::pop_back(stack);
                if(simple_map::contains_key(&global.contracts, &dest_addr)) {
                    ret_size = ret_len;
                    let ret_end = ret_len + ret_pos;
                    let params = slice(*memory, m_pos, m_len);
                    let runtime = simple_map::borrow(&mut global.contracts, &dest_addr).runtime;
                    let ret_bytes = run(global, copy contract_addr, dest_addr, runtime, params, readOnly, msg_value);
                    let index = 0;
                    while (ret_pos < ret_end) {
                        let bytes = if(ret_end - ret_pos >= 32) {
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
                    if(opcode == 0xfa) {
                        vector::push_back(stack, 0);
                    } else {
                        assert!(false, CALL_CONTRACT_NOT_EXIST);
                    }

                };
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
                    runtime: x""
                });
                // debug::print(&utf8(b"create2 start"));
                // debug::print(&p);
                // debug::print(&contract_addr);
                // debug::print(&new_contract_addr);
                let runtime = run(global, copy contract_addr, new_contract_addr, new_codes, x"", false, msg_value);
                // debug::print(&utf8(b"create2 end"));
                simple_map::borrow_mut<vector<u8>, T>(&mut global.contracts, &new_contract_addr).runtime = runtime;
                vector::push_back(stack, data_to_u256(new_contract_addr,0, 32));
                i = i + 1
            }
                //revert
            else if(opcode == 0xfd) {
                let pos = vector::pop_back(stack);
                let len = vector::pop_back(stack);
                debug::print(&slice(*memory, pos, len));
                assert!(false, (opcode as u64));
                i = i + 1
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
        move_ret
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
        }
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
}

module demo::evmstorage {
    use aptos_std::simple_map;
    use demo::util::{checkCaller};

    const INSUFFICIENT_BALANCE: u64 = 101;
    const INVALID_NONCE: u64 = 102;
    const INSUFFICIENT_TRANSFER_BALANCE: u64 = 103;

    struct R has key {
        accounts: simple_map::SimpleMap<vector<u8>, Account>,
        total_fee: u256
    }

    struct Account has key, store {
        nonce: u256,
        addr: vector<u8>,
        balance: u256,
        is_contract: bool
    }

    entry fun init_module(account: &signer) {
        move_to(account, R {
            accounts: simple_map::create<vector<u8>, Account>(),
            total_fee: 0
        });
    }

    public fun createAccount(addr: vector<u8>, is_contract: bool) acquires R {
        let global = borrow_global_mut<R>(@demo);
        if (!simple_map::contains_key(&global.accounts, &addr)) {
            simple_map::add(&mut global.accounts, addr, Account {
                nonce: 0,
                addr,
                balance: 0,
                is_contract
            })
        };
    }

    public fun update(account: &signer, from: vector<u8>, to: vector<u8>, nonce:u256, value: u256, gas_fee: u256) acquires R {
        checkCaller(account);
        let global = borrow_global_mut<R>(@demo);
        global.total_fee = global.total_fee + gas_fee;
        let to_account = simple_map::borrow_mut(&mut global.accounts, &to);
        to_account.balance = to_account.balance + value;

        let from_account = simple_map::borrow_mut(&mut global.accounts, &from);
        assert!(from_account.balance >= value + gas_fee, INSUFFICIENT_BALANCE);
        assert!(from_account.nonce == nonce, INVALID_NONCE);

        from_account.balance = from_account.balance - gas_fee;
        from_account.nonce = from_account.nonce + 1;
    }

    public fun transfer(from: vector<u8>, to: vector<u8>, amount: u256) acquires R {
        if(amount > 0) {
            let global = borrow_global_mut<R>(@demo);
            let from_account = simple_map::borrow_mut(&mut global.accounts, &from);
            assert!(from_account.balance >= amount, INSUFFICIENT_TRANSFER_BALANCE);
            from_account.balance = from_account.balance - amount;

            let to_account = simple_map::borrow_mut(&mut global.accounts, &to);
            to_account.balance = to_account.balance + amount;
        }
    }

    public fun addBalance(_signer: &signer, to: vector<u8>, amount: u256) acquires R {
        createAccount(to, false);
        let account = simple_map::borrow_mut(&mut borrow_global_mut<R>(@demo).accounts, &to);
        account.balance = account.balance + amount;
    }

    public fun subBalance(signer: &signer, from: vector<u8>, amount: u256, gas: u256) acquires R {
        checkCaller(signer);
        let account = simple_map::borrow_mut(&mut borrow_global_mut<R>(@demo).accounts, &from);
        assert!(account.balance >= amount + gas, INSUFFICIENT_BALANCE);
        account.balance = account.balance - amount - gas;
    }

    #[view]
    public fun getAccount(addr: vector<u8>): (u256, u256) acquires R {
        if(simple_map::contains_key(&borrow_global<R>(@demo).accounts, &addr)) {
            let account = simple_map::borrow(&borrow_global<R>(@demo).accounts, &addr);
            (account.balance, account.nonce)
        } else {
            (0, 0)
        }
    }

    #[test_only]
    public fun init_module_for_test(account: &signer) {
        init_module(account);
    }
}

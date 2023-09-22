module demo::evmtx {
    use aptos_std::simple_map;
    use demo::evmcontract;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use demo::evmcontract::call;

    #[test_only]
    use aptos_framework::account;
    use std::string;
    use std::signer;
    use std::vector;
    use aptos_std::debug;
    use std::string::utf8;

    const INSUFFICIENT_BALANCE: u64 = 1;
    const INVALID_SIGNER: u64 = 2;
    const INVALID_NONCE: u64 = 3;

    const ZERO_ADDR: vector<u8> = x"0000000000000000000000000000000000000000000000000000000000000000";

    struct Account has key, store {
        nonce: u256,
        addr: vector<u8>,
        balance: u256,
        is_contract: bool
    }

    struct TX has key, store {
        from: vector<u8>,
        to: vector<u8>,
        nonce: u256,
        gas_fee: u256,
        contractAddress: vector<u8>,
        type: u64
    }

    struct R has key {
        txs: simple_map::SimpleMap<vector<u8>, TX>,
        accounts: simple_map::SimpleMap<vector<u8>, Account>,
        total_fee: u256
    }

    entry fun init_module(account: &signer) {
        move_to(account, R {
            txs: simple_map::create<vector<u8>, TX>(),
            accounts: simple_map::create<vector<u8>, Account>(),
            total_fee: 0
        });
    }

    public entry fun sendTx(
        account: &signer,
        value: u256,
        tx_hash: vector<u8>,
        from: vector<u8>,
        to: vector<u8>,
        nonce: u256,
        data: vector<u8>,
        gas_fee: u256
    ) acquires R {
        assert!(signer::address_of(account) == @signer, INVALID_SIGNER);
        let global = borrow_global_mut<R>(@demo);
        coin::transfer<AptosCoin>(account, @demo, (gas_fee as u64));

        let deploy_contract = if (to == ZERO_ADDR) true else false;
        createAccount(global, from, false);


        if (deploy_contract) {
            let contract_addr = evmcontract::deploy(account, from, nonce, data, value);
            createAccount(global, contract_addr, true);
            to = contract_addr;
        } else {
            createAccount(global, to, false);
            call(account, from, to, data, value);
        };

        let is_contract = simple_map::borrow_mut(&mut global.accounts, &to).is_contract;
        simple_map::add(&mut global.txs, tx_hash, TX {
            from,
            to,
            nonce,
            gas_fee,
            contractAddress: if (is_contract) to else x"",
            type: 0
        });

        global.total_fee = global.total_fee + gas_fee;
        update_from(global, from, nonce, value, gas_fee);
        update_to(global, to, value);
    }

    fun update_to(global: &mut R, to: vector<u8>, value: u256) {
        let to_account = simple_map::borrow_mut(&mut global.accounts, &to);
        to_account.balance = to_account.balance + value;
    }

    fun update_from(global: &mut R, from: vector<u8>, nonce: u256, value: u256, gas_fee: u256) {
        let from_account = simple_map::borrow_mut(&mut global.accounts, &from);
        assert!(from_account.balance >= value + gas_fee, INSUFFICIENT_BALANCE);
        assert!(from_account.nonce == nonce, INVALID_NONCE);

        from_account.balance = from_account.balance - value - gas_fee;
        from_account.nonce = from_account.nonce + 1;
    }

    #[view]
    public fun query(from: vector<u8>, to: vector<u8>, data: vector<u8>): vector<u8> {
        evmcontract::view(from, to, data)
    }

    public entry fun deposit(account: &signer, amount: u256, to: vector<u8>) acquires R {
        let global = borrow_global_mut<R>(@demo);
        coin::transfer<AptosCoin>(account, @demo, (amount as u64));
        createAccount(global, to, false);
        let account = simple_map::borrow_mut(&mut borrow_global_mut<R>(@demo).accounts, &to);
        account.balance = account.balance + amount;
    }

    fun createAccount(global: &mut R, addr: vector<u8>, is_contract: bool) {
        if (!simple_map::contains_key(&global.accounts, &addr)) {
            simple_map::add(&mut global.accounts, addr, Account {
                nonce: 0,
                addr,
                balance: 0,
                is_contract
            })
        };
    }

    #[test_only]
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

    #[test(admin = @demo)]
    fun test() acquires R {
        let aptos = account::create_account_for_test(@0x1);
        let caller = account::create_account_for_test(@signer);
        let evm = account::create_account_for_test(@demo);
        init_module(&evm);
        evmcontract::init_module_for_test(&evm);
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<AptosCoin>(
            &aptos,
            string::utf8(b"APT"),
            string::utf8(b"APT"),
            8,
            false,
        );
        coin::register<AptosCoin>(&caller);
        coin::register<AptosCoin>(&evm);

        let coins = coin::mint<AptosCoin>(1000000000000, &mint_cap);
        coin::deposit(signer::address_of(&caller), coins);
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_freeze_cap(freeze_cap);
        coin::destroy_burn_cap(burn_cap);

        //test deposit
        let alice = to_32bit(x"892a2b7cF919760e148A0d33C1eb0f44D3b383f8");
        let bob = to_32bit(x"2D83750BDB3139eed1F76952dB472A512685E3e0");
        deposit(&caller, 10000000000, alice);
        debug::print(&borrow_global<R>(@demo).accounts);
        let tx1_hash = x"0000000000000000000000000000000000000000000000000000000000000001";
        debug::print(&utf8(b"alice transfer 1 apt to bob"));
        sendTx(&caller, 100000000, tx1_hash, alice, bob, 0, x"", 10000);
        debug::print(&borrow_global<R>(@demo).accounts);

        debug::print(&utf8(b"alice deploy a single contract"));
        let tx2_hash = x"0000000000000000000000000000000000000000000000000000000000000002";
        let data = x"6080604052348015600e575f80fd5b5060a58061001b5f395ff3fe6080604052348015600e575f80fd5b50600436106030575f3560e01c80632e64cec11460345780636057361d146048575b5f80fd5b5f5460405190815260200160405180910390f35b605760533660046059565b5f55565b005b5f602082840312156068575f80fd5b503591905056fea26469706673582212206a98897a49d701ccfc0a55b6148c8005628cdbc6cfbe2fddb9a8357f498d15e764736f6c63430008150033";
        sendTx(&caller, 0, tx2_hash, alice, ZERO_ADDR, 1, data, 100000);

        debug::print(&borrow_global<R>(@demo).accounts);
    }
}
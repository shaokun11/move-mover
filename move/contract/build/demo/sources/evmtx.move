module demo::evmtx {
    use demo::evmcontract;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use demo::evmcontract::call;
    use demo::evmstorage::{createAccount, update, addBalance};

    #[test_only]
    use aptos_framework::account;
    use std::string;
    use std::vector;
    use aptos_std::debug;
    use std::string::utf8;
    #[test_only]
    use demo::evmstorage;
    use demo::util::checkCaller;
    #[test_only]
    use std::signer;


    const INSUFFICIENT_BALANCE: u64 = 1;
    const INVALID_SIGNER: u64 = 2;
    const INVALID_NONCE: u64 = 3;

    const ZERO_ADDR: vector<u8> = x"0000000000000000000000000000000000000000000000000000000000000000";

    public entry fun sendTx(
        account: &signer,
        value: u256,
        from: vector<u8>,
        to: vector<u8>,
        nonce: u256,
        data: vector<u8>,
        gas_fee: u256
    ) {
        checkCaller(account);
        coin::transfer<AptosCoin>(account, @demo, (gas_fee as u64));

        let deploy_contract = if (to == ZERO_ADDR) true else false;
        createAccount(from, false);

        if (deploy_contract) {
            let contract_addr = evmcontract::deploy(account, from, nonce, data, value);
            createAccount(contract_addr, true);
            to = contract_addr;
        } else {
            createAccount(to, false);
            call(account, from, to, data, value);
        };

        update(account, from, to, nonce, value, gas_fee);
    }



    #[view]
    public fun query(from: vector<u8>, to: vector<u8>, data: vector<u8>): vector<u8> {
        evmcontract::view(from, to, data)
    }

    public entry fun deposit(account: &signer, amount: u256, to: vector<u8>) {
        coin::transfer<AptosCoin>(account, @demo, (amount as u64));
        addBalance(account, to, amount);
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
    fun test() {
        let aptos = account::create_account_for_test(@0x1);
        let caller = account::create_account_for_test(@signer);
        let evm = account::create_account_for_test(@demo);

        evmstorage::init_module_for_test(&evm);
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
        // debug::print(&borrow_global<R>(@demo).accounts);
        debug::print(&utf8(b"alice transfer 1 apt to bob"));
        sendTx(&caller, 100000000, alice, bob, 0, x"", 10000);
        // debug::print(&borrow_global<R>(@demo).accounts);

        debug::print(&utf8(b"alice deploy a single contract"));
        let data = x"6080604052348015600e575f80fd5b5060a58061001b5f395ff3fe6080604052348015600e575f80fd5b50600436106030575f3560e01c80632e64cec11460345780636057361d146048575b5f80fd5b5f5460405190815260200160405180910390f35b605760533660046059565b5f55565b005b5f602082840312156068575f80fd5b503591905056fea26469706673582212206a98897a49d701ccfc0a55b6148c8005628cdbc6cfbe2fddb9a8357f498d15e764736f6c63430008150033";
        sendTx(&caller, 0, alice, ZERO_ADDR, 1, data, 100000);

        // debug::print(&borrow_global<R>(@demo).accounts);
    }
}
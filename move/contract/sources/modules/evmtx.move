module demo::evmtx {
    use demo::evm;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use demo::evm::call;
    use demo::evmstorage::{createAccount, update, addBalance};

    // #[test_only]
    // use aptos_framework::account;
    // use std::string;
    use std::vector;
    // use aptos_std::debug;
    // use std::string::utf8;
    // #[test_only]
    // use demo::evmstorage;
    use demo::util::checkCaller;
    #[test_only]
    use aptos_framework::account;
    #[test_only]
    use demo::evmstorage;
    #[test_only]
    use std::string;
    #[test_only]
    use std::signer;
    #[test_only]
    use aptos_std::debug;
    #[test_only]
    use std::string::utf8;
    #[test_only]
    use aptos_framework::timestamp::set_time_has_started_for_testing;

    // use aptos_framework::transaction_context;
    // use aptos_framework::coin::merge;
    // #[test_only]
    // use std::signer;
    const INSUFFICIENT_BALANCE: u64 = 1;
    const INVALID_SIGNER: u64 = 2;
    const INVALID_NONCE: u64 = 3;
    const CONVERT_BASE: u256 = 10000000000;

    const ZERO_ADDR: vector<u8> = x"0000000000000000000000000000000000000000000000000000000000000000";

    public entry fun sendTx(
        account: &signer,
        value: u256,
        from: vector<u8>,
        to: vector<u8>,
        nonce: u256,
        data: vector<u8>,
        gas_fee: u256,
        _tx_type: u64,
    ) {
        checkCaller(account);
        coin::transfer<AptosCoin>(account, @demo, (gas_fee as u64));

        let deploy_contract = if (to == ZERO_ADDR) true else false;
        createAccount(from, false);

        if (deploy_contract) {
            let contract_addr = evm::deploy(account, from, nonce, data, value);
            to = contract_addr;
        } else {
            createAccount(to, false);
            call(account, from, to, data, value);
        };

        update(account, from, to, nonce, value, gas_fee * CONVERT_BASE);
    }

    public entry fun test_query(from: vector<u8>, to: vector<u8>, data: vector<u8>) {
        evm::view(from, to, data);
    }

    #[view]
    public fun query(from: vector<u8>, to: vector<u8>, data: vector<u8>): vector<u8> {
        evm::view(from, to, data)
    }

    public entry fun deposit(account: &signer, amount: u256, to: vector<u8>) {
        coin::transfer<AptosCoin>(account, @demo, ((amount / CONVERT_BASE) as u64));
        // coin::withdraw<>()
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
        // let evm = account::create_account_for_test(@demo);
        set_time_has_started_for_testing(&aptos);
        evmstorage::init_module_for_test(&caller);
        evm::init_module_for_test(&caller);
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<AptosCoin>(
            &aptos,
            string::utf8(b"APT"),
            string::utf8(b"APT"),
            8,
            false,
        );
        coin::register<AptosCoin>(&caller);
        // coin::register<AptosCoin>(&evm);

        let coins = coin::mint<AptosCoin>(1000000000000, &mint_cap);
        coin::deposit(signer::address_of(&caller), coins);
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_freeze_cap(freeze_cap);
        coin::destroy_burn_cap(burn_cap);

        //test deposit
        let alice = to_32bit(x"892a2b7cF919760e148A0d33C1eb0f44D3b383f8");
        // let bob = to_32bit(x"2D83750BDB3139eed1F76952dB472A512685E3e0");
        deposit(&caller, 100000000000000000000, alice);
        // // debug::print(&borrow_global<R>(@demo).accounts);
        // debug::print(&utf8(b"alice transfer 1 apt to bob"));
        // sendTx(&caller, 1000000000000000000, alice, bob, 0, x"", 10000);
        // // debug::print(&borrow_global<R>(@demo).accounts);

        debug::print(&utf8(b"alice deploy a single contract"));
        let data = x"60806040526040516105d83803806105d8833981810160405281019061002591906100f0565b804210610067576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161005e906101a0565b60405180910390fd5b8060008190555033600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550506101c0565b600080fd5b6000819050919050565b6100cd816100ba565b81146100d857600080fd5b50565b6000815190506100ea816100c4565b92915050565b600060208284031215610106576101056100b5565b5b6000610114848285016100db565b91505092915050565b600082825260208201905092915050565b7f556e6c6f636b2074696d652073686f756c6420626520696e207468652066757460008201527f7572650000000000000000000000000000000000000000000000000000000000602082015250565b600061018a60238361011d565b91506101958261012e565b604082019050919050565b600060208201905081810360008301526101b98161017d565b9050919050565b610409806101cf6000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c8063251c1aa3146100465780633ccfd60b146100645780638da5cb5b1461006e575b600080fd5b61004e61008c565b60405161005b919061024a565b60405180910390f35b61006c610092565b005b61007661020b565b60405161008391906102a6565b60405180910390f35b60005481565b6000544210156100d7576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016100ce9061031e565b60405180910390fd5b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610167576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161015e9061038a565b60405180910390fd5b7fbf2ed60bd5b5965d685680c01195c9514e4382e28e3a5a2d2d5244bf59411b9347426040516101989291906103aa565b60405180910390a1600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc479081150290604051600060405180830381858888f19350505050158015610208573d6000803e3d6000fd5b50565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6000819050919050565b61024481610231565b82525050565b600060208201905061025f600083018461023b565b92915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061029082610265565b9050919050565b6102a081610285565b82525050565b60006020820190506102bb6000830184610297565b92915050565b600082825260208201905092915050565b7f596f752063616e27742077697468647261772079657400000000000000000000600082015250565b60006103086016836102c1565b9150610313826102d2565b602082019050919050565b60006020820190508181036000830152610337816102fb565b9050919050565b7f596f75206172656e277420746865206f776e6572000000000000000000000000600082015250565b60006103746014836102c1565b915061037f8261033e565b602082019050919050565b600060208201905081810360008301526103a381610367565b9050919050565b60006040820190506103bf600083018561023b565b6103cc602083018461023b565b939250505056fea264697066735822122037d72a62344bd1b2480de1f3f4d6ffe4a35d6a5337d4c346f069eed9df11cad164736f6c6343000813003300000000000000000000000000000000000000000000000000000000000eb2b1";
        sendTx(&caller, 1, alice, ZERO_ADDR, 0, data, 100000, 1);

        // debug::print(&borrow_global<R>(@demo).accounts);
        // let data = x"252dba42000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000d8cdb8f68f35f36959044c56f60e5081e6a0ff37000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000040902f1ac00000000000000000000000000000000000000000000000000000000";
        // query(alice, alice, data);
    }
}
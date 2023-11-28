module demo::signer {
    #[test_only]
    use aptos_framework::account;
    use std::vector;
    #[test_only]
    use aptos_framework::account::{create_resource_account, create_resource_address};
    #[test_only]
    use aptos_std::debug;
    #[test_only]
    use std::signer;
    use aptos_framework::account::create_resource_account;

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

    fun create(account: &signer, evm_addr: vector<u8>) {
        let(resource, signer_cap) = create_resource_account(account, evm_addr);

    }


    #[test(admin = @demo)]
    fun testSigner() {
        let _aptos = account::create_account_for_test(@0x1);
        let sender = to_32bit(x"892a2b7cF919760e148A0d33C1eb0f44D3b383f8");
        let user = account::create_account_for_test(@signer);
        let(resource, signer_cap) = create_resource_account(&user, sender);

        let address = create_resource_address(&@signer, sender);
        // let resource_signer_cap = resource_account::retrieve_resource_account_cap(&user, @0x1);

        debug::print(&address);
        debug::print(&signer_cap);
        debug::print(&signer::address_of(&resource));
    }
}


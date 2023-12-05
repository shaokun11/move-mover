module aptos_framework::evm {
    public native fun msg_sender(): address;
    public native fun create_signer(addr: address): signer;
}
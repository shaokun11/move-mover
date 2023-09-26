let {AptosAccount, MoveView, BCS, AptosClient, HexString, TxnBuilderTypes, FaucetClient} = require("aptos")
const client = new AptosClient("https://fullnode.devnet.aptoslabs.com");
let pk = "0xc2ecf903082be25b14b93eae5c635ca4e182200fac5d0cd614c0fbf9fb80d3c0";
let owner = new AptosAccount(new HexString(pk).toUint8Array())

async function submitTx(rawTxn) {
    const bcsTxn = await client.signTransaction(owner, rawTxn);
    console.log(bcsTxn)
    const pendingTxn = await client.submitTransaction(bcsTxn);

    return pendingTxn.hash;
}

function convertToPaddedUint8Array(str, length = 32) {
    const value = Uint8Array.from(Buffer.from(str.replace(/^0x/i, "").padStart(length, "0"), "hex"))
    return Uint8Array.from([...new Uint8Array(length - value.length), ...value])
}

async function run() {
    let alice = "0x0000000000000000000000000000000000000000000000000000000000000000"
    let rawTxn = await client.generateTransaction(owner.address(), {
        function: `${owner.address()}::evmtx::deposit`,
        type_arguments: [],
        arguments: [100, convertToPaddedUint8Array(alice)],
    });
    console.log(await submitTx(rawTxn));

}


run().then();
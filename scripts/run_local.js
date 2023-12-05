let {AptosAccount, MoveView, BCS, AptosClient, HexString, TxnBuilderTypes, FaucetClient, get} = require("aptos")
const fs = require("fs");
const path = require("path");
const client = new AptosClient("http://127.0.0.1:8080");
const { keccak256 } = require("ethers");
let pk = "0x482cecd3907cd6571b4bea0c3bafc316c8e6037dbd16434ffc6882b71c614ea9";
let owner = new AptosAccount(new HexString(pk).toUint8Array())
let zeros = "0x0000000000000000000000000000000000000000000000000000000000000000"
let alice = "0x000000000000000000000000d25f846911bAB00fEd5da31eaB8d4812d00fD100".toLowerCase()
let aliceEthAddress = "0x" + alice.slice(26)
let amount_1 = "500000000000000000"

let { AbiCoder, Interface } = require("@ethersproject/abi");
const data = require("./data.json");
const {address} = require("./data.json");
let abiCoder = new AbiCoder()

async function submitTx(rawTxn) {
    const bcsTxn = await client.signTransaction(owner, rawTxn);
    // await client.simulateTransaction(owner, rawTxn);
    const pendingTxn = await client.submitTransaction(bcsTxn);
    await client.waitForTransaction(pendingTxn.hash)
    return pendingTxn.hash;
}

function convertToPaddedUint8Array(str, length = 32) {
    const value = Uint8Array.from(Buffer.from(str.replace(/^0x/i, "").padStart(length, "0"), "hex"))
    return Uint8Array.from([...new Uint8Array(length - value.length), ...value])
}

async function deposit() {
    let rawTxn = await client.generateTransaction(owner.address(), {
        function: `${owner.address()}::evmtx::deposit`,
        type_arguments: [],
        arguments: ["500000000000000000", convertToPaddedUint8Array(alice)],
    });
    console.log(await submitTx(rawTxn));
}




function toBuffer(hex) {
    return new HexString(hex).toUint8Array();
}

async function sendTx(to, calldata) {
    let nonce = await getNonce(alice);
    let rawTxn = await client.generateTransaction(owner.address(), {
        function: `${owner.address()}::evmtx::sendTx`,
        type_arguments: [],
        arguments: [0, toBuffer(alice), toBuffer(to), nonce, toBuffer(calldata), 100000],
    });

    console.log(await submitTx(rawTxn));
    if(to == zeros) {
        let salt = alice + nonce.toString(16).padStart(64, "0")
        let contract_addr = "0x" + keccak256(salt).slice(26)
        return contract_addr
    }
}

async function view(to, calldata) {
    let payload = {
        function: address + `::evm::view`,
        type_arguments: [],
        arguments: ["", "0x70a08231000000000000000000000000e7b97f140835a4308f368b88ab790c170e148296"],
    };
    return await client.view(payload);
}

const encodeFunction = (method, params) => {
    const parameters = params?.types ?? [];
    let methodWithParameters = `function ${method}(${parameters.join(",")})`;
    methodWithParameters = method == "aggregate" ? "function aggregate((address,bytes)[])": methodWithParameters
    const signatureHash = new Interface([methodWithParameters]).getSighash(method);
    const encodedArgs = abiCoder.encode(parameters, params?.values ?? []);

    return signatureHash + encodedArgs.slice(2);
};

function to32Bit(addr) {
    return "0x" + "00".repeat(12) + addr.slice(2)
}

async function getCount() {
    let resource = await client.getAccountResource(owner.address(), `${owner.address()}::counter::M`, [])
    console.log(resource.data.num);
}

async function simulateCount() {
    let rawTxn = await client.generateTransaction(owner.address(), {
        function: `${owner.address()}::counter::add_simulate`,
        type_arguments: [],
        arguments: [],
    });
    let res = await client.simulateTransaction(owner, rawTxn);
    console.log(res);
}

async function addCount() {
    let rawTxn = await client.generateTransaction(owner.address(), {
        function: `${owner.address()}::counter::add_simulate`,
        type_arguments: [],
        arguments: [],
    });
    console.log(await submitTx(rawTxn));
}

async function run() {
    await simulateCount();
    // await addCount()
    // await getCount()
    // await deposit()
    // await deploy()
    // await uniswap()
    // await uniswap2()
    // await mint("0xE4dbFd60e3B20E2018dC07fd88148C0D7D966aB2".toLowerCase())
}


run().then();
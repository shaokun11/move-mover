let {AptosAccount, MoveView, BCS, AptosClient, HexString, TxnBuilderTypes, FaucetClient, get} = require("aptos")
const fs = require("fs");
const path = require("path");
const client = new AptosClient("https://seed-node1-rpc.movementlabs.xyz");
const { keccak256 } = require("ethers");
let pk = "0x9380c4b6e92c7e36ab14f60045d0eb44afc318d6fe626c4669822e580d54790a";
let owner = new AptosAccount(new HexString(pk).toUint8Array())
let zeros = "0x0000000000000000000000000000000000000000000000000000000000000000"
let alice = "0x000000000000000000000000892a2b7cF919760e148A0d33C1eb0f44D3b383f8".toLowerCase()
let aliceEthAddress = "0x" + alice.slice(26)
let amount_1 = "500000000000000000"

let { AbiCoder, Interface } = require("@ethersproject/abi");
const data = require("./data.json");
const {address} = require("./data.json");
let abiCoder = new AbiCoder()

async function submitTx(rawTxn) {
    const bcsTxn = await client.signTransaction(owner, rawTxn);
    await client.simulateTransaction(owner, rawTxn);
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

async function getNonce(addr) {
    let resource = await client.getAccountResource(owner.address(), `${owner.address()}::evmstorage::R`, [])
    return parseInt(resource.data.accounts.data.find(i => i.key == addr).value.nonce)
}

const encodeDeployment = (bytecode, params) => {
    const deploymentData = "0x" + bytecode;
    if (params) {
        const argumentsEncoded = abiCoder.encode(params.types, params.values);
        return deploymentData + argumentsEncoded.slice(2);
    }
    return deploymentData;
};

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

async function mint(addr) {
    let address = require("./data.json").address
    console.log("mint usdc")
    const mintUSDC = encodeFunction("mint", {
        types: ["address", "uint256"],
        values: [addr, "500000000000000000000"]
    });
    await sendTx(to32Bit(address.USDC), mintUSDC)

    console.log("mint usdt")
    const mintUSDT = encodeFunction("mint", {
        types: ["address", "uint256"],
        values: [addr, "500000000000000000000"]
    });
    await sendTx(to32Bit(address.USDT), mintUSDT)
}

async function uniswap2() {
    let address = require("./data.json").address
    console.log("get pair")
    const getPair = encodeFunction("getPair", {
        types: ["address", "address"],
        values: [address.USDC, address.USDT]
    });

    let pair = await view(to32Bit(address.FACTORY), getPair)
    console.log(pair);
}

async function uniswap() {
    let address = require("./data.json").address
    console.log("mint usdc")
    const mintUSDC = encodeFunction("mint", {
        types: ["address", "uint256"],
        values: [aliceEthAddress, "500000000000000000000"]
    });
    await sendTx(to32Bit(address.USDC), mintUSDC)

    console.log("mint usdt")
    const mintUSDT = encodeFunction("mint", {
        types: ["address", "uint256"],
        values: [aliceEthAddress, "500000000000000000000"]
    });
    await sendTx(to32Bit(address.USDT), mintUSDT)

    console.log("approve usdc")
    const approveUSDC = encodeFunction("approve", {
        types: ["address", "uint256"],
        values: [address.ROUTER, "500000000000000000000"]
    });
    await sendTx(to32Bit(address.USDC), approveUSDC)

    console.log("approve usdt")
    const approveUSDT = encodeFunction("approve", {
        types: ["address", "uint256"],
        values: [address.ROUTER, "500000000000000000000"]
    });
    await sendTx(to32Bit(address.USDT), approveUSDT)

    let deadline = 1697746917;
    console.log("add liquidity")
    const addLiquidity = encodeFunction("addLiquidity", {
        types: ["address", "address", "uint256", "uint256", "uint256", "uint256", "address", "uint256"],
        values: [address.USDC, address.USDT, "100000000000000000000", "100000000000000000000", 0, 0, aliceEthAddress, deadline],
    });
    await sendTx(to32Bit(address.ROUTER), addLiquidity)

    console.log("swap")
    const swap = encodeFunction("swapExactTokensForTokens", {
        types: ["uint256", "uint256", "address[]", "address", "uint256"],
        values: ["50000000000000000000", 0, [address.USDC, address.USDT], aliceEthAddress, deadline]
    });
    await sendTx(to32Bit(address.ROUTER), swap)

    // console.log("approve to router")
    // const approveRouter = encodeFunction("approve", {
    //     types: ["address", "uint256"],
    //     values: [aliceEthAddress, "500000000000000000000"]
    // });
    // await sendTx(to32Bit(address.USDC), mintUSDC)
    //
    // console.log("mint usdc")
    // const mintUSDC = encodeFunction("mint", {
    //     types: ["address", "uint256"],
    //     values: [aliceEthAddress, "500000000000000000000"]
    // });
    // await sendTx(to32Bit(address.USDC), mintUSDC)
    //
    // console.log("mint usdc")
    // const mintUSDC = encodeFunction("mint", {
    //     types: ["address", "uint256"],
    //     values: [aliceEthAddress, "500000000000000000000"]
    // });
    // await sendTx(to32Bit(address.USDC), mintUSDC)
    //
    // console.log("mint usdc")
    // const mintUSDC = encodeFunction("mint", {
    //     types: ["address", "uint256"],
    //     values: [aliceEthAddress, "500000000000000000000"]
    // });
    // await sendTx(to32Bit(address.USDC), mintUSDC)
}

async function deploy() {
    let data = require("./data.json")
    let bytecodes = data.bytecodes

    let usdcBytecode = encodeDeployment(bytecodes.ERC20, {
        types: ["string", "string", "uint8"],
        values: ["USDC", "USDC", 18]
    })
    let usdcAddr = await sendTx(zeros, usdcBytecode)
    let usdtBytecode = encodeDeployment(bytecodes.ERC20, {
        types: ["string", "string", "uint8"],
        values: ["USDT", "USDT", 18]
    })
    let usdtAddr = await sendTx(zeros, usdtBytecode)

    let factoryBytecode = encodeDeployment(bytecodes.factory, {
        types: ["address"],
        values: [aliceEthAddress]
    })
    let factoryAddr = await sendTx(zeros, factoryBytecode)

    let wethBytecode = encodeDeployment(bytecodes.WETH, {
        types: [],
        values: []
    })
    let wethAddr = await sendTx(zeros, wethBytecode)

    let routerBytecode = encodeDeployment(bytecodes.router, {
        types: ["address", "address"],
        values: [factoryAddr, wethAddr]
    })
    let routerAddr = await sendTx(zeros, routerBytecode);

    let multicallBytecode = encodeDeployment(bytecodes.multicall, {
        types: [],
        values: []
    })
    let multicallAddr = await sendTx(zeros, multicallBytecode)

    data.address = {
        USDC: usdcAddr,
        USDT: usdtAddr,
        WETH: wethAddr,
        ROUTER: routerAddr,
        FACTORY: factoryAddr,
        MULTICALL: multicallAddr
    }
    fs.writeFileSync("./scripts/data.json", JSON.stringify(data, null, 4))
}

async function run() {
    await getNonce();
    // await deposit()
    // await deploy()
    // await uniswap()
    // await uniswap2()
    // await mint("0xE4dbFd60e3B20E2018dC07fd88148C0D7D966aB2".toLowerCase())
}


run().then();
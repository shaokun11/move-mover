const {exec } = require('child_process')
const fs = require("fs");
let fileName = "ERC20"
let contractName = "ERC20Mock"
let file = `./contracts/${fileName}.sol`
let { ethers } = require("ethers")

async function genBytecode() {
    await runCmd(`solc --optimize --bin-runtime ${file} -o ./yul --overwrite`)
    let runtime = fs.readFileSync(`./yul/${contractName}.bin`).toString()

    await runCmd(`solc --optimize --bin ${file} -o ./yul --overwrite`)
    let bytecode = fs.readFileSync(`./yul/${contractName}.bin`).toString()
    let abiEncoder = ethers.AbiCoder.defaultAbiCoder()
    const params = abiEncoder.encode(['string', 'string', 'uint8'], ["USDC", "USDC", 18]);
    let construct = bytecode + params.slice(2);

    fs.writeFileSync(`./output/${fileName}.bytecode`, `runtime\n${runtime}\n\nconstructor\n${construct}`)
    console.log("complete")
}

function runCmd(cmd) {
    return new Promise((resolve, reject) => {
        exec(cmd, (err, stdout, stderr) => {
            if (err) {
                console.log(err)
                reject(err);
                return;
            }
            resolve(stdout);
        });
    })
}

genBytecode()
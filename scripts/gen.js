const {exec } = require('child_process')
const fs = require("fs");
let fileName = "UniswapV2Factory"
let contractName = "UniswapV2Factory"
let file = `./contracts/flatten/${fileName}.sol`
let { ethers } = require("ethers")

async function genBytecode() {
    await runCmd(`solc --optimize --bin-runtime ${file} -o ./yul --overwrite`)
    let runtime = fs.readFileSync(`./yul/${contractName}.bin-runtime`).toString()

    await runCmd(`solc --optimize --bin ${file} -o ./yul --overwrite`)
    let bytecode = fs.readFileSync(`./yul/${contractName}.bin`).toString()
    let abiEncoder = ethers.AbiCoder.defaultAbiCoder()
    const params = abiEncoder.encode(['address'], ["0xe7b97f140835a4308f368b88ab790c170e148296"]);
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
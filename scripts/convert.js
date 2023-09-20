let fs = require("fs");
let {exec} = require("child_process");
let template = JSON.parse(fs.readFileSync(`./output/template.json`).toString())

async function process(file, contractName) {
    await runCmd(`solc --optimize --ast-compact-json ${file} -o ./output --overwrite`)
    let ast = JSON.parse(fs.readFileSync(`./output/${contractName}.sol_json.ast`).toString())
    // let constructor = source.code
    // let content = source.subObjects[0].code
    // statements = content.block.statements[0].statements;
    //
    // await runCmd(`solc --storage-layout ${file} -o ./yul --overwrite`)
    // storages = JSON.parse(fs.readFileSync(`./yul/${contractName}_storage.json`).toString())
    //
    await runCmd(`solc --abi ${file} -o ./output --overwrite`)
    let abi = JSON.parse(fs.readFileSync(`./output/${contractName}.abi`).toString())
    //
    await runCmd(`solc --hashes ${file} -o ./output --overwrite`)
    let src = fs.readFileSync(`./output/${contractName}.signatures`).toString()
    const lines = src.split('\n');
    const signatureLines = lines.filter(line => /^[0-9a-f]{8}:/.test(line));
    let signatures = signatureLines.map(line => {
        const parts = line.split(':');
        const signature = parts[0].trim();

        const match = parts[1].trim().match(/([a-z_]+)\((.*)\)/i) || parts[1].trim().match(/([a-z_]+)()/i);
        const funName = match[1];
        const abiItem = abi.find(i => i.name == funName)
        const inputs = abiItem.inputs
        const outputs = abiItem.outputs
        const scope = abiItem.stateMutability
        return {
            funName,
            signature,
            inputs,
            outputs,
            scope
        };
    });

    return {
        signatures: signatures,
        ast: ast
    }
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

async function main() {
    let ERC20FileName = "ERC20"
    let ERC20File = `./contracts2/${ERC20FileName}.sol`
    let source = await process(ERC20File, ERC20FileName)
    for(let contract of source.nodes) {
        if(contract.nodeType == "ContractDefinition") {
            for(let item of contract.nodes) {
                if(item.nodeType == "FunctionDefinition" && item.stateMutability != "view" && item.visibility == "public") {
                    item.body = template.statement;
                }
            }
        }

    }
    console.log(template);
}

main()

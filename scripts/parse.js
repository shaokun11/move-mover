let fileName = "ERC20"
let contractName = "ERC20Mock"
let fs = require("fs")
const {exec } = require('child_process')

let statements

let indent = 8;

const VarTypes = {
    Storage: "storage",
    Constant: "constant"
}

let localCodes = ""
let globalCodes = ""
let functions = {}
let signatures = []
let storages
let abi
let scope = "global"

function initCode() {
    globalCodes = " ".repeat(indent) + "let move_ret = &mut vector::empty<u8>();\n"
    globalCodes += " ".repeat(indent) + "let memory = &mut simple_map::new<u256, u256>();\n"
    globalCodes += " ".repeat(indent) + "let pstorage = &mut borrow_global_mut<T>(@demo).storage;\n"
}

function addCodes(scope, code, head = false) {
    let added = " ".repeat(indent) + `${code}\n`
    if(scope == "global") {
        globalCodes = head ? added + globalCodes: globalCodes + added;
        // viewCodes += " ".repeat(indent) + `${code}\n`
    } else {
        functions[scope].code = head ? added + functions[scope].code: functions[scope].code + added
    }

}

async function process(file) {
    await runCmd(`solc --optimize --ir-optimized-ast-json ${file} -o ./yul --overwrite`)
    let source = JSON.parse(fs.readFileSync(`./yul/${contractName}_opt_yul_ast.json`).toString())
    let constructor = source.code
    let content = source.subObjects[0].code
    statements = content.block.statements[0].statements;

    await runCmd(`solc --storage-layout ${file} -o ./yul --overwrite`)
    storages = JSON.parse(fs.readFileSync(`./yul/${contractName}_storage.json`).toString())

    await runCmd(`solc --abi ${file} -o ./yul --overwrite`)
    abi = JSON.parse(fs.readFileSync(`./yul/${contractName}.abi`).toString())

    await runCmd(`solc --hashes ${file} -o ./yul --overwrite`)
    let hashes = fs.readFileSync(`./yul/${contractName}.signatures`).toString()
    signatures = readSignature(hashes)
    scope = "global"
    initCode()
    // readDef(constructor.block)
    readDef(content.block)
    writeDefinition()
    scope = "global"

    readCode(content.block)

    // addCodes("view", "ret")
    // addCodes("global", "*borrow_global_mut<T>(@demo).storage = pstorage;")
    addCodes("global", "*takes_mut_returns_immut(move_ret)")
    generate()
}

function readDef(code) {
    for(let statement of code.statements) {
        if(statement.nodeType == "YulFunctionDefinition") {
            functions[statement.name] = {
                name: statement.name,
                content:statement.body,
                params: statement.parameters ?? [],
                ret:statement.returnVariables ?? [],
                code: "",
                options: {
                    storage: false,
                    memory: false,
                    data: false,
                    sender: false
                }
            }
        }
    }
}

function writeDefinition() {
    // viewCodes.
    indent = 4
    for(let item of Object.values(functions)) {
        scope = item.name
        let params = item.params.map(i => i.name + ": u256")
        let ret = item.ret.map(i => i.name)
        indent += 4
        readCode(item.content)
        if(item.ret.length > 0) {
            addCodes(scope, ret[0])
        }
        indent -= 4
        if(item.options.storage) {
            params.push("pstorage: &mut SimpleMap<u256, u256>")
        }

        if(item.options.memory) {
            params.push("memory: &mut SimpleMap<u256, u256>")
        }

        if(item.options.data) {
            params.push("data: vector<u8>")
        }

        // if(item.options.sender) {
        //     params.push("signer: &signer")
        // }
        let title = `fun ${item.name}(${params.join(', ')}) ${ret.length > 0 ? ":u256": ""} {`
        addCodes(scope, title, true)
        addCodes(scope,"}")
        localCodes += item.code + "\n"

    }
    indent += 4

    // console.log(111);
}


function readSignature(src) {
    const lines = src.split('\n');

// 过滤出有关函数签名的行
    const signatureLines = lines.filter(line => /^[0-9a-f]{8}:/.test(line));

// 将每行转换为所需的对象格式
    return signatureLines.map(line => {
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
}

function readCode(code) {
    let exps = []
    for(let statement of code.statements) {
        switch(statement.nodeType) {
            case "YulSwitch":
                exps.push(readSwitch(statement.cases, statement.expression))
                break
            case "YulIf":
                exps.push(readIf(statement.condition, statement.body))
                break
            case "YulExpressionStatement":
                exps.push(readExpression(statement.expression))
                break
            case "YulVariableDeclaration":
                exps.push(readVariable(statement.variables, statement.value, false))
                break
            case "YulAssignment":
                exps.push(readVariable(statement.variableNames, statement.value, true))
                break
            case "YulBlock":
                readCode(statement)
                break
            case "YulForLoop":
                readForLoop(statement.condition, statement.post, statement.body)
                break
        }
    }
    return exps
}

function readSwitch(cases, expression) {
    switch (expression.nodeType) {
        case "YulFunctionCall": {
            let fun = readFun(expression.functionName.name, expression.arguments)
            addCodes(scope, `let m = ${fun};`)
            break
        }
        case "YulIdentifier":
            addCodes(scope, `let m = ${expression.name};`)
            break
    }

    for(let item of cases) {
        let value = item.value
        addCodes(scope, `if(yul::equal(m, ${genU256(value)})) {`)
        indent += 4
        readCode(item.body)
        indent -= 4
        addCodes(scope, "};")
    }
}

function genU256(value) {
    // if(value.kind == "number")
    //     return `u256::from_u64(${value})`
    if(value.kind == "number")
        return `${value.value}`
    else if(value.kind == "string")
        return `0x${value.hexValue}`
}

function readFun(funName, args) {
    let params = []
    if(funName == "mload" ||funName == "mstore" || funName == "keccak256") {
        if(scope != "global") {
            functions[scope].options.memory = true;
        }
        params.push("memory")
    }
    if(funName == "calldatasize" || funName == "calldataload") {
        if(scope != "global") {
            functions[scope].options.data = true;
        }
        params.push("data")
    }

    if(funName == "caller") {
        params.push("sender")
    }

    if(funName == "sload" || funName == "sstore") {
        if(scope != "global") {
            functions[scope].options.storage = true;
        }
        params.push("pstorage")
    }

    if(funName == "return") {
        params.push("move_ret")
        params.push("memory")
        funName = "ret"
    }

    // if(funName == "revert" && scope == "global") {
    //     return null
    // }


    for(let arg of args) {
        if(arg.nodeType == "YulLiteral")
            params.push(genU256(arg))
        else if(arg.nodeType == "YulFunctionCall") {
            params.push(readFun(arg.functionName.name, arg.arguments))
        } else if(arg.nodeType == "YulIdentifier") {
            params.push(arg.name)
        }
    }

    let localFun = Object.values(functions).find(i => i.name == funName)
    let fun
    if(localFun) {
        if(localFun.options.storage) {
            params.push("pstorage")
        }

        if(localFun.options.memory) {
            params.push("memory")
        }

        if(localFun.options.data) {
            params.push("data")
        }
        fun = `${funName}(${params.join(',')})`
    } else {
        fun = `yul::${funName}(${params.join(',')})`
    }

    return fun
}

function readVariable(names, values, assign) {
    let left = names.map(i => i.name).join(",")
    let right = null
    let args = values.arguments;
    if(scope != "global" && assign) {
        if(functions[scope].ret.find(i => i.name == names[0].name)) {
            assign = false
        }
    }
    switch(values.nodeType) {
        case "YulFunctionCall": {
            let funName = values.functionName.name
            right = readFun(funName, args)
            break
        }
        case "YulIdentifier":
            right = values.name
            break
        case "YulLiteral":
            if(values.kind == "number")
                right = genU256(values)
    }


    addCodes(scope, assign ? `${left} = ${right};`: `let ${left} = ${right};`)
}

function readExpression(expression) {
    let arg = expression.arguments
    switch(expression.nodeType) {
        case "YulFunctionCall":
            let funName = expression.functionName.name
            let fun = readFun(funName, arg)
            if(fun) {
                addCodes(scope, `${fun};`)
            }

    }
}

function readForLoop(condition, post, body) {
    let cond
    switch(condition.nodeType) {
        case "YulFunctionCall":
            let fun = readFun(condition.functionName.name, condition.arguments)
            // if(!fun.startsWith("yul::eq(")) {
            cond = `${fun} != 0`
        // }else {
        //     cond = fun
        // }

    }

    addCodes(scope, `while(${cond}) {`)
    indent += 4
    readCode(body)
    readCode(post)
    indent -= 4
    addCodes(scope, `};`)
}

function readIf(condition, body) {
    let cond
    switch(condition.nodeType) {
        case "YulFunctionCall":
            let fun = readFun(condition.functionName.name, condition.arguments)
            // if(!fun.startsWith("yul::eq(")) {
            cond = `${fun} != 0`
        // }else {
        //     cond = fun
        // }

    }

    addCodes(scope, `if(${cond}) {`)
    indent += 4
    readCode(body)
    indent -= 4
    addCodes(scope, `};`)
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

function generateMoveCode() {
    const moveCode = `
module demo::${contractName.toLowerCase()} {
    use demo::yul;
    use std::vector;
    use std::signer;
    use aptos_std::simple_map;
    use aptos_std::simple_map::SimpleMap;
    
    struct T has key {
        storage: SimpleMap<u256, u256>
    }
    
    fun takes_mut_returns_immut(x: &mut vector<u8>): &vector<u8> { x }

    entry fun init_module(account: &signer) {
        move_to(account, T {
            storage: simple_map::new<u256, u256>(),
        });
    }
    
    public fun run(sender: address, data: vector<u8>): vector<u8> acquires T {
${globalCodes}
    }
    
${localCodes}

    public entry fun call(account: &signer,data: vector<u8>) acquires T  {
        run(signer::address_of(account), data);
    }

    #[view]
    public fun view(sender: address, data: vector<u8>): vector<u8> acquires T  {
        run(sender, data)
    }
}`;

    return moveCode;
}

function generate() {
    fs.writeFileSync(`./move/contract/sources/modules/${contractName}.move`, generateMoveCode())
    console.log("run complete")
}

process(`./contracts/${fileName}.sol`)





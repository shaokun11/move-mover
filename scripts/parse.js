let contractName = "Counter"
let fs = require("fs")
const {exec } = require('child_process')

let statements

let indent = 8;


const VarTypes = {
    Storage: "storage",
    Constant: "constant"
}

let callCodes = ""
let viewCodes = ""

let functions = []
let storages
let abi
let vars = {}
let scope = "global"

function initCode() {
    callCodes = " ".repeat(indent) + "let ret = vector::empty<u8>();\n"
    callCodes += " ".repeat(indent) + "let memory = simple_map::new<U256, U256>();\n"
    callCodes += " ".repeat(indent) + "let pstorage = borrow_global_mut<T>(@demo).storage;\n"

    viewCodes = " ".repeat(indent) + "let ret = vector::empty<u8>();\n"
    viewCodes += " ".repeat(indent) + "let memory = simple_map::new<U256, U256>();\n"
    viewCodes += " ".repeat(indent) + "let pstorage = borrow_global_mut<T>(@demo).storage;\n"
}

function addCodes(scope, code) {
    if(scope == "global") {
        callCodes += " ".repeat(indent) + `${code}\n`
        viewCodes += " ".repeat(indent) + `${code}\n`
    } else if(scope == "call") {
        callCodes += " ".repeat(indent) + `${code}\n`
    } else if(scope == "view") {
        viewCodes += " ".repeat(indent) + `${code}\n`
    }
}

async function process(file) {
    await runCmd(`solc --optimize --ir-optimized-ast-json ${file} -o ./yul --overwrite`)
    let source = JSON.parse(fs.readFileSync(`./yul/${contractName}_opt_yul_ast.json`).toString())
    let constructor = source.code
    let content = source.subObjects[0].code
    statements = content.block.statements[0].statements;

    let src = await runCmd(`solc --storage-layout ${file}`)
    let regex = /Contract Storage Layout:\s*([\s\S]*)/;
    let match = src.match(regex);
    storages = JSON.parse(match[1])

    src = await runCmd(`solc --abi ${file}`)
    regex = /\[\{.*\}\]/;
    match = src.match(regex);
    abi = JSON.parse(match[0])

    src = await runCmd(`solc --hashes ${file}`)
    functions = readSignature(src)
    scope = "global"
    initCode()
    readCode(content.block)
    addCodes("view", "ret")
    addCodes("call", "borrow_global_mut<T>(@demo).storage = pstorage")
    generate()
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
                return readCode(statement)
            case "YulLeave":
                // exps.push({
                //     type: CodeTypes.LeaveExp
                // })
                break
        }
    }
    return exps
}

function loadStorage(slot, offset = 0) {
    let item = storages.storage.find(i => i.slot == slot);
    return {
        value: item.label,
        type: VarTypes.Storage
    }
}

function setVar(name, value) {
    vars[scope][name] = value
}

function getVar(name) {
    return vars[scope][name]
}

function genConstant(value) {
    return {
        "type": VarTypes.Constant,
        "value": value
    }
}

function readSwitch(cases, expression) {
    let fun = readFun(expression.functionName.name, expression.arguments)
    addCodes(scope, `let m = ${fun};`)
    let changeScope = false;
    for(let item of cases) {
        let value = item.value.value
        if(scope == "global") {
            let sign = functions.find(i => "0x" + i.signature == value)
            scope = sign.scope == "view" ? "view": "call"
            changeScope = true
        }
        addCodes(scope, `if(yul::eq(m, ${genU256(value)})) {`)
        indent += 4
        readCode(item.body)
        indent -= 4
        addCodes(scope, "};")
        if(changeScope) {
            scope = "global"
        }
    }
}

function genU256(value) {
    return `u256::from_u64(${value})`
}

function readFun(funName, args) {
    let params = []
    if(funName == "mstore") {
        params.push("&mut memory")
    }
    if(funName == "calldatasize" || funName == "calldataload") {
        params.push("data")
    }

    if(funName == "sload" || funName == "sstore") {
        params.push("&mut pstorage")
    }

    if(funName == "return") {
        params.push("&mut ret")
        params.push("&mut memory")
        funName = "ret"
    }

    if(funName == "revert" && scope == "global") {
        return null
    }


    for(let arg of args) {
        if(arg.nodeType == "YulLiteral")
            params.push(genU256(arg.value))
        else if(arg.nodeType == "YulFunctionCall") {
            params.push(readFun(arg.functionName.name, arg.arguments))
        } else if(arg.nodeType == "YulIdentifier") {
            params.push(arg.name)
        }
    }
    let fun = `yul::${funName}(${params.join(',')})`
    return fun
}

function readVariable(names, values, assign) {
    let left = names.map(i => i.name).join(",")
    let right = null
    let args = values.arguments;
    switch(values.nodeType) {
        case "YulFunctionCall": {
            let funName = values.functionName.name
            // abi_decode特殊处理
            right = readFun(funName, args)
            break
        }
        case "YulIdentifier":
            right = values.name
            break
        case "YulLiteral":
            if(values.kind == "number")
                right = genU256(values.value)
    }


    addCodes(scope, `let ${left} = ${right};`)
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

function readIf(condition, body) {
    let exps
    let cond
    switch(condition.nodeType) {
        case "YulFunctionCall":
            let fun = readFun(condition.functionName.name, condition.arguments)
            cond = `!yul::eq(${fun},u256::zero())`
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
module demo::counter {
    use demo::yul;
    use std::vector;
    use u256::u256;
    use aptos_std::simple_map;
    use aptos_std::simple_map::SimpleMap;
    use u256::u256::U256;
    
    struct T has key {
        storage: SimpleMap<U256, U256>
    }

    entry fun init_module(account: &signer) {
        move_to(account, T {
            storage: simple_map::new<U256, U256>(),
        });
    }

    public entry fun call(data: vector<u8>) acquires T  {
${callCodes}
    }
    
    #[view]
    public fun view(data: vector<u8>): vector<u8> acquires T  {
${viewCodes}
    }
}`;

    return moveCode;
}

function generate() {
    fs.writeFileSync("./move/contract/sources/modules/Counter.move", generateMoveCode())
    console.log("run complete")
}

process(`./contracts/${contractName}.sol`)





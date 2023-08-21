let contractName = "Counter"

// let source = require(`../yul/${contractName}.json`)
let fs = require("fs")

const {exec } = require('child_process')

let stacks = []

//构造函数
let source
//合约代码
let statements
let usingStorage = false

let indent = 8;
let codes = " ".repeat(indent) + "let memory = simple_map::new<U256, U256>();\n"

const VarTypes = {
    Storage: "storage",
    Constant: "constant"
}


//当前解析的最外层函数, external的
let deps = {}
let functions = []
let storages
let abi
let currentFun

let sources = []
let vars = {}
let memory = {}
let scope = "global"
let exps = []

const CodeTypes = {
    If: "if",
    Skip: "skip",
    Execute: "execute",
    Declare: "declare",
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
    generate.functions = readSignature(src)
    vars[scope] = {}
    readCode(content.block)
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

        return {
            funName,
            signature,
            inputs,
            outputs
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

function runFun(funName, args) {
    switch(funName) {
        case "memoryguard":
            return genConstant(0)
        case "calldatasize":
            if(scope == "global")
                return genConstant(4)
            let item = generate.functions.find(i => "0x" + i.signature == scope);
            return genConstant(32 * item.inputs.length + 4)

        case "mstore":
            memory[parseInt(args[0])] = args[1]
            break
        case "lt":
            return genConstant(parseInt(args[0]) < parseInt(args[1]) ? 1: 0)
        case "slt":
            return genConstant(parseInt(args[0]) < parseInt(args[1]) ? 1: 0)
        case "callvalue":
            return genConstant(0)
        case "add":
            return genConstant(args[0] + args[1])
        case "iszero":
            return genConstant(args[0] == 0 ? 1: 0)
        case "callvalue":
            return 0
        case "not":
            let length = parseInt(args[0]).toString(2).length;
            let binaryOnes = '1'.repeat(length);
            return genConstant(parseInt(binaryOnes, 2) - parseInt(args[0]))
        case "sload":
            usingStorage = true
            return loadStorage(args[0])
    }
}

function readSwitch(cases, expression) {
    let fun = readFun(expression.functionName.name, expression.arguments)
    codes += " ".repeat(indent) + `let m = ${fun};\n`
    for(let item of cases) {
        codes += " ".repeat(indent) + `if(yul::eq(m, ${genU256(item.value.value)})) {\n`
        indent += 4
        readCode(item.body)
        indent -= 4
        codes += " ".repeat(indent) + "};\n"
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

    if(funName == "return") {
        funName = "ret"
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
    // fun = tryRun(fun)
    let fun = `yul::${funName}(${params.join(',')})`
    return fun
}

function tryRun(fun) {
    for(let arg of fun.params) {
        if(arg.type != VarTypes.Constant)
            return fun
    }

    let value = runFun(fun.name, fun.params.map(i => i.value))

    return value ?? fun
    // args.map(i => i.nodeType == "YulLiteral" ? i.value: i.name).join(',')
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


    codes += " ".repeat(indent) + `let ${left} = ${right};\n`
}

function readExpression(expression) {
    let arg = expression.arguments
    switch(expression.nodeType) {
        case "YulFunctionCall":
            let funName = expression.functionName.name
            let fun = readFun(funName, arg)
            codes += " ".repeat(indent) + `${fun};\n`
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

    codes += " ".repeat(indent) + `if(${cond}) {\n`
    indent += 4
    readCode(body)
    indent -= 4
    codes += " ".repeat(indent) + "};\n"
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

function generateMoveCode(content) {
    const moveCode = `
module demo::counter {
    use demo::yul;
    use u256::u256;
    use aptos_std::simple_map;
    use u256::u256::U256;

    public fun call(data: vector<u8>) {
${content}
    }
}`;

    return moveCode;
}

function generate() {
    fs.writeFileSync("./move/contract/sources/modules/Counter.move", generateMoveCode(codes))
    console.log("run complete")
}

process(`./contracts/${contractName}.sol`)





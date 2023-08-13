let contractName = "Counter"

// let source = require(`../yul/${contractName}.json`)
let abi = require(`../artifacts/contracts/${contractName}.sol/${contractName}.json`).abi
let fs = require("fs")

const {exec } = require('child_process')

//构造函数
let source
//合约代码
let statements

const CodeTypes = {
    FunExp: "fun",
    IfExp: "if",
    DecodeExp: "decode",
    NormalExp: "normal",
    LeaveExp: "leave"
}


//当前解析的最外层函数, external的
let deps = {}
let functions = []
let storages
let currentFun

async function process(file) {
    await runCmd(`solc --optimize --ir-optimized --yul-optimizations 'dhfoD[xarrscLMcCTUulmul]:fDnTOc' --ir-optimized-ast-json ${file} -o ./yul --overwrite`)
    let source = JSON.parse(fs.readFileSync(`./yul/${contractName}_opt_yul_ast.json`).toString())
    let constructor = source.code
    let content = source.subObjects[0].code
    statements = content.block.statements;

    let src = await runCmd(`solc --storage-layout ${file}`)
    let regex = /Contract Storage Layout:\s*([\s\S]*)/;
    let match = src.match(regex);
    storages = JSON.parse(match[1])
    readFunctions(content)
}

function parseFunction(funName, params) {
    if(funName == "callvalue") {
        return "Evm::hasCallValue()"
    } else if(funName == "zero_value_for_split_uint256") {
        return "U256::zero()"
    } else if(funName == "checked_add_uint256") {
        return `U256::add(${params[0].name}, ${params[1].name})`
    }
    else if(funName.startsWith("revert")) {
        let code = funName.split("_")[2]
        return `require(false, "${code}")`
    } else {
        let funContent = statements.find(i => i.name === funName)
        let inputs = []
        let outputs = []
        let isPublic
        console.log(`解析到funName`)
        if(funName.startsWith("external")) {
            let abiFun = abi.find(i => i.name == funName.split("_")[2])
            inputs = abiFun.inputs
            outputs = abiFun.outputs
            isPublic = true
        } else {
            if(funContent.parameters)
                inputs = funContent.parameters.map(i => i.name)
            if(funContent.returnVariables)
                outputs = funContent.returnVariables.map(i => i.name)
            isPublic = false
        }
        let code = funContent.body
        let fun = {
            type: CodeTypes.FunExp,
            name: funName,
            exps: null,
            inputs: inputs,
            outputs: outputs,
            isPublic: isPublic
        }
        currentFun = fun
        fun.exps = readCode(code)
        functions.push(fun)
        return `${funName}(${params ? params.map(i => i.name).join(",") : ""})`
    }
}


// 读取函数列表 以selector为入口
function readFunctions() {
    let selectors;
    // for(let st of statements) {
    //     if(st.nodeType == "YulIf" && st.condition.functionName.name == "iszero") {
    //         let root = st.body.statements[1]
    //         selectors = root.cases
    //         break
    //     }
    // }
    let root = statements[0]
    selectors = root.statements[1].body.statements[1].cases
    for(let selector of selectors) {
        if(selector.value == "default")
            break
        let root = selector.body.statements[0].expression
        let funName = root.functionName.name
        parseFunction(funName)
    }

    fs.writeFileSync("./yul/output.json", JSON.stringify({
        functions: functions,
        storages: storages
    }, null, 4))
}

function readCode(code) {
    let exps = []
    for(let statement of code.statements) {
        switch(statement.nodeType) {
            case "YulIf":
                exps.push(readIf(statement.condition, statement.body))
                break
            case "YulExpressionStatement":
                exps.push(readExpression(statement.expression))
                break
            case "YulVariableDeclaration":
                //allocate_unbounded后面的代码直接忽略
                if(statement.value.nodeType == "YulFunctionCall" && statement.value.functionName.name == "allocate_unbounded") {
                    exps.push({
                        type: CodeTypes.LeaveExp
                    })
                    return exps
                }
                exps.push(readVariable(statement.variables, statement.value, false))
                break
            case "YulAssignment":
                exps.push(readVariable(statement.variableNames, statement.value, true))
                break
            case "YulLeave":
                exps.push({
                    type: CodeTypes.LeaveExp
                })
                break
        }
    }
    return exps
}

function readVariable(names, values, assign) {
    let func
    let type = CodeTypes.NormalExp;
    let left = names.map(i => i.name).join(",")
    let right = null
    let arg = values.arguments;
    switch(values.nodeType) {
        case "YulFunctionCall": {
            let funName = values.functionName.name
            // abi_decode特殊处理
            if(funName.startsWith("abi_decode")) {
                return {
                    type: CodeTypes.DecodeExp,
                    params: names.map(i => i.name)
                }
            } else if(funName.startsWith(("read_from_storage"))) {
                let slot
                let offset
                //特殊处理，不成立，后面再解决
                if(arg.length == 2) {
                    slot = parseInt(arg[0].value);
                    offset = parseInt(arg[1].value);
                } else {
                    offset = 0;
                    slot = parseInt(arg[0].value);
                }
                let label = findVar(slot, offset);
                right = `borrow_global_mut<T>(@self).${label}`
            } else if(funName.startsWith("convert_rational_by_to_uint256")) {
                right = parseInt(arg[0].value)
            }
            else {
                func = parseFunction(funName, arg)
                right = func
            }
            break
        }
        case "YulIdentifier":
            right = values.name
            break
        case "YulLiteral":
            if(values.kind == "number") {
                right = parseInt(values.value)
            }
    }

    return {
        type: type,
        content: assign ? `${left} = ${right}`: `let ${left} = ${right}`
    }
}

function readExpression(expression) {
    let arg = expression.arguments
    switch(expression.nodeType) {
        case "YulFunctionCall":
            let funName = expression.functionName.name
            if(funName.startsWith("abi_decode")) {
                return {
                    type: CodeTypes.DecodeExp,
                    params: []
                }
            } else if(funName.startsWith("update_storage")) {
                let label = findVar(arg[0].value, 0);
                return {
                    type: CodeTypes.NormalExp,
                    content: `T.${label} = ${arg[1].name}`
                }
            }
            return {
                type: "normal",
                content: `${funName}()`
            }
    }
}

function readIf(condition, body) {
    let ifExp = {
        type: CodeTypes.IfExp,
        condition: "",
        exps: []
    }

    switch(condition.nodeType) {
        case "YulFunctionCall": 
            ifExp.condition = parseFunction(condition.functionName.name)
            break
    }
    ifExp.exps = readCode(body)
    return ifExp
}

function findVar(slot, offset) {
    for(let v of storages.storage) {
        if(v.offset == offset && parseInt(v.slot) == parseInt(slot))
            return v.label
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

process(`./contracts/${contractName}.sol`)





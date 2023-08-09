let source = require("../yul/Plus.json")
// let block = source.block

//构造函数
let constructor = source.code
//合约代码
let content = source.subObjects[0].code
let statements = content.block.statements

//当前解析的函数
let currentFunction = ""
let deps = {}
let functions = {}

const gen = (type, code) => {
    return {
        type: type,
        code: code
    }
}

function parseFunction(funName) {
    if(funName == "callvalue") {
        return gen(0, "Evm::hasCallValue()")
    } else if(funName.startsWith("abi_decode")) {
        return gen(1,  null)
    }
    else if(funName.startsWith("revert")) {
        let code = funName.split("_")[2]
        return gen(0, `revert(${code})`)
    } else {
        let funContent = statements.find(i => i.name === funName)
        currentFunction = funName

        // TODO: 读取abi中的参数列表，目前先仅用a, b
        functions[funName] = {
            name: funName,
            params: ["a", "b"],
            paramsYul: [] // 在yul中的参数列表，通常是param_1, param_2这种形式，后面会读取
        }

        let code = funContent.body
        readCode(code)
    }
}

// 读取函数列表 以selector为入口
function readFunctions(content) {
    let root = content.block.statements[0].statements[1].body
    let selectors = root.statements[1]["cases"]
    for(let selector of selectors) {
        let root = selector.body.statements[0].expression
        let funName = root.functionName.name
        parseFunction(funName)
    }
}

function readCode(code) {
    for(let statement of code.statements) {
        switch(statement.nodeType) {
            case "YulIf":
                readIf(statement.condition, statement.body)
                break
            case "YulExpressionStatement":
                readExpression(statement.expression)
                break
            case "YulVariableDeclaration":
                readVariable(statement.variables, statement.value)
                break
        }
    }
}

function readVariable(names, values) {
    let func
    switch(values.nodeType) {
        case "YulFunctionCall":
            func = parseFunction(values.functionName.name)
            //说明是解析参数的函数，直接读取yul中的参数以便后续可以用abi中的参数名替换
            if(func.type == 1) {
                functions[currentFunction].paramsYul = names.map(i => i.name)
            }

            break
    }
}

function readExpression(expression) {
    let arg = expression.arguments
    let func
    switch(expression.nodeType) {
        case "YulFunctionCall":
            func = parseFunction(expression.functionName.name)
            break
    }
}

function readIf(condition, body) {
    let arg = condition.arguments
    let func;
    switch(condition.nodeType) {
        case "YulFunctionCall": 
            func = parseFunction(condition.functionName.name)
            break
    }
    readCode(body)
}

readFunctions(content)




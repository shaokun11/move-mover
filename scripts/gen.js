let source = require("../yul/output.json")
let storages = source.storages;
let functions = source.functions;
let struct = "";
let initialValue = ""
let contractName = "counter"
let fs = require("fs")
function generateStruct() {
    for(let i = 0;i < storages.storage.length;i++) {
        let item = storages.storage[i]
        let name = item.label
        let type = item.type
        let src = convert(type)
        struct += `        ${name}: ${src.t}\n`
        initialValue += `        ${name}: ${src.v}\n`
    }
}

function generateFun() {
    let funContent = ""
    for(let item of functions) {
        let fun = ""
        fun += `public fun ${item.name}(): `
        if(item.outputs.length > 0) {
            // let p =
        }
        // console.log(item);
    }
}

//有问题，下次解决
function convert(type) {
    if(type == "t_uint256") {
        return {
            t: "u64",
            v: 0
        }
    }
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
    generateStruct()
    generateFun()
    fs.writeFileSync("./move/add/sources/modules/Counter.move", generateMoveCode())
    console.log("run complete")
}

generate()
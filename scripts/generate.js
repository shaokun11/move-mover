
let scope = ""
let abi = []
let code;

module.exports = {

    functions: null,
    scope: null,
    globalVar: {},
    localVar: {},
    varIdx: {},

    writeExp(scope, exps) {
        if(scope == "global") {
            return
        }

        let codes = []
        this.varIdx = 0
        for(let exp of exps) {
            if(exp.type == "execute") {
                codes.push(this.writeLine(exp.content))
            }
        }
        console.log(1111)
    },

    writeLine(content) {
        let code
        let params = content.params
        if(content.name == "mstore") {
            let key = params[0].value
            let value = params[1].type == "storage" ? `borrow_global_mut<T>(@demo).${params[1].value}`: params[1].value
            code = `simple_map::upsert(&mut memory, ${key}, ${value};`
        } else if(content.name == "return") {
            code = `*simple_map::borrow<u64, u64>(&memory, &${params[0].value});`
        }

        return code
    }
}


function generateMoveCode() {
    const moveCode = `
module demo::yul {
    use std::vector;
    use aptos_std::simple_map;
    use u256::u256;
    use u256::u256::U256;
    use aptos_std::simple_map::SimpleMap;

    fun init_module(signer: &signer) {
        move_to(signer, T{
${initialValue}
        });
    }

    #[view]
    public fun get_counter(): u64 acquires T {
        let ret_1 = borrow_global_mut<T>(@demo).count;
        let ret = ret_1;
        ret
    }

    fun fun_increase() acquires T  {
        let _1 = borrow_global_mut<T>(@demo).count;
        _1 = _1 + 1;
    }

    public entry fun increase() acquires T {
        fun_increase()
    }
}`;

    return moveCode;
}
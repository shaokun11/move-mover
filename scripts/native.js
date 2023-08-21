module.exports = {
    runFun(funName, args) {
        if(funName == memoryguard) {
            return {
                "type": "pointer",
                "value": parseInt(args[0], 16)
            }
        }
    }
}
/// @use-src 0:"ERC20.sol"
object "ERC20Mock_751" {
    code {
        {
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            mstore(64, memoryguard(0x80))
            if callvalue() { revert(0, 0) }
            let programSize := datasize("ERC20Mock_751")
            let argSize := sub(codesize(), programSize)
            let memoryDataOffset := allocate_memory(argSize)
            codecopy(memoryDataOffset, programSize, argSize)
            let _1 := add(memoryDataOffset, argSize)
            if slt(sub(_1, memoryDataOffset), 96)
            {
                revert(/** @src -1:-1:-1 */ 0, 0)
            }
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let offset := mload(memoryDataOffset)
            let _2 := sub(shl(64, 1), 1)
            if gt(offset, _2)
            {
                revert(/** @src -1:-1:-1 */ 0, 0)
            }
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let value0 := abi_decode_string_fromMemory(add(memoryDataOffset, offset), _1)
            let _3 := 32
            let offset_1 := mload(add(memoryDataOffset, _3))
            if gt(offset_1, _2)
            {
                revert(/** @src -1:-1:-1 */ 0, 0)
            }
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let value1 := abi_decode_string_fromMemory(add(memoryDataOffset, offset_1), _1)
            let value := mload(add(memoryDataOffset, 64))
            let _4 := and(value, 0xff)
            if iszero(eq(value, _4))
            {
                revert(/** @src -1:-1:-1 */ 0, 0)
            }
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let newLen := mload(value0)
            if gt(newLen, _2)
            {
                mstore(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ shl(224, 0x4e487b71))
                mstore(4, 0x41)
                revert(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x24)
            }
            /// @src 0:6641:6654  "_name = name_"
            let _5 := 0x03
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let _6 := sload(/** @src 0:6641:6654  "_name = name_" */ _5)
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let length := /** @src -1:-1:-1 */ 0
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let _7 := 1
            length := shr(_7, _6)
            let outOfPlaceEncoding := and(_6, _7)
            if iszero(outOfPlaceEncoding) { length := and(length, 0x7f) }
            if eq(outOfPlaceEncoding, lt(length, _3))
            {
                mstore(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ shl(224, 0x4e487b71))
                mstore(4, 0x22)
                revert(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x24)
            }
            let _8 := 31
            if gt(length, _8)
            {
                mstore(/** @src -1:-1:-1 */ 0, /** @src 0:6641:6654  "_name = name_" */ _5)
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                let data := keccak256(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _3)
                let deleteStart := add(data, shr(5, add(newLen, _8)))
                if lt(newLen, _3) { deleteStart := data }
                let _9 := add(data, shr(5, add(length, _8)))
                let start := deleteStart
                for { } lt(start, _9) { start := add(start, _7) }
                {
                    sstore(start, /** @src -1:-1:-1 */ 0)
                }
            }
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let srcOffset := /** @src -1:-1:-1 */ 0
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            srcOffset := _3
            switch gt(newLen, _8)
            case 1 {
                let loopEnd := and(newLen, not(31))
                mstore(/** @src -1:-1:-1 */ 0, /** @src 0:6641:6654  "_name = name_" */ _5)
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                let dstPtr := keccak256(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _3)
                let i := /** @src -1:-1:-1 */ 0
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                for { } lt(i, loopEnd) { i := add(i, _3) }
                {
                    sstore(dstPtr, mload(add(value0, srcOffset)))
                    dstPtr := add(dstPtr, _7)
                    srcOffset := add(srcOffset, _3)
                }
                if lt(loopEnd, newLen)
                {
                    let lastValue := mload(add(value0, srcOffset))
                    sstore(dstPtr, and(lastValue, not(shr(and(shl(/** @src 0:6641:6654  "_name = name_" */ _5, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ newLen), 248), not(0)))))
                }
                sstore(/** @src 0:6641:6654  "_name = name_" */ _5, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ add(shl(_7, newLen), _7))
            }
            default {
                let value_1 := /** @src -1:-1:-1 */ 0
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                if newLen
                {
                    value_1 := mload(add(value0, srcOffset))
                }
                sstore(/** @src 0:6641:6654  "_name = name_" */ _5, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ or(and(value_1, not(shr(shl(/** @src 0:6641:6654  "_name = name_" */ _5, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ newLen), not(0)))), shl(_7, newLen)))
            }
            let newLen_1 := mload(value1)
            if gt(newLen_1, _2)
            {
                mstore(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ shl(224, 0x4e487b71))
                mstore(/** @src 0:6664:6681  "_symbol = symbol_" */ 0x04, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x41)
                revert(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x24)
            }
            /// @src 0:6664:6681  "_symbol = symbol_"
            let _10 := 0x04
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let _11 := sload(/** @src 0:6664:6681  "_symbol = symbol_" */ _10)
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let length_1 := /** @src -1:-1:-1 */ 0
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            length_1 := shr(_7, _11)
            let outOfPlaceEncoding_1 := and(_11, _7)
            if iszero(outOfPlaceEncoding_1)
            {
                length_1 := and(length_1, 0x7f)
            }
            if eq(outOfPlaceEncoding_1, lt(length_1, _3))
            {
                mstore(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ shl(224, 0x4e487b71))
                mstore(/** @src 0:6664:6681  "_symbol = symbol_" */ _10, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x22)
                revert(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x24)
            }
            if gt(length_1, _8)
            {
                mstore(/** @src -1:-1:-1 */ 0, /** @src 0:6664:6681  "_symbol = symbol_" */ _10)
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                let data_1 := keccak256(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _3)
                let deleteStart_1 := add(data_1, shr(5, add(newLen_1, _8)))
                if lt(newLen_1, _3) { deleteStart_1 := data_1 }
                let _12 := add(data_1, shr(5, add(length_1, _8)))
                let start_1 := deleteStart_1
                for { } lt(start_1, _12) { start_1 := add(start_1, _7) }
                {
                    sstore(start_1, /** @src -1:-1:-1 */ 0)
                }
            }
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let srcOffset_1 := /** @src -1:-1:-1 */ 0
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            srcOffset_1 := _3
            switch gt(newLen_1, _8)
            case 1 {
                let loopEnd_1 := and(newLen_1, not(31))
                mstore(/** @src -1:-1:-1 */ 0, /** @src 0:6664:6681  "_symbol = symbol_" */ _10)
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                let dstPtr_1 := keccak256(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _3)
                let i_1 := /** @src -1:-1:-1 */ 0
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                for { } lt(i_1, loopEnd_1) { i_1 := add(i_1, _3) }
                {
                    sstore(dstPtr_1, mload(add(value1, srcOffset_1)))
                    dstPtr_1 := add(dstPtr_1, _7)
                    srcOffset_1 := add(srcOffset_1, _3)
                }
                if lt(loopEnd_1, newLen_1)
                {
                    let lastValue_1 := mload(add(value1, srcOffset_1))
                    sstore(dstPtr_1, and(lastValue_1, not(shr(and(shl(/** @src 0:6641:6654  "_name = name_" */ _5, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ newLen_1), 248), not(0)))))
                }
                sstore(/** @src 0:6664:6681  "_symbol = symbol_" */ _10, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ add(shl(_7, newLen_1), _7))
            }
            default {
                let value_2 := /** @src -1:-1:-1 */ 0
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                if newLen_1
                {
                    value_2 := mload(add(value1, srcOffset_1))
                }
                sstore(/** @src 0:6664:6681  "_symbol = symbol_" */ _10, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ or(and(value_2, not(shr(shl(/** @src 0:6641:6654  "_name = name_" */ _5, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ newLen_1), not(0)))), shl(_7, newLen_1)))
            }
            sstore(/** @src 0:17639:17641  "18" */ 0x05, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ or(and(sload(/** @src 0:17639:17641  "18" */ 0x05), /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ not(255)), _4))
            let _13 := mload(64)
            let _14 := datasize("ERC20Mock_751_deployed")
            codecopy(_13, dataoffset("ERC20Mock_751_deployed"), _14)
            return(_13, _14)
        }
        function allocate_memory(size) -> memPtr
        {
            memPtr := mload(64)
            let newFreePtr := add(memPtr, and(add(size, 31), not(31)))
            if or(gt(newFreePtr, sub(shl(64, 1), 1)), lt(newFreePtr, memPtr))
            {
                mstore(0, shl(224, 0x4e487b71))
                mstore(4, 0x41)
                revert(0, 0x24)
            }
            mstore(64, newFreePtr)
        }
        function abi_decode_string_fromMemory(offset, end) -> array
        {
            if iszero(slt(add(offset, 0x1f), end)) { revert(0, 0) }
            let _1 := mload(offset)
            if gt(_1, sub(shl(64, 1), 1))
            {
                mstore(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ shl(224, 0x4e487b71))
                mstore(4, 0x41)
                revert(/** @src -1:-1:-1 */ 0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x24)
            }
            let _2 := 0x20
            let array_1 := allocate_memory(add(and(add(_1, 0x1f), not(31)), _2))
            mstore(array_1, _1)
            if gt(add(add(offset, _1), _2), end)
            {
                revert(/** @src -1:-1:-1 */ 0, 0)
            }
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            let i := /** @src -1:-1:-1 */ 0
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            for { } lt(i, _1) { i := add(i, _2) }
            {
                mstore(add(add(array_1, i), _2), mload(add(add(offset, i), _2)))
            }
            mstore(add(add(array_1, _1), _2), /** @src -1:-1:-1 */ 0)
            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
            array := array_1
        }
    }
    /// @use-src 0:"ERC20.sol"
    object "ERC20Mock_751_deployed" {
        code {
            {
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                let _1 := memoryguard(0x80)
                let _2 := 64
                mstore(_2, _1)
                let _3 := 4
                if iszero(lt(calldatasize(), _3))
                {
                    let _4 := 0
                    switch shr(224, calldataload(_4))
                    case 0x06fdde03 {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _4) { revert(_4, _4) }
                        let ret := _4
                        let slotValue := sload(/** @src 0:6839:6844  "_name" */ 0x03)
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        let length := _4
                        let _5 := 1
                        length := shr(_5, slotValue)
                        let outOfPlaceEncoding := and(slotValue, _5)
                        if iszero(outOfPlaceEncoding) { length := and(length, 0x7f) }
                        let _6 := 32
                        if eq(outOfPlaceEncoding, lt(length, _6))
                        {
                            mstore(_4, shl(224, 0x4e487b71))
                            mstore(_3, 0x22)
                            revert(_4, 0x24)
                        }
                        mstore(_1, length)
                        switch outOfPlaceEncoding
                        case 0 {
                            mstore(add(_1, _6), and(slotValue, not(255)))
                            ret := add(add(_1, shl(5, iszero(iszero(length)))), _6)
                        }
                        case 1 {
                            mstore(_4, /** @src 0:6839:6844  "_name" */ 0x03)
                            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                            let dataPos := 87903029871075914254377627908054574944891091886930582284385770809450030037083
                            let i := _4
                            for { } lt(i, length) { i := add(i, _6) }
                            {
                                mstore(add(add(_1, i), _6), sload(dataPos))
                                dataPos := add(dataPos, _5)
                            }
                            ret := add(add(_1, i), _6)
                        }
                        let newFreePtr := add(_1, and(add(sub(ret, _1), 31), not(31)))
                        if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, _1))
                        {
                            mstore(_4, shl(224, 0x4e487b71))
                            mstore(_3, 0x41)
                            revert(_4, 0x24)
                        }
                        mstore(_2, newFreePtr)
                        return(newFreePtr, sub(abi_encode_string(newFreePtr, _1), newFreePtr))
                    }
                    case 0x095ea7b3 {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _2) { revert(_4, _4) }
                        let value0 := abi_decode_address_5631()
                        /// @src 0:9201:9207  "amount"
                        fun_approve(/** @src 0:4486:4496  "msg.sender" */ caller(), /** @src 0:9201:9207  "amount" */ value0, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ calldataload(36))
                        let memPos := mload(_2)
                        mstore(memPos, 1)
                        return(memPos, 32)
                    }
                    case 0x18160ddd {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _4) { revert(_4, _4) }
                        let _7 := sload(/** @src 0:7937:7949  "_totalSupply" */ 0x02)
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        let memPos_1 := mload(_2)
                        mstore(memPos_1, _7)
                        return(memPos_1, 32)
                    }
                    case 0x23b872dd {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), 96) { revert(_4, _4) }
                        let value0_1 := abi_decode_address_5631()
                        let value1 := abi_decode_address()
                        let value := calldataload(68)
                        mstore(_4, and(value0_1, sub(shl(160, 1), 1)))
                        mstore(32, 1)
                        let _8 := keccak256(_4, _2)
                        mstore(_4, /** @src 0:4486:4496  "msg.sender" */ caller())
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        mstore(32, _8)
                        let _9 := sload(keccak256(_4, _2))
                        /// @src 0:15835:16078  "if (currentAllowance != type(uint256).max) {..."
                        if /** @src 0:15839:15876  "currentAllowance != type(uint256).max" */ iszero(eq(_9, /** @src 0:15859:15876  "type(uint256).max" */ not(0)))
                        /// @src 0:15835:16078  "if (currentAllowance != type(uint256).max) {..."
                        {
                            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                            if /** @src 0:15900:15926  "currentAllowance >= amount" */ lt(_9, value)
                            /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                            {
                                let memPtr := mload(_2)
                                mstore(memPtr, shl(229, 4594637))
                                mstore(add(memPtr, _3), 32)
                                mstore(add(memPtr, 36), 29)
                                mstore(add(memPtr, 68), "ERC20: insufficient allowance")
                                revert(memPtr, 100)
                            }
                            /// @src 0:16027:16052  "currentAllowance - amount"
                            fun_approve(value0_1, /** @src 0:4486:4496  "msg.sender" */ caller(), /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ sub(/** @src 0:16027:16052  "currentAllowance - amount" */ _9, value))
                        }
                        /// @src 0:10019:10025  "amount"
                        fun_transfer(value0_1, value1, value)
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        let memPos_2 := mload(_2)
                        mstore(memPos_2, 1)
                        return(memPos_2, 32)
                    }
                    case 0x313ce567 {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _4) { revert(_4, _4) }
                        let value_1 := and(sload(/** @src 0:17956:17970  "customDecimals" */ 0x05), /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0xff)
                        let memPos_3 := mload(_2)
                        mstore(memPos_3, value_1)
                        return(memPos_3, 32)
                    }
                    case 0x39509351 {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _2) { revert(_4, _4) }
                        let value0_2 := abi_decode_address_5631()
                        mstore(_4, /** @src 0:4486:4496  "msg.sender" */ caller())
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        mstore(32, 1)
                        let _10 := keccak256(_4, _2)
                        mstore(_4, and(value0_2, sub(shl(160, 1), 1)))
                        mstore(32, _10)
                        /// @src 0:10616:10654  "allowance(owner, spender) + addedValue"
                        fun_approve(/** @src 0:4486:4496  "msg.sender" */ caller(), /** @src 0:10616:10654  "allowance(owner, spender) + addedValue" */ value0_2, checked_add_uint256(/** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ sload(keccak256(_4, _2)), calldataload(36)))
                        let memPos_4 := mload(_2)
                        mstore(memPos_4, 1)
                        return(memPos_4, 32)
                    }
                    case 0x40c10f19 {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _2) { revert(_4, _4) }
                        let value0_3 := abi_decode_address_5631()
                        let value_2 := calldataload(36)
                        let _11 := and(/** @src 0:13198:13219  "account != address(0)" */ value0_3, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ sub(shl(160, 1), 1))
                        if /** @src 0:13198:13219  "account != address(0)" */ iszero(/** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _11)
                        {
                            let memPtr_1 := mload(_2)
                            mstore(memPtr_1, shl(229, 4594637))
                            mstore(add(memPtr_1, _3), 32)
                            mstore(add(memPtr_1, 36), 31)
                            mstore(add(memPtr_1, 68), "ERC20: mint to the zero address")
                            revert(memPtr_1, 100)
                        }
                        sstore(/** @src 0:13326:13348  "_totalSupply += amount" */ 0x02, checked_add_uint256(/** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ sload(/** @src 0:13326:13348  "_totalSupply += amount" */ 0x02), value_2))
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        mstore(_4, _11)
                        mstore(32, _4)
                        let dataSlot := keccak256(_4, _2)
                        sstore(dataSlot, add(sload(/** @src 0:13494:13522  "_balances[account] += amount" */ dataSlot), /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ value_2))
                        /// @src 0:13547:13584  "Transfer(address(0), account, amount)"
                        let _12 := /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ mload(_2)
                        mstore(_12, value_2)
                        /// @src 0:13547:13584  "Transfer(address(0), account, amount)"
                        log3(_12, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 32, /** @src 0:13547:13584  "Transfer(address(0), account, amount)" */ 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _4, /** @src 0:13547:13584  "Transfer(address(0), account, amount)" */ _11)
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        return(_4, _4)
                    }
                    case 0x70a08231 {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), 32) { revert(_4, _4) }
                        mstore(_4, and(abi_decode_address_5631(), sub(shl(160, 1), 1)))
                        mstore(32, _4)
                        let _13 := sload(keccak256(_4, _2))
                        let memPos_5 := mload(_2)
                        mstore(memPos_5, _13)
                        return(memPos_5, 32)
                    }
                    case 0x95d89b41 {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _4) { revert(_4, _4) }
                        let memPtr_2 := mload(_2)
                        let ret_1 := _4
                        let slotValue_1 := sload(_3)
                        let length_1 := _4
                        let _14 := 1
                        length_1 := shr(_14, slotValue_1)
                        let outOfPlaceEncoding_1 := and(slotValue_1, _14)
                        if iszero(outOfPlaceEncoding_1)
                        {
                            length_1 := and(length_1, 0x7f)
                        }
                        let _15 := 32
                        if eq(outOfPlaceEncoding_1, lt(length_1, _15))
                        {
                            mstore(_4, shl(224, 0x4e487b71))
                            mstore(_3, 0x22)
                            revert(_4, 0x24)
                        }
                        mstore(memPtr_2, length_1)
                        switch outOfPlaceEncoding_1
                        case 0 {
                            mstore(add(memPtr_2, _15), and(slotValue_1, not(255)))
                            ret_1 := add(add(memPtr_2, shl(5, iszero(iszero(length_1)))), _15)
                        }
                        case 1 {
                            mstore(_4, _3)
                            let dataPos_1 := 62514009886607029107290561805838585334079798074568712924583230797734656856475
                            let i_1 := _4
                            for { } lt(i_1, length_1) { i_1 := add(i_1, _15) }
                            {
                                mstore(add(add(memPtr_2, i_1), _15), sload(dataPos_1))
                                dataPos_1 := add(dataPos_1, _14)
                            }
                            ret_1 := add(add(memPtr_2, i_1), _15)
                        }
                        let newFreePtr_1 := add(memPtr_2, and(add(sub(ret_1, memPtr_2), 31), not(31)))
                        if or(gt(newFreePtr_1, 0xffffffffffffffff), lt(newFreePtr_1, memPtr_2))
                        {
                            mstore(_4, shl(224, 0x4e487b71))
                            mstore(_3, 0x41)
                            revert(_4, 0x24)
                        }
                        mstore(_2, newFreePtr_1)
                        return(newFreePtr_1, sub(abi_encode_string(newFreePtr_1, memPtr_2), newFreePtr_1))
                    }
                    case 0xa457c2d7 {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _2) { revert(_4, _4) }
                        let value0_4 := abi_decode_address_5631()
                        let value_3 := calldataload(36)
                        mstore(_4, /** @src 0:4486:4496  "msg.sender" */ caller())
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        mstore(32, 1)
                        let _16 := keccak256(_4, _2)
                        mstore(_4, and(value0_4, sub(shl(160, 1), 1)))
                        mstore(32, _16)
                        let _17 := sload(keccak256(_4, _2))
                        if /** @src 0:11387:11422  "currentAllowance >= subtractedValue" */ lt(_17, value_3)
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        {
                            let memPtr_3 := mload(_2)
                            mstore(memPtr_3, shl(229, 4594637))
                            mstore(add(memPtr_3, _3), 32)
                            mstore(add(memPtr_3, 36), 37)
                            mstore(add(memPtr_3, 68), "ERC20: decreased allowance below")
                            mstore(add(memPtr_3, 100), " zero")
                            revert(memPtr_3, 132)
                        }
                        /// @src 0:11523:11557  "currentAllowance - subtractedValue"
                        fun_approve(/** @src 0:4486:4496  "msg.sender" */ caller(), /** @src 0:11523:11557  "currentAllowance - subtractedValue" */ value0_4, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ sub(/** @src 0:11523:11557  "currentAllowance - subtractedValue" */ _17, value_3))
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        let memPos_6 := mload(_2)
                        mstore(memPos_6, 1)
                        return(memPos_6, 32)
                    }
                    case 0xa9059cbb {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _2) { revert(_4, _4) }
                        let value0_5 := abi_decode_address_5631()
                        /// @src 0:8489:8495  "amount"
                        fun_transfer(/** @src 0:4486:4496  "msg.sender" */ caller(), /** @src 0:8489:8495  "amount" */ value0_5, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ calldataload(36))
                        let memPos_7 := mload(_2)
                        mstore(memPos_7, 1)
                        return(memPos_7, 32)
                    }
                    case 0xace28fa5 {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _4) { revert(_4, _4) }
                        let value_4 := and(sload(/** @src 0:17609:17641  "uint8 public customDecimals = 18" */ 5), /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0xff)
                        let memPos_8 := mload(_2)
                        mstore(memPos_8, value_4)
                        return(memPos_8, 32)
                    }
                    case 0xdd62ed3e {
                        if callvalue() { revert(_4, _4) }
                        if slt(add(calldatasize(), not(3)), _2) { revert(_4, _4) }
                        let value0_6 := abi_decode_address_5631()
                        let value1_1 := abi_decode_address()
                        let _18 := sub(shl(160, 1), 1)
                        mstore(_4, and(value0_6, _18))
                        mstore(32, /** @src 0:8697:8708  "_allowances" */ 0x01)
                        /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                        let _19 := keccak256(_4, _2)
                        mstore(_4, and(value1_1, _18))
                        mstore(32, _19)
                        let _20 := sload(keccak256(_4, _2))
                        let memPos_9 := mload(_2)
                        mstore(memPos_9, _20)
                        return(memPos_9, 32)
                    }
                }
                revert(0, 0)
            }
            function abi_encode_string(headStart, value0) -> tail
            {
                let _1 := 32
                mstore(headStart, _1)
                let length := mload(value0)
                mstore(add(headStart, _1), length)
                let i := 0
                for { } lt(i, length) { i := add(i, _1) }
                {
                    mstore(add(add(headStart, i), 64), mload(add(add(value0, i), _1)))
                }
                mstore(add(add(headStart, length), 64), 0)
                tail := add(add(headStart, and(add(length, 31), not(31))), 64)
            }
            function abi_decode_address_5631() -> value
            {
                value := calldataload(4)
                if iszero(eq(value, and(value, sub(shl(160, 1), 1)))) { revert(0, 0) }
            }
            function abi_decode_address() -> value
            {
                value := calldataload(36)
                if iszero(eq(value, and(value, sub(shl(160, 1), 1)))) { revert(0, 0) }
            }
            function checked_add_uint256(x, y) -> sum
            {
                sum := add(x, y)
                if gt(x, sum)
                {
                    mstore(0, shl(224, 0x4e487b71))
                    mstore(4, 0x11)
                    revert(0, 0x24)
                }
            }
            /// @ast-id 464 @src 0:12051:12839  "function _transfer(address from, address to, uint256 amount) internal virtual {..."
            function fun_transfer(var_from, var_to, var_amount)
            {
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                let _1 := sub(shl(160, 1), 1)
                let _2 := and(/** @src 0:12147:12165  "from != address(0)" */ var_from, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _1)
                if /** @src 0:12147:12165  "from != address(0)" */ iszero(/** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _2)
                {
                    let memPtr := mload(64)
                    mstore(memPtr, shl(229, 4594637))
                    mstore(add(memPtr, 4), 32)
                    mstore(add(memPtr, 36), 37)
                    mstore(add(memPtr, 68), "ERC20: transfer from the zero ad")
                    mstore(add(memPtr, 100), "dress")
                    revert(memPtr, 132)
                }
                let _3 := and(/** @src 0:12225:12241  "to != address(0)" */ var_to, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _1)
                if /** @src 0:12225:12241  "to != address(0)" */ iszero(/** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _3)
                {
                    let memPtr_1 := mload(64)
                    mstore(memPtr_1, shl(229, 4594637))
                    mstore(add(memPtr_1, 4), 32)
                    mstore(add(memPtr_1, 36), 35)
                    mstore(add(memPtr_1, 68), "ERC20: transfer to the zero addr")
                    mstore(add(memPtr_1, 100), "ess")
                    revert(memPtr_1, 132)
                }
                /// @src 0:12163:12164  "0"
                let _4 := 0x00
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                mstore(/** @src 0:12163:12164  "0" */ _4, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _2)
                mstore(0x20, /** @src 0:12163:12164  "0" */ _4)
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                let _5 := sload(keccak256(/** @src 0:12163:12164  "0" */ _4, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x40))
                if /** @src 0:12396:12417  "fromBalance >= amount" */ lt(_5, var_amount)
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                {
                    let memPtr_2 := mload(0x40)
                    mstore(memPtr_2, shl(229, 4594637))
                    mstore(add(memPtr_2, 4), 0x20)
                    mstore(add(memPtr_2, 36), 38)
                    mstore(add(memPtr_2, 68), "ERC20: transfer amount exceeds b")
                    mstore(add(memPtr_2, 100), "alance")
                    revert(memPtr_2, 132)
                }
                mstore(/** @src 0:12163:12164  "0" */ _4, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _2)
                mstore(0x20, /** @src 0:12163:12164  "0" */ _4)
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                sstore(keccak256(/** @src 0:12163:12164  "0" */ _4, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x40), sub(/** @src 0:12512:12532  "fromBalance - amount" */ _5, var_amount))
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                mstore(/** @src 0:12163:12164  "0" */ _4, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _3)
                let dataSlot := keccak256(/** @src 0:12163:12164  "0" */ _4, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x40)
                sstore(dataSlot, add(sload(/** @src 0:12709:12732  "_balances[to] += amount" */ dataSlot), /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ var_amount))
                /// @src 0:12758:12784  "Transfer(from, to, amount)"
                let _6 := /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ mload(0x40)
                mstore(_6, var_amount)
                /// @src 0:12758:12784  "Transfer(from, to, amount)"
                log3(_6, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x20, /** @src 0:12758:12784  "Transfer(from, to, amount)" */ 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, _2, _3)
            }
            /// @ast-id 638 @src 0:15052:15392  "function _approve(address owner, address spender, uint256 amount) internal virtual {..."
            function fun_approve(var_owner, var_spender, var_amount)
            {
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                let _1 := sub(shl(160, 1), 1)
                let _2 := and(/** @src 0:15153:15172  "owner != address(0)" */ var_owner, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _1)
                if /** @src 0:15153:15172  "owner != address(0)" */ iszero(/** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _2)
                {
                    let memPtr := mload(64)
                    mstore(memPtr, shl(229, 4594637))
                    mstore(add(memPtr, 4), 32)
                    mstore(add(memPtr, 36), 36)
                    mstore(add(memPtr, 68), "ERC20: approve from the zero add")
                    mstore(add(memPtr, 100), "ress")
                    revert(memPtr, 132)
                }
                let _3 := and(/** @src 0:15231:15252  "spender != address(0)" */ var_spender, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _1)
                if /** @src 0:15231:15252  "spender != address(0)" */ iszero(/** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _3)
                {
                    let memPtr_1 := mload(64)
                    mstore(memPtr_1, shl(229, 4594637))
                    mstore(add(memPtr_1, 4), 32)
                    mstore(add(memPtr_1, 36), 34)
                    mstore(add(memPtr_1, 68), "ERC20: approve to the zero addre")
                    mstore(add(memPtr_1, 100), "ss")
                    revert(memPtr_1, 132)
                }
                mstore(/** @src 0:15170:15171  "0" */ 0x00, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _2)
                mstore(0x20, /** @src 0:15302:15313  "_allowances" */ 0x01)
                /// @src 0:17575:17979  "contract ERC20Mock is ERC20 {..."
                let _4 := keccak256(/** @src 0:15170:15171  "0" */ 0x00, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x40)
                mstore(/** @src 0:15170:15171  "0" */ 0x00, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ _3)
                mstore(0x20, _4)
                sstore(keccak256(/** @src 0:15170:15171  "0" */ 0x00, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x40), var_amount)
                /// @src 0:15353:15385  "Approval(owner, spender, amount)"
                let _5 := /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ mload(0x40)
                mstore(_5, var_amount)
                /// @src 0:15353:15385  "Approval(owner, spender, amount)"
                log3(_5, /** @src 0:17575:17979  "contract ERC20Mock is ERC20 {..." */ 0x20, /** @src 0:15353:15385  "Approval(owner, spender, amount)" */ 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, _2, _3)
            }
        }
        data ".metadata" hex"a2646970667358221220bc4b2369e39006f408a031b1c7be0a93d81c694d0c24e917689ad1c04e845b8164736f6c63430008150033"
    }
}

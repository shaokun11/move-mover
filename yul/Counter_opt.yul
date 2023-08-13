/// @use-src 0:"contracts/Counter.sol"
object "Counter_14" {
    code {
        {
            /// @src 0:65:176  "contract Counter {..."
            mstore(64, memoryguard(0x80))
            if callvalue()
            {
                revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb()
            }
            let _1 := allocate_unbounded()
            let _2 := datasize("Counter_14_deployed")
            codecopy(_1, dataoffset("Counter_14_deployed"), _2)
            return(_1, _2)
        }
        function allocate_unbounded() -> memPtr
        {
            let memPtr_1 := mload(64)
            memPtr := memPtr_1
        }
        function revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb()
        { revert(0, 0) }
    }
    /// @use-src 0:"contracts/Counter.sol"
    object "Counter_14_deployed" {
        code {
            {
                /// @src 0:65:176  "contract Counter {..."
                mstore(64, memoryguard(0x80))
                if iszero(lt(calldatasize(), 4))
                {
                    let selector := shift_right_unsigned(calldataload(0))
                    switch selector
                    case 0x06661abd { external_fun_count() }
                    case 0xe8927fbc { external_fun_increase() }
                }
                revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74()
            }
            function shift_right_unsigned(value) -> newValue
            { newValue := shr(224, value) }
            function allocate_unbounded() -> memPtr
            {
                let memPtr_1 := mload(64)
                memPtr := memPtr_1
            }
            function revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb()
            { revert(0, 0) }
            function revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b()
            { revert(0, 0) }
            function abi_decode(headStart, dataEnd)
            {
                if slt(sub(dataEnd, headStart), 0)
                {
                    revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b()
                }
            }
            function shift_right_unsigned_dynamic(bits, value) -> newValue
            { newValue := shr(bits, value) }
            function cleanup_from_storage_uint256(value) -> cleaned
            { cleaned := value }
            function extract_from_storage_value_dynamict_uint256(slot_value, offset) -> value
            {
                let _1 := shift_right_unsigned_dynamic(shl(3, offset), slot_value)
                let value_1 := cleanup_from_storage_uint256(_1)
                value := value_1
            }
            function read_from_storage_split_dynamic_uint256(slot, offset) -> value
            {
                let _1 := sload(slot)
                let value_1 := extract_from_storage_value_dynamict_uint256(_1, offset)
                value := value_1
            }
            /// @ast-id 3 @src 0:88:105  "uint public count"
            function getter_fun_count() -> ret
            {
                let ret_1 := read_from_storage_split_dynamic_uint256(0, 0)
                ret := ret_1
            }
            /// @src 0:65:176  "contract Counter {..."
            function cleanup_uint256(value) -> cleaned
            { cleaned := value }
            function abi_encode_uint256_to_uint256(value, pos)
            {
                let _1 := cleanup_uint256(value)
                mstore(pos, _1)
            }
            function abi_encode_uint256(headStart, value0) -> tail
            {
                tail := add(headStart, 32)
                abi_encode_uint256_to_uint256(value0, headStart)
            }
            function external_fun_count()
            {
                if callvalue()
                {
                    revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb()
                }
                abi_decode(4, calldatasize())
                let ret := getter_fun_count()
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_uint256(memPos, ret)
                return(memPos, sub(memEnd, memPos))
            }
            function abi_encode_tuple(headStart) -> tail
            { tail := headStart }
            function external_fun_increase()
            {
                if callvalue()
                {
                    revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb()
                }
                abi_decode(4, calldatasize())
                fun_increase()
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_tuple(memPos)
                return(memPos, sub(memEnd, memPos))
            }
            function revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74()
            { revert(0, 0) }
            function shift_right_0_unsigned(value) -> newValue
            { newValue := value }
            function extract_from_storage_value_offsett_uint256(slot_value) -> value
            {
                let _1 := shift_right_0_unsigned(slot_value)
                let value_1 := cleanup_from_storage_uint256(_1)
                value := value_1
            }
            function read_from_storage_split_offset_uint256(slot) -> value
            {
                let _1 := sload(slot)
                let value_1 := extract_from_storage_value_offsett_uint256(_1)
                value := value_1
            }
            function cleanup_rational_by(value) -> cleaned
            { cleaned := value }
            function identity(value) -> ret
            { ret := value }
            function convert_rational_by_to_uint256(value) -> converted
            {
                let _1 := cleanup_rational_by(value)
                let _2 := identity(_1)
                let converted_1 := cleanup_uint256(_2)
                converted := converted_1
            }
            function panic_error_0x11()
            {
                mstore(0, shl(224, 0x4e487b71))
                mstore(4, 0x11)
                revert(0, 0x24)
            }
            function checked_add_uint256(x, y) -> sum
            {
                let x_1 := cleanup_uint256(x)
                let y_1 := cleanup_uint256(y)
                let sum_1 := add(x_1, y_1)
                sum := sum_1
                if gt(x_1, sum_1) { panic_error_0x11() }
            }
            function shift_left(value) -> newValue
            { newValue := value }
            function update_byte_slice_shift(value, toInsert) -> result
            {
                let toInsert_1 := shift_left(toInsert)
                result := toInsert_1
            }
            function convert_uint256_to_uint256(value) -> converted
            {
                let _1 := cleanup_uint256(value)
                let _2 := identity(_1)
                let converted_1 := cleanup_uint256(_2)
                converted := converted_1
            }
            function prepare_store_uint256(value) -> ret
            { ret := value }
            function update_storage_value_offsett_uint256_to_uint256(slot, value)
            {
                let convertedValue := convert_uint256_to_uint256(value)
                let _1 := prepare_store_uint256(convertedValue)
                let _2 := sload(slot)
                let _3 := update_byte_slice_shift(_2, _1)
                sstore(slot, _3)
            }
            /// @ast-id 13 @src 0:112:174  "function increase() public  {..."
            function fun_increase()
            {
                /// @src 0:158:163  "count"
                let _1 := read_from_storage_split_offset_uint256(0x00)
                /// @src 0:158:167  "count + 1"
                let _2 := convert_rational_by_to_uint256(/** @src 0:166:167  "1" */ 0x01)
                /// @src 0:158:167  "count + 1"
                let expr := checked_add_uint256(_1, _2)
                /// @src 0:150:167  "count = count + 1"
                update_storage_value_offsett_uint256_to_uint256(/** @src 0:158:163  "count" */ 0x00, /** @src 0:150:167  "count = count + 1" */ expr)
            }
        }
        data ".metadata" hex"a26469706673582212200cd5c79e7717d3ad4da382751eb78be58e2b4d5cc8dd3e505d3f654d3dfdce3b64736f6c63430008150033"
    }
}

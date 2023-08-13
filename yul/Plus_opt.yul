/// @use-src 0:"Plus.sol"
object "Plus_16" {
    code {
        {
            /// @src 0:64:171  "contract Plus {..."
            mstore(64, memoryguard(0x80))
            if callvalue()
            {
                revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb()
            }
            let _1 := allocate_unbounded()
            codecopy(_1, dataoffset("Plus_16_deployed"), datasize("Plus_16_deployed"))
            return(_1, datasize("Plus_16_deployed"))
        }
        function allocate_unbounded() -> memPtr
        { memPtr := mload(64) }
        function revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb()
        { revert(0, 0) }
    }
    /// @use-src 0:"Plus.sol"
    object "Plus_16_deployed" {
        code {
            {
                /// @src 0:64:171  "contract Plus {..."
                mstore(64, memoryguard(0x80))
                if iszero(lt(calldatasize(), 4))
                {
                    let selector := shift_right_unsigned(calldataload(0))
                    switch selector
                    case 0x66098d4f { external_fun_plus() }
                    default { }
                }
                revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74()
            }
            function shift_right_unsigned(value) -> newValue
            { newValue := shr(224, value) }
            function allocate_unbounded() -> memPtr
            { memPtr := mload(64) }
            function revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb()
            { revert(0, 0) }
            function revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b()
            { revert(0, 0) }
            function cleanup_uint256(value) -> cleaned
            { cleaned := value }
            function validator_revert_uint256(value)
            {
                if iszero(eq(value, cleanup_uint256(value))) { revert(0, 0) }
            }
            function abi_decode_uint256(offset, end) -> value
            {
                value := calldataload(offset)
                validator_revert_uint256(value)
            }
            function abi_decode_uint256t_uint256(headStart, dataEnd) -> value0, value1
            {
                if slt(sub(dataEnd, headStart), 64)
                {
                    revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b()
                }
                let offset := 0
                value0 := abi_decode_uint256(add(headStart, offset), dataEnd)
                let offset_1 := 32
                value1 := abi_decode_uint256(add(headStart, offset_1), dataEnd)
            }
            function abi_encode_uint256_to_uint256(value, pos)
            {
                mstore(pos, cleanup_uint256(value))
            }
            function abi_encode_uint256(headStart, value0) -> tail
            {
                tail := add(headStart, 32)
                abi_encode_uint256_to_uint256(value0, add(headStart, 0))
            }
            function external_fun_plus()
            {
                if callvalue()
                {
                    revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb()
                }
                let param, param_1 := abi_decode_uint256t_uint256(4, calldatasize())
                let ret := fun_plus(param, param_1)
                let memPos := allocate_unbounded()
                let memEnd := abi_encode_uint256(memPos, ret)
                return(memPos, sub(memEnd, memPos))
            }
            function revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74()
            { revert(0, 0) }
            function zero_value_for_split_uint256() -> ret
            { ret := 0 }
            function panic_error_0x11()
            {
                mstore(0, shl(224, 0x4e487b71))
                mstore(4, 0x11)
                revert(0, 0x24)
            }
            function checked_add_uint256(x, y) -> sum
            {
                x := cleanup_uint256(x)
                y := cleanup_uint256(y)
                sum := add(x, y)
                if gt(x, sum) { panic_error_0x11() }
            }
            /// @ast-id 15 @src 0:84:169  "function plus(uint a, uint b) pure public returns(uint) {..."
            function fun_plus(var_a, var_b) -> var
            {
                /// @src 0:134:138  "uint"
                let zero_uint256 := zero_value_for_split_uint256()
                var := zero_uint256
                /// @src 0:157:158  "a"
                let _1 := var_a
                let expr := _1
                /// @src 0:161:162  "b"
                let _2 := var_b
                let expr_1 := _2
                /// @src 0:157:162  "a + b"
                let expr_2 := checked_add_uint256(expr, expr_1)
                /// @src 0:150:162  "return a + b"
                var := expr_2
                leave
            }
        }
        data ".metadata" hex"a2646970667358221220907a667e0a7cf07999f26cd83bd76607080557de680a4dc645ba664cc554a4e264736f6c63430008150033"
    }
}

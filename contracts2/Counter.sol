// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.5.16;
contract CounterB {
    address constant public CounterA = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    uint public count;

    function increase() public  {
        (bool success, bytes memory data) = CounterA.delegatecall(abi.encodeWithSignature("increase()"));
    }
}
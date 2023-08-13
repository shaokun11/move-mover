// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

contract Counter2 {
    uint public counts = 1;
    uint8 c1 = 0;
    uint8 c2 = 0;

    function increase() public  {
        counts = counts + 1;
        c1 = c1 + 1;
        c2 = c2 + 1;
    }
}
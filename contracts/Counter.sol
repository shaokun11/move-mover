// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

contract Counter {
    uint public count;

    function increase(uint num) public  {
        count = count + num;
    }
}
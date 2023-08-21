// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

contract Counter {
    uint public count;

    function increase(uint num) public  {
        count = count + num;
    }

    function twoValue(uint a, uint b) public pure returns(uint, uint){
        return (a+b, a*b);
    }
}
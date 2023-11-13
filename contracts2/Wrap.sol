// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract WarpMessage {
    event SendWarpMessage(
        bytes32 indexed destinationChainID,
        address indexed destinationAddress,
        address indexed sender,
        bytes message
    );

    function sendWarpMessage(
        bytes32 destinationChainID,
        address destinationAddress,
        bytes calldata payload
    ) external {
        emit SendWarpMessage (destinationChainID, destinationAddress, msg.sender, payload);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWormhole {
    function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel) external payable returns (uint64 sequence);
    function verifyVM(bytes memory encodedVM) external view returns (bool valid, string memory reason);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITokenRegistry {
    function register(bytes32 assetId, address token) external;
    function getWrapped(bytes32 assetId) external view returns (address);
}

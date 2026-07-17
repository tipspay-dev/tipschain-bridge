// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ITokenRegistry.sol";

contract TokenRegistry is ITokenRegistry {
    mapping(bytes32 => address) private wrappedTokens;

    event Registered(bytes32 indexed assetId, address token);

    function register(bytes32 assetId, address token) external override {
        wrappedTokens[assetId] = token;
        emit Registered(assetId, token);
    }

    function getWrapped(bytes32 assetId) external view override returns (address) {
        return wrappedTokens[assetId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokenRegistry.sol";
import "./IWormhole.sol";

contract Bridge is UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    ITokenRegistry public registry;
    IWormhole public wormhole;
    uint8 public consistencyLevel;

    event Deposited(address indexed token, uint256 amount, uint256 targetChainId, address recipient, uint64 sequence);
    event Released(bytes32 indexed assetId, uint256 amount, address recipient, uint64 sequence);
    event Burned(bytes32 indexed assetId, uint256 amount, address recipient, uint64 sequence);

    function initialize(address _registry, address _wormhole, uint8 _consistencyLevel) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        registry = ITokenRegistry(_registry);
        wormhole = IWormhole(_wormhole);
        consistencyLevel = _consistencyLevel;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function deposit(address token, uint256 amount, uint256 targetChainId, address recipient) external payable {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        bytes memory payload = abi.encode(token, amount, recipient, targetChainId);
        uint64 sequence = wormhole.publishMessage(0, payload, consistencyLevel);
        emit Deposited(token, amount, targetChainId, recipient, sequence);
    }

    function release(bytes32 assetId, uint256 amount, address recipient, bytes calldata encodedVM)
        external
        onlyRole(VALIDATOR_ROLE)
    {
        (bool valid, ) = wormhole.verifyVM(encodedVM);
        require(valid, "Invalid Wormhole message");

        address wrapped = registry.getWrapped(assetId);
        IERC20(wrapped).transfer(recipient, amount);

        emit Released(assetId, amount, recipient, 0);
    }

    function burn(bytes32 assetId, uint256 amount, uint256 targetChainId, address recipient) external payable {
        address wrapped = registry.getWrapped(assetId);
        IERC20(wrapped).transferFrom(msg.sender, address(this), amount);
        // wrapped token burn fonksiyonu çağrılmalı

        bytes memory payload = abi.encode(assetId, amount, recipient, targetChainId);
        uint64 sequence = wormhole.publishMessage(0, payload, consistencyLevel);
        emit Burned(assetId, amount, recipient, sequence);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokenRegistry.sol";
import "./IMessageBus.sol";

contract Bridge is UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    ITokenRegistry public registry;
    IMessageBus public messageBus;

    event Deposited(address indexed token, uint256 amount, uint256 targetChainId, address recipient, bytes32 msgId);
    event Released(bytes32 indexed assetId, uint256 amount, address recipient, bytes32 msgId);
    event Burned(bytes32 indexed assetId, uint256 amount, address recipient, bytes32 msgId);

    function initialize(address _registry, address _messageBus) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        registry = ITokenRegistry(_registry);
        messageBus = IMessageBus(_messageBus);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function deposit(
        address token,
        uint256 amount,
        uint256 targetChainId,
        address recipient
    ) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        bytes memory payload = abi.encode(token, amount, recipient);
        bytes32 msgId = messageBus.sendMessage(targetChainId, recipient, payload);

        emit Deposited(token, amount, targetChainId, recipient, msgId);
    }

    function release(
        bytes32 assetId,
        uint256 amount,
        address recipient,
        bytes calldata payload,
        bytes calldata signature,
        uint256 srcChainId
    ) external onlyRole(VALIDATOR_ROLE) {
        bytes32 msgId = keccak256(payload);

        require(
            messageBus.verifyMessage(msgId, srcChainId, block.chainid, recipient, payload, signature),
            "Invalid cross-chain message"
        );

        address wrapped = registry.getWrapped(assetId);
        IERC20(wrapped).transfer(recipient, amount);

        emit Released(assetId, amount, recipient, msgId);
    }

    function burn(
        bytes32 assetId,
        uint256 amount,
        uint256 targetChainId,
        address recipient
    ) external {
        address wrapped = registry.getWrapped(assetId);
        IERC20(wrapped).transferFrom(msg.sender, address(this), amount);
        // wrapped token burn fonksiyonu çağrılmalı (mintable/burnable interface ile)

        bytes memory payload = abi.encode(assetId, amount, recipient);
        bytes32 msgId = messageBus.sendMessage(targetChainId, recipient, payload);

        emit Burned(assetId, amount, recipient, msgId);
    }
}

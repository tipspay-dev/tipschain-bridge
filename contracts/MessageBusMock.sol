// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IMessageBus.sol";

contract MessageBusMock is IMessageBus {
    struct Message {
        uint256 srcChainId;
        uint256 dstChainId;
        address sender;
        address recipient;
        bytes payload;
        bytes signature;
        bool delivered;
    }

    mapping(bytes32 => Message) public messages;

    function sendMessage(
        uint256 dstChainId,
        address recipient,
        bytes calldata payload
    ) external override returns (bytes32) {
        bytes32 msgId = keccak256(
            abi.encodePacked(msg.sender, dstChainId, recipient, payload, block.timestamp)
        );

        messages[msgId] = Message({
            srcChainId: block.chainid,
            dstChainId: dstChainId,
            sender: msg.sender,
            recipient: recipient,
            payload: payload,
            signature: "",
            delivered: false
        });

        emit MessageSent(msgId, block.chainid, dstChainId, msg.sender, payload);
        return msgId;
    }

    function verifyMessage(
        bytes32 msgId,
        uint256 srcChainId,
        uint256 dstChainId,
        address recipient,
        bytes calldata payload,
        bytes calldata signature
    ) external view override returns (bool) {
        Message storage m = messages[msgId];
        return (
            m.srcChainId == srcChainId &&
            m.dstChainId == dstChainId &&
            m.recipient == recipient &&
            keccak256(m.payload) == keccak256(payload)
        );
    }

    // Test helper: mark message as delivered
    function deliverMessage(bytes32 msgId, bytes calldata signature) external {
        Message storage m = messages[msgId];
        require(!m.delivered, "Already delivered");
        m.signature = signature;
        m.delivered = true;

        emit MessageReceived(msgId, m.srcChainId, m.dstChainId, m.recipient, m.payload);
    }
}

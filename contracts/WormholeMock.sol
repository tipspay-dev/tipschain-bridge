// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IWormhole.sol";

contract WormholeMock is IWormhole {
    struct VM {
        bool valid;
        uint256 srcChainId;
        uint256 dstChainId;
        address sender;
        bytes payload;
    }

    mapping(uint64 => VM) public vms;
    uint64 public nextSequence;

    event MockMessagePublished(uint64 indexed sequence, uint256 srcChainId, uint256 dstChainId, address sender, bytes payload);

    constructor() {
        nextSequence = 1;
    }

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable override returns (uint64 sequence) {
        sequence = nextSequence++;
        vms[sequence] = VM({
            valid: true,
            srcChainId: block.chainid,
            dstChainId: 0, // test ortamında dummy
            sender: msg.sender,
            payload: payload
        });

        emit MockMessagePublished(sequence, block.chainid, 0, msg.sender, payload);
    }

    function verifyVM(bytes memory encodedVM)
        external
        view
        override
        returns (bool valid, string memory reason)
    {
        // encodedVM → sequence ID olarak kabul edelim
        uint64 seq;
        assembly {
            seq := mload(add(encodedVM, 32))
        }

        VM storage vm = vms[seq];
        if (vm.valid) {
            return (true, "");
        } else {
            return (false, "Invalid VM");
        }
    }

    // Test helper: invalidate a VM
    function invalidateVM(uint64 seq) external {
        vms[seq].valid = false;
    }
}

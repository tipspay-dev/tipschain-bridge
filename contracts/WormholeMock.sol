// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IWormhole.sol";

contract WormholeMock is IWormhole {
    struct VM {
        bool valid;
        bytes payload;
    }

    mapping(uint64 => VM) public vms;
    uint64 public nextSequence;

    event MockMessagePublished(uint64 indexed sequence, bytes payload);

    constructor() {
        nextSequence = 1;
    }

    function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel)
        external
        payable
        override
        returns (uint64 sequence)
    {
        sequence = nextSequence++;
        vms[sequence] = VM({valid: true, payload: payload});
        emit MockMessagePublished(sequence, payload);
    }

    function verifyVM(bytes memory encodedVM) external view override returns (bool valid, string memory reason) {
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

    function invalidateVM(uint64 seq) external {
        vms[seq].valid = false;
    }
}

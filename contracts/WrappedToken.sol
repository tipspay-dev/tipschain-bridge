// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WrappedToken is ERC20BurnableUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Burnable_init();
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

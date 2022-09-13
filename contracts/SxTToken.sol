// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error NotMinter();
error MaxSupplyOverflow();
error Blacklisted();

contract SXTToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 10 ** 27;

    mapping (address => bool) public minters;

    mapping (address => bool) public blacklisted;

    constructor() ERC20("Space and Time Token", "SXT") {
        addMinter(_msgSender());
    }

    // --- Owner Functions ---
    function addMinter(address _who) public onlyOwner {
        minters[_who] = true;
    }

    function revokeMinter(address _who) public onlyOwner {
        minters[_who] = false;
    }

    function blacklist(address _who) public onlyOwner {
        blacklisted[_who] = true;
        emit Blacklist(_who, true);
    }

    function unblacklist(address _who) public onlyOwner {
        blacklisted[_who] = false;
        emit Blacklist(_who, false);
    }

    function bulkBlacklist(address[] calldata _addresses) external onlyOwner {
        uint256 length = _addresses.length;
        for (uint256 i = 0; i < length; i ++) {
            blacklist(_addresses[i]);
        }
    }

    function bulkUnblacklist(address[] calldata _addresses) external onlyOwner {
        uint256 length = _addresses.length;
        for (uint256 i = 0; i < length; i ++) {
            unblacklist(_addresses[i]);
        }
    }

    // --- Minter Functions ---
    function mint(address _who, uint256 _amount) external onlyMinter {
        if (totalSupply() + _amount > MAX_SUPPLY) revert MaxSupplyOverflow();
        _mint(_who, _amount);
    }

    // --- Internal Functions ---
    function _beforeTokenTransfer(address _from, address _to, uint256) internal override view {
        if (blacklisted[_from] || blacklisted[_to]) revert Blacklisted();
    }

    modifier onlyMinter() {
        if (!minters[_msgSender()]) revert NotMinter();
        _;
    }

    event Blacklist(address who, bool isBlacklisted);
}

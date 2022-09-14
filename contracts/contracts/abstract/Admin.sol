// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Admin {
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "admin only function");
        _;
    }

    function getAdmin() public view returns (address adminAddress) {
        return admin;
    }

    function setAdmin(address adminAddress) public onlyAdmin {
        admin = adminAddress;
    }

    function adminCall(address target, bytes calldata data)
        external
        payable
        onlyAdmin
    {
        assembly {
            calldatacopy(0, data.offset, data.length)
            let result := call(gas(), target, callvalue(), 0, data.length, 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

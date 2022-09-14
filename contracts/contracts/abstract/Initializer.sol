// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error AlreadyInitialized();

abstract contract Initializer {
    bool private _isInitialized;

    modifier initializer() {
        if (_isInitialized) revert AlreadyInitialized();
        _;
        _isInitialized = true;
    }
}

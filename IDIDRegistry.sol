// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IDIDRegistry {
    event DIDAttributeChanged(
        address indexed identity,
        bytes32 name,
        bytes value,
        uint256 validTo,
        uint256 previousChange
    );

    function register(string calldata _domain, address _subject) external;

    function deactivate(string calldata _domain, address _subject) external;

    function isActive(string calldata _domain, address _subject)
        external
        view
        returns (bool status);

    function isActive(bytes32 credential) external view returns (bool status);

    function setAttribute(
        address identity,
        bytes32 name,
        bytes calldata value,
        uint256 validity
    ) external;
}

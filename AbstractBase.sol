// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract AbstractBase is Initializable, OwnableUpgradeable {
    error CONTRACT_SUSPENDED();
    error TRANSFER_FAILED();
    error INVALID_FORWARDER();

    bool public isPaused;
    address public trustedForwarder;

    /**
     * @notice Allows updating the trusted forwarder to another for this contract
     */
    function setTrustedForwarder(address _trustedForwarder)
        external
        virtual
        onlyOwner
        confirmForwarder
    {
        trustedForwarder = _trustedForwarder;
    }

    /**
     * @notice Allows pausing of the operation of this contract.
     */
    function setPause(bool _pause) external virtual onlyOwner confirmForwarder {
        isPaused = _pause;
    }

    /**
     * @notice Transfers contract Ether balance to a given address.
     */
    function recoverBalance(address payable _destination)
        external
        virtual
        onlyOwner
        confirmForwarder
    {
        (bool success, ) = _destination.call{value: address(this).balance}("");

        if (!success) {
            revert TRANSFER_FAILED();
        }
    }

    /**
     * @notice Transfers ERC20 balance owned by the contract to a given address.
     */
    function recoverTokenBalance(
        IERC20 _token,
        uint256 _amount,
        address _destination
    ) external virtual onlyOwner confirmForwarder {
        bool success = _token.transfer(_destination, _amount);

        if (!success) {
            revert TRANSFER_FAILED();
        }
    }

    /**
     * @notice ERC2771 support. Taken from openzeppelin/ERC2771Context 4.7.3.
     */
    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == trustedForwarder;
    }

    /**
     * @notice ERC2771 support. Taken from openzeppelin/ERC2771Context 4.7.3.
     */
    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    /**
     * @notice ERC2771 support. Taken from openzeppelin/ERC2771Context 4.7.3.
     */
    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @notice Check that contract is not paused.
     */
    modifier whileActive() virtual {
        if (isPaused) {
            revert CONTRACT_SUSPENDED();
        }

        _;
    }

    /**
     * @notice Support for ERC2771. This method only does rudimentary address checking against a known-good sender address that is expected to be set in a constructor or initializer of the implementing contract.
     */
    modifier confirmForwarder() virtual {
        if (trustedForwarder != address(0) && msg.sender != trustedForwarder) {
            revert INVALID_FORWARDER();
        }

        _;
    }
}

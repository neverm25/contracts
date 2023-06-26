// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "contracts/interfaces/IBribeFactory.sol";
import 'contracts/InternalBribe.sol';
import 'contracts/ExternalBribe.sol';

contract BribeFactory is IBribeFactory {
    address public last_internal_bribe;
    address public last_external_bribe;
    address[] private _internal_bribes;
    address[] private _external_bribes;

    event BribeCreated(address bribe, address[] allowedRewards);

    function createInternalBribe(address[] memory allowedRewards) external returns (address) {
        last_internal_bribe = address(new InternalBribe(msg.sender, allowedRewards));
        _internal_bribes.push(last_internal_bribe);
        emit BribeCreated(last_internal_bribe, allowedRewards);
        return last_internal_bribe;
    }

    function createExternalBribe(address[] memory allowedRewards) external returns (address) {
        last_external_bribe = address(new ExternalBribe(msg.sender, allowedRewards));
        _external_bribes.push(last_external_bribe);
        emit BribeCreated(last_external_bribe, allowedRewards);
        return last_external_bribe;
    }

    function getInternalBribes() external view returns (address[] memory) {
        return _internal_bribes;
    }


    function getExternalBribes() external view returns (address[] memory) {
        return _external_bribes;
    }


}

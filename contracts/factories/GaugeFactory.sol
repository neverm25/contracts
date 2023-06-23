// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import 'contracts/interfaces/IGaugeFactory.sol';
import 'contracts/Gauge.sol';

import '../GaugeV2_CL.sol';
import "../CLFeesVault.sol";

contract GaugeFactory is IGaugeFactory {
    address public last_gauge;
    address public last_feeVault;
    address[] private _nativeGauges;
    address[] private _algebraGauges;
    address public gammaFeeRecipient;

    event GaugeCreated(address indexed gauge, address indexed pool, address indexed internal_bribe, address external_bribe, address ve, bool isPair, address[] allowedRewards, bool isAlgebra);

    constructor( address _gammaFeeRecipient ) {
        require(_gammaFeeRecipient != address(0), "zero address");
        gammaFeeRecipient = _gammaFeeRecipient;
    }

    function createGauge(address _pool, address _internal_bribe, address _external_bribe, address _ve, bool isPair, address[] memory allowedRewards) external returns (address) {
        last_gauge = address(new Gauge(_pool, _internal_bribe, _external_bribe, _ve, msg.sender, isPair, allowedRewards, false));
        _nativeGauges.push(last_gauge);
        emit GaugeCreated(last_gauge, _pool, _internal_bribe, _external_bribe, _ve, isPair, allowedRewards, false);
        return last_gauge;
    }
    function createGaugeOnAlgebra(address _rewardToken, address _distribution, address _pool, address _internal_bribe, address _external_bribe, address _ve, bool isPair, address[] memory allowedRewards) external returns (address) {
        last_feeVault = address( new CLFeesVault(_token, _distribution, gammaFeeRecipient) );
        last_gauge = address(new Gauge(_pool, _internal_bribe, _external_bribe, _ve, msg.sender, isPair, allowedRewards, true));
        _algebraGauges.push(last_gauge);
        emit GaugeCreated(last_gauge, _pool, _internal_bribe, _external_bribe, _ve, isPair, allowedRewards, true);
        return last_gauge;
    }
    function getAllNativeGauges() external view returns (address[] memory) {
        return _nativeGauges;
    }
    function getNativeGauge(uint256 index) external view returns (address) {
        return _nativeGauges[index];
    }
    function getNativeGaugesLength() external view returns (uint256) {
        return _nativeGauges.length;
    }
    function getAllAlgebraGauges() external view returns (address[] memory) {
        return _algebraGauges;
    }
    function getAlgebraGauge(uint256 index) external view returns (address) {
        return _algebraGauges[index];
    }
    function getAlgebraGaugesLength() external view returns (uint256) {
        return _algebraGauges.length;
    }
    function setGammaFeeRecipient(address _gammaFeeRecipient) external onlyOwner {
        require(_gammaFeeRecipient != address(0), "zero address");
        gammaFeeRecipient = _gammaFeeRecipient;
    }
}

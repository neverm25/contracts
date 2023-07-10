// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import 'contracts/interfaces/IGaugeFactory.sol';
import 'contracts/Gauge.sol';
import "contracts/CLFeesVault.sol";

contract GaugeFactory is IGaugeFactory {
    address public last_gauge;
    address public last_feeVault;
    address[] private _gauges;
    address public pairFactory;
    bool public isAlgebra;
    address public liquidityManager;

    event GaugeCreated(address indexed gauge, address indexed pool, address indexed internal_bribe, address external_bribe, address ve, bool isPair, address[] allowedRewards, bool isAlgebra);

    constructor( bool _isAlgebra, address _liquidityManager, address _pairFactory ){
        require( _pairFactory != address(0), "PairFactory: ZERO_ADDRESS" );
        require( _liquidityManager != address(0), "LiquidityManager: ZERO_ADDRESS" );
        isAlgebra = _isAlgebra;
        liquidityManager = _liquidityManager;
        pairFactory = _pairFactory;
        IPairFactory(_pairFactory).allPairsLength();
    }

    function createGauge(address _pool, address _internal_bribe, address _external_bribe, address _ve, bool isPair, address[] memory allowedRewards) external returns (address) {
        last_gauge = address( new Gauge(isAlgebra, liquidityManager, _pool, _internal_bribe, _external_bribe, _ve, msg.sender, isPair, allowedRewards, address(0)) );
        _gauges.push(last_gauge);
        emit GaugeCreated(last_gauge, _pool, _internal_bribe, _external_bribe, _ve, isPair, allowedRewards, true);
        return last_gauge;
    }
    function createGaugeOnAlgebra(address _voter, address _pool, address _internal_bribe, address _external_bribe, address _ve, bool isPair, address[] memory allowedRewards) external returns (address) {
        last_feeVault = address( new CLFeesVault(_pool, pairFactory, _voter) );
        last_gauge = address(new Gauge(isAlgebra, liquidityManager, _pool, _internal_bribe,
            _external_bribe, _ve, msg.sender, isPair,
            allowedRewards, last_feeVault));
        _gauges.push(last_gauge);
        emit GaugeCreated(last_gauge, _pool, _internal_bribe, _external_bribe, _ve, isPair, allowedRewards, true);
        return last_gauge;
    }
    function getAllNativeGauges() external view returns (address[] memory) {
        return _gauges;
    }
    function getNativeGauge(uint256 index) external view returns (address) {
        return _gauges[index];
    }
    function getNativeGaugesLength() external view returns (uint256) {
        return _gauges.length;
    }
    function getAllAlgebraGauges() external view returns (address[] memory) {
        return _gauges;
    }
    function getAlgebraGauge(uint256 index) external view returns (address) {
        return _gauges[index];
    }
    function getAlgebraGaugesLength() external view returns (uint256) {
        return _gauges.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

interface IGaugeFactory {
    function last_gauge() external view returns (address);
    function last_feeVault() external view returns (address);
    function pairFactory() external view returns (address);
    function createGauge(address _pool, address _internal_bribe, address _external_bribe, address _ve, bool isPair, address[] memory allowedRewards) external returns (address);
    function createGaugeOnAlgebra(address _voter, address _pool, address _internal_bribe, address _external_bribe, address _ve, bool isPair, address[] memory allowedRewards) external returns (address);
    function getAllNativeGauges() external view returns (address[] memory);
    function getNativeGauge(uint256 index) external view returns (address);
    function getNativeGaugesLength() external view returns (uint256);
    function getAllAlgebraGauges() external view returns (address[] memory);
    function getAlgebraGauge(uint256 index) external view returns (address);
    function getAlgebraGaugesLength() external view returns (uint256);

}

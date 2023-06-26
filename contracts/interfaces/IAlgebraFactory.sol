// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;
interface IAlgebraFactory {
  event RenounceOwnershipStart(uint256 timestamp, uint256 finishTimestamp);
  event RenounceOwnershipStop(uint256 timestamp);
  event RenounceOwnershipFinish(uint256 timestamp);
  event Pool(address indexed token0, address indexed token1, address pool);
  event FarmingAddress(address indexed newFarmingAddress);
  //event DefaultFeeConfiguration(AlgebraFeeConfiguration newConfig);
  event DefaultCommunityFee(uint8 newDefaultCommunityFee);
  function POOLS_ADMINISTRATOR_ROLE() external view returns (bytes32);
  function hasRoleOrOwner(bytes32 role, address account) external view returns (bool);
  function owner() external view returns (address);
  function poolDeployer() external view returns (address);
  function farmingAddress() external view returns (address);
  function communityVault() external view returns (address);
  function defaultCommunityFee() external view returns (uint8);
  function poolByPair(address tokenA, address tokenB) external view returns (address pool);
  function renounceOwnershipStartTimestamp() external view returns (uint256 timestamp);
  function createPool(address tokenA, address tokenB) external returns (address pool);
  function setFarmingAddress(address newFarmingAddress) external;
  function setDefaultCommunityFee(uint8 newDefaultCommunityFee) external;
  //function setDefaultFeeConfiguration(AlgebraFeeConfiguration calldata newConfig) external;
  function startRenounceOwnership() external;
  function stopRenounceOwnership() external;
}

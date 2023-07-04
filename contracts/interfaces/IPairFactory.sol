// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;
import {IAlgebraFactory} from 'contracts/interfaces/IAlgebraFactory.sol';
interface IPairFactory {
    function getPairInfo(address pair) external view returns (address token0, address token1, bool stable, uint createdAt);
    function PRECISION() external view returns (uint);
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function isPairFor(address tokenA, address tokenB, bool stable) external view returns (bool);
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);

    function referralFee() external view returns(uint);
    function stakingNFTFee() external view returns(uint);
    function stakingNftFeeHandler() external view returns(address);
    function dibs() external view returns(address);
    function gammaFeeRecipient() external view returns(address);
    function activeReferral() external view returns(bool);
    function gammaShare() external view returns(uint);

    function isAlgebra() external view returns(bool);
    function algebraFactory() external view returns (IAlgebraFactory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import './interfaces/IPairInfo.sol';
import './interfaces/IBribe.sol';
import './interfaces/IVoter.sol';
import './interfaces/IPairFactory.sol';
import "./libraries/Math.sol";

contract CLFeesVault is Ownable {
    using SafeERC20 for IERC20;
    struct FeeData {
        uint256 amount0;
        uint256 amount1;
    }
    IVoter public voter;

    address public pool;
    IPairFactory public pairFactory;

    modifier onlyGauge() {
        require(voter.isGauge(msg.sender),'not gauge contract');
        _;
    }

    event Fees(uint256 totAmount0,uint256 totAmount1, address indexed token0, address indexed token1, address indexed pool, uint timestamp);
    event Fees0(uint gamma, uint referral, uint nft, uint gauge, address indexed token);
    event Fees1(uint gamma, uint referral, uint nft, uint gauge, address indexed token);

    constructor(address _pool, address _pairFactory, address _voter) {
        pairFactory = IPairFactory(_pairFactory);
        pool = _pool;
        voter = IVoter(_voter);

        // safe checks:
        voter.poolForGauge(_pool);
        pairFactory.allPairsLength();
        IPairInfo(_pool).token0();
    }

    /// @dev    Claim Fees from the gauge. Return the fees claimed by the gauge
    function claimFees() external onlyGauge returns(uint256 gauge0, uint256 gauge1) {
        // check gauge pool using voter
        address _pool = voter.poolForGauge(msg.sender);
        require(pool == _pool,"not pool");

        // fees
        uint gamma;
        uint referral;
        uint nft;

        // token0
        address t0 = IPairInfo(pool).token0();
        uint256 _amount0 = IERC20(t0).balanceOf(address(this));

        (gamma, referral, nft, gauge0) = getFees(_amount0);

        if(_amount0 > 0){

            if(gauge0 > 0) IERC20(t0).safeTransfer(msg.sender, gauge0);
            if(gamma > 0) IERC20(t0).safeTransfer(pairFactory.gammaRecipient(), gamma);
            if(nft > 0) IERC20(t0).safeTransfer(pairFactory.stakingNftFeeHandler(), nft);
            if(referral > 0) IERC20(t0).safeTransfer(pairFactory.dibs(), referral);
            emit Fees0(gamma, referral, nft, gauge0, t0);

        }
        // token1
        address t1 = IPairInfo(pool).token1();
        uint256 _amount1 = IERC20(t1).balanceOf(address(this));

        (gamma, referral, nft, gauge1) = getFees(_amount1);
        if(_amount1 > 0){
            if(gauge1 > 0) IERC20(t1).safeTransfer(msg.sender, gauge1);
            if(gamma > 0) IERC20(t1).safeTransfer(pairFactory.gammaRecipient(), gamma);
            if(nft > 0) IERC20(t1).safeTransfer(pairFactory.stakingNftFeeHandler(), nft);
            if(referral > 0) IERC20(t1).safeTransfer(pairFactory.dibs(), referral);
            emit Fees1(gamma, referral, nft, gauge1, t1);
        }

        emit Fees(_amount0, _amount1, t0, t1, pool, block.timestamp);

    }

    function getFees(uint amount) public view returns(uint gamma, uint referral, uint nft, uint gauge) {
        uint256 referralFee = pairFactory.activeReferral() ? pairFactory.referralFee() : 0;
        uint256 theNftFee = pairFactory.stakingNFTFee();
        uint precision = pairFactory.PRECISION();
        referral = amount * referralFee / precision;
        nft = (amount - referral) * theNftFee / precision;
        gamma = amount * pairFactory.gammaShare() / precision;
        gauge = amount - gamma - nft - referral;
    }

}

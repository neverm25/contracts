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
import './interfaces/IPermissionsRegistry.sol';
import "./libraries/Math.sol";

interface IPairFactory{
    function MAX_REFERRAL_FEE() external view returns(uint);
    function stakingNFTFee() external view returns(uint);
    function stakingFeeHandler() external view returns(address);
    function dibs() external view returns(address);
}


contract CLFeesVault is Ownable {

    using SafeERC20 for IERC20;

    /* -----------------------------------------------------------------------------
                                    DATA
    ----------------------------------------------------------------------------- */
    struct FeeData {
        uint256 amount0;
        uint256 amount1;
    }

    bool public activereferral = false;

    IVoter public voter;

    uint256 public PRECISION = 10000;
    uint256 public gammaShare = 0; // usually 7%
    uint256 public immutable gammaMAX = 2500; //25%

    address public pool;
    address public gammaRecipient;
    address public dibs;
    address public theNftStakingConverter;
    address public pairFactory = address(0xAFD89d21BdB66d00817d4153E055830B1c2B3970);

    mapping(address => bool) public isHypervisor;           //address   =>  boolean         check if caller is gamma strategy. Hypervisor calls updatedFees

    /* -----------------------------------------------------------------------------
                                    MODIFIERS
    ----------------------------------------------------------------------------- */
    modifier onlyGauge() {
        require(voter.isGauge(msg.sender),'!gauge contract');
        _;
    }

    /* -----------------------------------------------------------------------------
                                    EVENTS
    ----------------------------------------------------------------------------- */
    event Fees(uint256 totAmount0,uint256 totAmount1, address indexed token0, address indexed token1, address indexed pool, uint timestamp);
    event Fees0(uint gamma, uint referral, uint nft, uint gauge, address indexed token);
    event Fees1(uint gamma, uint referral, uint nft, uint gauge, address indexed token);

    constructor(address _pool, address _pairFactory, address _voter, address _gammaFeeRecipient) {
        pairFactory = _pairFactory;
        pool = _pool;
        voter = IVoter(_voter);
        theNftStakingConverter = IPairFactory(pairFactory).stakingFeeHandler();
        gammaRecipient = _gammaFeeRecipient;
        dibs = IPairFactory(pairFactory).dibs();
    }



    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    LP FEES CLAIM
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @dev    Claim Fees from the gauge. Return the fees claimed by the gauge
    function claimFees() external onlyGauge returns(uint256 gauge0, uint256 gauge1) {
        // check gauge pool using voter
        address _pool = voter.poolForGauge(msg.sender);
        require(pool == _pool);

        // fees
        uint gamma;
        uint referral;
        uint nft;

        // token0
        address t0 = IPairInfo(pool).token0();
        uint256 _amount0 = IERC20(t0).balanceOf(address(this));

        (gamma, referral, nft, gauge0) = _getFees(_amount0);

        if(_amount0 > 0){

            if(gauge0 > 0) IERC20(t0).safeTransfer(msg.sender, gauge0);
            if(gamma > 0) IERC20(t0).safeTransfer(gammaRecipient, gamma);
            if(nft > 0) IERC20(t0).safeTransfer(theNftStakingConverter, nft);
            if(referral > 0) IERC20(t0).safeTransfer(dibs, referral);
            emit Fees0(gamma, referral, nft, gauge0, t0);

        }
        // token1
        address t1 = IPairInfo(pool).token1();
        uint256 _amount1 = IERC20(t1).balanceOf(address(this));

        (gamma, referral, nft, gauge1) = _getFees(_amount1);
        if(_amount1 > 0){
            if(gauge1 > 0) IERC20(t1).safeTransfer(msg.sender, gauge1);
            if(gamma > 0) IERC20(t1).safeTransfer(gammaRecipient, gamma);
            if(nft > 0) IERC20(t1).safeTransfer(theNftStakingConverter, nft);
            if(referral > 0) IERC20(t1).safeTransfer(dibs, referral);
            emit Fees1(gamma, referral, nft, gauge1, t1);
        }

        emit Fees(_amount0, _amount1, t0, t1, pool, block.timestamp);

    }

    function _getFees(uint amount) internal view returns(uint gamma, uint referral, uint nft, uint gauge) {
        uint256 referralFee;
        if(activereferral) {
            referralFee = IPairFactory(pairFactory).MAX_REFERRAL_FEE();
        } else {
            referralFee = 0;
        }

        uint256 theNftFee = IPairFactory(pairFactory).stakingNFTFee();
        referral = amount * referralFee / PRECISION;
        nft = (amount - referral) * theNftFee / PRECISION;
        gamma = amount * gammaShare / PRECISION;
        gauge = amount - gamma - nft - referral;
    }



    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    ADMIN FUNCTIONS
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */
    function setActiveReferral(bool _what) external onlyOwner {
        require(activereferral != _what);
        activereferral = _what;
    }

    function setGammaShare(uint256 share) external onlyOwner {
        require(share <= gammaMAX);
        gammaShare = share;
    }

    function setGammaRecipient(address _gR) external onlyOwner {
        require(_gR != address(0));
        gammaRecipient = _gR;
    }


    function setDibs(address _dibs) external onlyOwner {
        require(_dibs != address(0));
        dibs = _dibs;
    }

    function setNftStaking(address _theNftStaking) external onlyOwner {
        require(_theNftStaking != address(0));
        theNftStakingConverter = _theNftStaking;
    }

    function setPairFactory(address _pf) external onlyOwner {
        require(_pf != address(0));
        pairFactory = _pf;
    }

    function setVoter(address vt) external onlyOwner {
        require(vt != address(0));
        voter = IVoter(vt);
    }


    function setPermissionRegistry(address _pr) external onlyOwner {
        require(_pr != address(0));
        permissionsRegsitry = IPermissionsRegistry(_pr);
    }

    function setPool(address _pool) external onlyOwner {
        require(_pool != address(0));
        pool = _pool;
    }

    /// @notice Recover ERC20 from the contract.
    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)));
        IERC20(tokenAddress).safeTransfer(permissionsRegsitry.varaTeamMultisig(), tokenAmount);
    }

}

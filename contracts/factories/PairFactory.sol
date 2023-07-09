// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import 'contracts/interfaces/IPairFactory.sol';
import 'contracts/interfaces/IAlgebraFactory.sol';
import 'contracts/Pair.sol';

contract PairFactory is IPairFactory {

    bool public isPaused;
    address public pauser;
    address public pendingPauser;
    uint public PRECISION = 10000;
    uint256 public stableFee;
    uint256 public volatileFee;
    uint256 public constant MAX_FEE = 50; // 0.5%
    address public feeManager;
    address public pendingFeeManager;
    address public gammaFeeRecipient;
    uint256 public gammaShare = 0; // usually 7%
    uint256 public immutable gammaMAX = 2500; //25%

    uint256 public referralFee; // 12%
    uint256 public stakingNFTFee;
    address public dibs;                // referral fee handler
    address public stakingNftFeeHandler;   // staking fee handler
    bool public activeReferral;

    mapping(address => mapping(address => mapping(bool => address))) internal _getPair;
    mapping(address => mapping(address => address)) internal _getPairOnAlgebra;


    // get pair info by pool address, can be used to get pool info when we
    // have only the pool address:
    struct PairInfo {
        address token0;
        address token1;
        bool stable;
        uint createdAtTimestamp;
        uint createdAtBlock;
        bool isAlgebra;
    }
    mapping(address => PairInfo) private pairInfo;

    address[] public allPairs;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals

    address internal _temp0;
    address internal _temp1;
    bool internal _temp;

    event PairCreated(address indexed token0, address indexed token1, bool stable, address pair, uint);
    event AlgebraPairCreated(address indexed token0, address indexed token1, address pair, uint);

    event ActiveReferralSet(bool _activeReferral);
    event StakingNFTFeeSet(uint256 _stakingNFTFee);
    event GammaFeeRecipientSet(address _gammaFeeRecipient);
    event ReferralFeeSet(uint256 _referralFee);
    event DibsSet(address _dibs);
    event StakingFeeHandlerSet(address _stakingNftFeeHandler);
    event StableFeeSet(uint256 _stableFee);
    event VolatileFeeSet(uint256 _volatileFee);
    event PauserSet(address _pauser);
    event Paused(bool _state);
    event FeeManagerSet(address _feeManager);
    event GammaShareSet(uint256 _gammaShare);

    /// @dev AlgebraFactory is set in constructor, and cannot be changed.
    IAlgebraFactory public immutable algebraFactory;

    /// @dev if set all pools created will be on AlgebraFactory.
    bool public immutable isAlgebra;

    constructor( address _algebraFactory ) {

        /// @dev if set all pools created will be on AlgebraFactory.
        isAlgebra = _algebraFactory != address(0);
        algebraFactory = IAlgebraFactory(_algebraFactory);

        pauser = msg.sender;
        isPaused = false;
        feeManager = msg.sender;
        stableFee = 4; // 0.04%
        volatileFee = 30;
        gammaFeeRecipient = msg.sender;
        stakingNFTFee = 3000; // 30% of stable/volatileFee
        referralFee = 1200; // 12%

    }

    function setPauser(address _pauser) external {
        require(msg.sender == pauser, "not pauser");
        pendingPauser = _pauser;
    }

    function acceptPauser() external {
        require(msg.sender == pendingPauser, "not pending pauser");
        pauser = pendingPauser;
        emit PauserSet(pauser);
    }

    function setPause(bool _state) external {
        require(msg.sender == pauser, "not pauser");
        isPaused = _state;
        emit Paused(_state);
    }

    function setFeeManager(address _feeManager) external {
        require(msg.sender == feeManager, 'not fee manager');
        pendingFeeManager = _feeManager;
        emit FeeManagerSet(_feeManager);
    }

    function acceptFeeManager() external {
        require(msg.sender == pendingFeeManager, 'not pending fee manager');
        feeManager = pendingFeeManager;
        emit FeeManagerSet(feeManager);
    }

    function setFee(bool _stable, uint256 _fee) external {
        // TODO: add support to set fee on Algebra backend.
        require(msg.sender == feeManager, 'not fee manager');
        require(_fee <= MAX_FEE, 'fee too high');
        require(_fee != 0, 'fee must be nonzero');
        if (_stable) {
            stableFee = _fee;
            emit StableFeeSet(_fee);
        } else {
            volatileFee = _fee;
            emit VolatileFeeSet(_fee);
        }
    }

    function getFee(bool _stable) public view returns(uint256) {
        // TODO: if Algebra mode is on, get fee from Algebra backend?
        return _stable ? stableFee : volatileFee;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(Pair).creationCode);
    }

    function getInitializable() external view returns (address, address, bool) {
        return (_temp0, _temp1, _temp);
    }

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair) {
        require(!isPaused, 'paused');
        require(tokenA != tokenB, 'IA'); // Pair: IDENTICAL_ADDRESSES

        // we just return pair addresses instead of a revert to make sure some tests that use
        // same pair and different stable flags work for Algebra mode.
        pair = pairFor(tokenA, tokenB, stable);
        string memory symbolA = Pair(tokenA).symbol();
        string memory symbolB = Pair(tokenB).symbol();
        if ( pair != address(0) ){
            return pair;
        }

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZA'); // Pair: ZERO_ADDRESS
        (_temp0, _temp1, _temp) = (token0, token1, stable);

        if( isAlgebra ){
            pair = algebraFactory.createPool(token0, token1);
            _getPairOnAlgebra[token0][token1] = pair;
        }else{
            bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable)); // notice salt includes stable as well, 3 parameters
            pair = address(new Pair{salt:salt}());
        }

        /// @dev full _getPair, with stable flag, to compatibility with other contracts
        _getPair[token0][token1][stable] = pair;
        _getPair[token1][token0][stable] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;

        pairInfo[pair] = PairInfo({
            token0: token0,
            token1: token1,
            stable: stable,
            createdAtTimestamp: block.timestamp,
            createdAtBlock: block.number,
            isAlgebra: isAlgebra
        });

        emit PairCreated(token0, token1, stable, pair, allPairs.length);
    }
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }
    function setStakingFeeHandler(address _stakingNftFeeHandler) external {
        require( _stakingNftFeeHandler != address(0), 'zero address');
        require(msg.sender == feeManager, 'not fee manager');
        stakingNftFeeHandler = _stakingNftFeeHandler;
        emit StakingFeeHandlerSet(_stakingNftFeeHandler);
    }

    function setDibs(address _dibs) external  {
        require(msg.sender == feeManager, 'not fee manager');
        require(_dibs != address(0));
        emit DibsSet(_dibs);
        dibs = _dibs;
    }

    function setReferralFee(uint256 _refFee) external  {
        require(msg.sender == feeManager, 'not fee manager');
        emit ReferralFeeSet(_refFee);
        referralFee = _refFee;
    }
    function setGammaFeeRecipient(address _gammaFeeRecipient) external  {
        require(msg.sender == feeManager, 'not fee manager');
        require(_gammaFeeRecipient != address(0), "zero address");
        emit GammaFeeRecipientSet(_gammaFeeRecipient);
        gammaFeeRecipient = _gammaFeeRecipient;
    }
    function setActiveReferral(bool _activeReferral) external  {
        require(msg.sender == feeManager, 'not fee manager');
        emit ActiveReferralSet(_activeReferral);
        activeReferral = _activeReferral;
    }
    function setStakingNFTFee(uint256 _stakingNFTFee) external  {
        require(msg.sender == feeManager, 'not fee manager');
        emit StakingNFTFeeSet(_stakingNFTFee);
        stakingNFTFee = _stakingNFTFee;
    }
    function setGammaShare(uint256 _gammaShare) external  {
        require(msg.sender == feeManager, 'not fee manager');
        if(_gammaShare > gammaMAX) _gammaShare = gammaMAX;
        emit GammaShareSet(_gammaShare);
        gammaShare = _gammaShare;
    }

    function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
        // sort:
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if( isAlgebra )
            pair = _getPairOnAlgebra[token0][token1];
        else
            pair = _getPair[token0][token1][stable];
    }
    function getPair(address tokenA, address tokenB, bool stable) external view returns (address pair) {
        pair = pairFor(tokenA, tokenB, stable);
    }
    function isPairFor(address tokenA, address tokenB, bool stable) public view returns (bool) {
        return address(0) == pairFor(tokenA, tokenB, stable);
    }
    function getPairInfo(address pair) external view returns
    (address token0, address token1, bool stable, uint createdAt)
    {
        require(pair != address(0), "getPairInfo: zero address");
        PairInfo memory info = pairInfo[pair];
        token0 = info.token0;
        token1 = info.token1;
        stable = info.stable;
        createdAt = info.createdAtTimestamp;
    }
}

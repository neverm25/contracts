pragma solidity =0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "contracts/factories/BribeFactory.sol";
import "contracts/factories/GaugeFactory.sol";
import "contracts/factories/PairFactory.sol";
import "contracts/redeem/MerkleClaim.sol";
import "contracts/InternalBribe.sol";
import "contracts/ExternalBribe.sol";
import "contracts/Gauge.sol";
import "contracts/Minter.sol";
import "contracts/Pair.sol";
import "contracts/PairFees.sol";
import "contracts/RewardsDistributor.sol";
import "contracts/Router.sol";
import "contracts/Router2.sol";
import "contracts/UniversalRouter.sol";
import "contracts/interfaces/ISwapRouter.sol";
import "contracts/interfaces/IUniswapV2Router.sol";
import "contracts/Vara.sol";
import "contracts/VaraLibrary.sol";
import "contracts/Voter.sol";
import "contracts/VeArtProxy.sol";
import "contracts/VotingEscrow.sol";
import "utils/TestOwner.sol";
import "utils/TestStakingRewards.sol";
import "utils/TestToken.sol";
import "utils/TestVoter.sol";
import "utils/TestVotingEscrow.sol";
import "utils/TestWETH.sol";

import {IAlgebraFactory} from 'contracts/interfaces/IAlgebraFactory.sol';
import {IAlgebraPool} from 'contracts/interfaces/IAlgebraPool.sol';
import {INonfungiblePositionManager} from 'contracts/interfaces/INonfungiblePositionManager.sol';
import {ISwapRouter} from 'contracts/interfaces/ISwapRouter.sol';
import {IWETH} from 'contracts/interfaces/IWETH.sol';
import { SqrtPrice } from "contracts/libraries/SqrtPrice.sol";
import { FloorCeil } from "contracts/libraries/FloorCeil.sol";
import { TickMath } from '@cryptoalgebra/core/contracts/libraries/TickMath.sol';

import { IERC721Receiver } from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

abstract contract BaseTest is Test, TestOwner, IERC721Receiver {
    uint256 constant USDC_1 = 1e6;
    uint256 constant USDC_100K = 1e11; // 1e5 = 100K tokens with 6 decimals
    uint256 constant USDC_1M = 1e12;
    uint256 constant TOKEN_1 = 1e18;
    uint256 constant TOKEN_100K = 1e23; // 1e5 = 100K tokens with 18 decimals
    uint256 constant TOKEN_1M = 1e24; // 1e6 = 1M tokens with 18 decimals
    uint256 constant TOKEN_100M = 1e26; // 1e8 = 100M tokens with 18 decimals
    uint256 constant TOKEN_10B = 1e28; // 1e10 = 10B tokens with 18 decimals
    uint256 constant PAIR_1 = 1e9;

    TestOwner owner;
    TestOwner owner2;
    TestOwner owner3;
    address[] owners;
    MockERC20 USDC;
    MockERC20 FRAX;
    MockERC20 DAI;
    TestWETH WETH; // Mock WETH token
    Vara VARA;
    MockERC20 WEVE;
    MockERC20 LR; // late reward
    TestToken stake; // MockERC20 with claimFees() function that returns (0,0)
    PairFactory factory;

    UniversalRouter router;
    Router2 routerUniswap;

    VaraLibrary lib;
    Pair pair;
    Pair pair2;
    Pair pair3;

    // KAVA testnet
    // pool init code hash: 0xc65e01e65f37c1ec2735556a24a9c10e4c33b2613ad486dd8209d465524bc3f4
    // commit: cec544dbea25a9c884f236f1518e66ac6df2e0c1;
    address Mainnet_wEthAddress = address(0xc86c7C0eFbd6A49B35E8714C5f59D99De09A225b);
    address Mainnet_AlgebraPoolDeployerAddress = address(0x2dfC313b6cAeFe8bDFfef816BeD4C976287F6083);
    address Mainnet_AlgebraFactoryAddress = address(0x3E5Fa17641d7441CA8DD8D2F2d79513c99ADCDE6);
    address Mainnet_QuoterAddress = address(0xAD776e0A7596430D3107eB1eA986622c455C4a0A);
    address Mainnet_SwapRouterAddress = address(0x572DecDf78D90B91C2d674A5Ce2bA14853f67544);
    address Mainnet_NonfungibleTokenPositionDescriptorAddress = address(0x1BC3820C8e520049408A034227D4BEe34C7cABc7);
    address Mainnet_NonfungiblePositionManagerAddress = address(0xEeb41A68FcE47237bAe0A91aDa3f4F272bB01563);
    address Mainnet_AlgebraInterfaceMulticallAddress = address(0x3e61E3F9A75E859A7B1B59C41e1d5FBa6F3a7Bc7);
    address Mainnet_AlgebraLimitFarmingAddress = address(0x43c5c0756fA7F466915370D81abE32eB1aF48494);
    address Mainnet_AlgebraEternalFarmingAddress = address(0x8e7fc8d436FEA71cB7bA873Ab093cEBc43d64c54);
    address Mainnet_FarmingCenterAddress = address(0x3D00ba241e3885b937405Faa064f9583BAbC6dF9);

    // KAVA testnet
    // pool init code hash: 0xc65e01e65f37c1ec2735556a24a9c10e4c33b2613ad486dd8209d465524bc3f4
    // commit: cec544dbea25a9c884f236f1518e66ac6df2e0c1;
    address Testnet_wEthAddress = address(0x9D8D5A31E3e46D39D379Da2762fb143c7869a769);
    address Testnet_AlgebraPoolDeployerAddress = address(0x03592F961d3e8eA6E284347ec5d84dC6A0Ed41e1);
    address Testnet_AlgebraFactoryAddress = address(0x2dfC313b6cAeFe8bDFfef816BeD4C976287F6083);
    address Testnet_QuoterAddress = address(0x6D1D9932BC8A6190BD6559f2786cfeBe63c44DE5);
    address Testnet_SwapRouterAddress = address(0xAD776e0A7596430D3107eB1eA986622c455C4a0A);
    address Testnet_NonfungibleTokenPositionDescriptorAddress = address(0x678161abA75673c7B0368dc2907F13379Bc5069f);
    address Testnet_NonfungiblePositionManagerAddress = address(0x80bBD8C91612eEc110a24091cf5C4DaA5D0Fe7A7);
    address Testnet_AlgebraInterfaceMulticallAddress = address(0xcfC30f0074f54015D7481b36b3490e710e7602Dc);
    address Testnet_AlgebraLimitFarmingAddress = address(0x3e61E3F9A75E859A7B1B59C41e1d5FBa6F3a7Bc7);
    address Testnet_AlgebraEternalFarmingAddress = address(0x43c5c0756fA7F466915370D81abE32eB1aF48494);
    address Testnet_FarmingCenterAddress = address(0x09c82656190654b02eE3D4BdB7598084Bc93Cf2D);

    IAlgebraFactory algebraFactory;
    address algebraFactoryAddress;

    ISwapRouter algebraRouter;
    address algebraRouterAddress;

    IWETH algebraWeth;
    address algebraWethAddress;

    INonfungiblePositionManager algebraPositionManager;
    address algebraPositionManagerAddress;

    MockERC20 usdc;
    MockERC20 usdt;
    IAlgebraPool pool;
    address poolAddress;

    uint256 positionTokenId;
    uint128 positionLiquidity;
    uint256 positionAmount0;
    uint256 positionAmount1;

    int24 constant public tickLower = -60;
    int24 constant public tickUpper = 60;

    constructor(){
        uint VALID_TESTNET_ID = vm.envUint("VALID_TESTNET_ID");
        uint VALID_MAINNET_ID = vm.envUint("VALID_MAINNET_ID");
        uint CHAIN_ID = block.chainid;
        bool useMainnetAddresses = CHAIN_ID == VALID_MAINNET_ID;
        require(VALID_TESTNET_ID > 0, "VALID_TESTNET_ID not set in ../.env");
        require(VALID_MAINNET_ID > 0, "VALID_MAINNET_ID not set in ../.env");
        require(CHAIN_ID == VALID_TESTNET_ID || CHAIN_ID == VALID_MAINNET_ID, "block.chainid not VALID_TESTNET_ID or VALID_MAINNET_ID");
        if( useMainnetAddresses){
            algebraFactoryAddress = Mainnet_AlgebraFactoryAddress;
            algebraRouterAddress = Mainnet_SwapRouterAddress;
            algebraWethAddress = Mainnet_wEthAddress;
            algebraPositionManagerAddress = Mainnet_NonfungiblePositionManagerAddress;
        } else {
            algebraFactoryAddress = Testnet_AlgebraFactoryAddress;
            algebraRouterAddress = Testnet_SwapRouterAddress;
            algebraWethAddress = Testnet_wEthAddress;
            algebraPositionManagerAddress = Testnet_NonfungiblePositionManagerAddress;
        }
    }

    bool public isAlgebra = false;
    function useAlgebra() public {
        isAlgebra = true;

        // check if contracts code size:
        if(algebraFactoryAddress.code.length == 0)
            revert("algebraFactoryAddress code size is zero");
        if(algebraRouterAddress.code.length == 0)
            revert("algebraRouterAddress code size is zero");
        if(algebraWethAddress.code.length == 0)
            revert("algebraWethAddress code size is zero");
        if(algebraPositionManagerAddress.code.length == 0)
            revert("algebraPositionManagerAddress code size is zero");

        algebraRouter = ISwapRouter(algebraRouterAddress);
        algebraWeth = IWETH(algebraWethAddress);
        algebraFactory = IAlgebraFactory(algebraFactoryAddress);
        algebraPositionManager = INonfungiblePositionManager(algebraPositionManagerAddress);

        usdc = new MockERC20("USDC", "USDC", 6);
        usdt = new MockERC20("USDT", "USDT", 6);

        uint amount0ToMint = 10_000_000e6;
        uint amount1ToMint = 10_000_000e6;
        usdc.mint(address(this), amount0ToMint);
        usdt.mint(address(this), amount1ToMint);

        usdc.approve(address(algebraPositionManager), amount0ToMint);
        usdt.approve(address(algebraPositionManager), amount1ToMint);

        uint256 amount = 1e6;
        uint160 sqrtPriceX96 = SqrtPrice.getSqrtPrice(amount, amount);
        poolAddress = algebraFactory.poolByPair(address(usdc), address(usdt));

        if (poolAddress == address(0)) {
            poolAddress = algebraFactory.createPool(address(usdc), address(usdt));
            IAlgebraPool(poolAddress).initialize(sqrtPriceX96);
        }
        pool = IAlgebraPool(pool);

        INonfungiblePositionManager.MintParams memory params =
                            INonfungiblePositionManager.MintParams({
                token0: address(usdt),
                token1: address(usdc),
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amount0ToMint,
                amount1Desired: amount1ToMint,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });
        (positionTokenId, positionLiquidity, positionAmount0, positionAmount1) = algebraPositionManager.mint(params);
    }

    function onERC721Received(address, address, uint256, bytes calldata)
    external pure override returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    function deployOwners() public {
        owner = TestOwner(address(this));
        owner2 = new TestOwner();
        owner3 = new TestOwner();
        owners = new address[](3);
        owners[0] = address(owner);
        owners[1] = address(owner2);
        owners[2] = address(owner3);
    }

    function deployCoins() public {
        USDC = new MockERC20("USDC", "USDC", 6);
        FRAX = new MockERC20("FRAX", "FRAX", 18);
        DAI = new MockERC20("DAI", "DAI", 18);
        VARA = new Vara();
        WEVE = new MockERC20("WEVE", "WEVE", 18);
        LR = new MockERC20("LR", "LR", 18);
        WETH = new TestWETH();
        stake = new TestToken("stake", "stake", 18, address(owner));
    }

    function mintStables() public {
        for (uint256 i = 0; i < owners.length; i++) {
            USDC.mint(owners[i], 1e12 * USDC_1);
            FRAX.mint(owners[i], 1e12 * TOKEN_1);
            DAI.mint(owners[i], 1e12 * TOKEN_1);
        }
    }

    function mintVara(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _amounts.length; i++) {
            VARA.mint(_accounts[i], _amounts[i]);
        }
    }

    function mintLR(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            LR.mint(_accounts[i], _amounts[i]);
        }
    }

    function mintStake(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            stake.mint(_accounts[i], _amounts[i]);
        }
    }

    function mintWETH(address[] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            WETH.mint(_accounts[i], _amounts[i]);
        }
    }

    function dealETH(address [] memory _accounts, uint256[] memory _amounts) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            vm.deal(_accounts[i], _amounts[i]);
        }
    }

    function deployPairFactoryAndRouter() public {
        if( isAlgebra ){
            console2.log("Attention: Algebra is activated!");
            require(algebraFactoryAddress != address(0), "useAlgebra(useMainnetAddresses) not set");
        }
        require( address(router) == address(0), "router already set" );
        factory = new PairFactory(algebraFactoryAddress);
        assertEq(factory.allPairsLength(), 0);
        factory.setFee(true, 1); // set fee back to 0.01% for old tests
        factory.setFee(false, 1);

        routerUniswap = new Router2(address(factory), address(WETH));
        router = new UniversalRouter(isAlgebra, address(routerUniswap), algebraRouterAddress);

        assertEq(router.factory(), address(factory));
        lib = new VaraLibrary(address(router));

    }

    function deployPairWithOwner(address _owner) public {
        console2.log("deployPairWithOwner");
        TestOwner(_owner).approve(address(FRAX), address(router), TOKEN_1);
        TestOwner(_owner).approve(address(USDC), address(router), USDC_1);
        TestOwner(_owner).addLiquidity(payable(address(router)), address(FRAX), address(USDC), true, TOKEN_1, USDC_1, 0, 0, address(owner), block.timestamp);
        TestOwner(_owner).approve(address(FRAX), address(router), TOKEN_1);
        TestOwner(_owner).approve(address(USDC), address(router), USDC_1);
        TestOwner(_owner).addLiquidity(payable(address(router)), address(FRAX), address(USDC), false, TOKEN_1, USDC_1, 0, 0, address(owner), block.timestamp);
        TestOwner(_owner).approve(address(FRAX), address(router), TOKEN_1);
        TestOwner(_owner).approve(address(DAI), address(router), TOKEN_1);
        TestOwner(_owner).addLiquidity(payable(address(router)), address(FRAX), address(DAI), true, TOKEN_1, TOKEN_1, 0, 0, address(owner), block.timestamp);

        assertEq(factory.allPairsLength(), 3);

        address create2address = router.pairFor(address(FRAX), address(USDC), true);
        address address1 = factory.getPair(address(FRAX), address(USDC), true);
        pair = Pair(address1);
        address address2 = factory.getPair(address(FRAX), address(USDC), false);
        pair2 = Pair(address2);
        address address3 = factory.getPair(address(FRAX), address(DAI), true);
        pair3 = Pair(address3);
        assertEq(address(pair), create2address);
        assertGt(lib.getAmountOut(USDC_1, address(USDC), address(FRAX), true), 0);
    }

    function mintPairFraxUsdcWithOwner(address _owner) public {
        TestOwner(_owner).transfer(address(USDC), address(pair), USDC_1);
        TestOwner(_owner).transfer(address(FRAX), address(pair), TOKEN_1);
        TestOwner(_owner).mint(address(pair), _owner);
    }

    receive() external payable {}
}

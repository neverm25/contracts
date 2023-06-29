pragma solidity =0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "contracts/interfaces/ISwapRouter.sol";
import "contracts/interfaces/IWETH.sol";
import 'contracts/interfaces/IAlgebraFactory.sol';
import 'contracts/interfaces/IAlgebraPool.sol';
import 'contracts/interfaces/INonfungiblePositionManager.sol';

import { SqrtPrice } from "contracts/libraries/SqrtPrice.sol";
import { FloorCeil } from "contracts/libraries/FloorCeil.sol";
import { TickMath } from '@cryptoalgebra/core/contracts/libraries/TickMath.sol';

import { IERC721Receiver } from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract AlgebraTest is Test, IERC721Receiver {
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


    IAlgebraFactory factory;
    address factoryAddress;

    ISwapRouter router;
    address routerAddress;

    IWETH weth;
    address wethAddress;

    INonfungiblePositionManager positionManager;
    address positionManagerAddress;

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

    constructor(bool useMainnetAddresses ) {
        if( useMainnetAddresses){
            factoryAddress = Mainnet_AlgebraFactoryAddress;
            routerAddress = Mainnet_SwapRouterAddress;
            wethAddress = Mainnet_wEthAddress;
            positionManagerAddress = Mainnet_NonfungiblePositionManagerAddress;
        } else {
            factoryAddress = Testnet_AlgebraFactoryAddress;
            routerAddress = Testnet_SwapRouterAddress;
            wethAddress = Testnet_wEthAddress;
            positionManagerAddress = Testnet_NonfungiblePositionManagerAddress;
        }
        // check if contracts code size:
        if(factoryAddress.code.length == 0)
            revert("factoryAddress code size is zero");
        if(routerAddress.code.length == 0)
            revert("routerAddress code size is zero");
        if(wethAddress.code.length == 0)
            revert("wethAddress code size is zero");
        if(positionManagerAddress.code.length == 0)
            revert("positionManagerAddress code size is zero");

        router = ISwapRouter(routerAddress);
        weth = IWETH(wethAddress);
        factory = IAlgebraFactory(factoryAddress);
        positionManager = INonfungiblePositionManager(positionManagerAddress);

        usdc = new MockERC20("USDC", "USDC", 6);
        usdt = new MockERC20("USDT", "USDT", 6);

        uint amount0ToMint = 10_000_000e6;
        uint amount1ToMint = 10_000_000e6;
        usdc.mint(address(this), amount0ToMint);
        usdt.mint(address(this), amount1ToMint);

        usdc.approve(address(positionManager), amount0ToMint);
        usdt.approve(address(positionManager), amount1ToMint);

        uint256 amount = 1e6;
        uint160 sqrtPriceX96 = SqrtPrice.getSqrtPrice(amount, amount);
        poolAddress = factory.poolByPair(address(usdc), address(usdt));

        if (poolAddress == address(0)) {
            poolAddress = factory.createPool(address(usdc), address(usdt));
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
        (positionTokenId, positionLiquidity, positionAmount0, positionAmount1) = positionManager.mint(params);
    }

    function onERC721Received(address, address, uint256, bytes calldata)
    external pure override returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

}

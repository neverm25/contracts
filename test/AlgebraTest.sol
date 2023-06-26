pragma solidity =0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "contracts/interfaces/ISwapRouter.sol";
import "contracts/interfaces/IWETH.sol";
import 'contracts/interfaces/IAlgebraFactory.sol';
import 'contracts/mock/FaucetERC20d6.sol';
import 'contracts/Vara.sol';

contract AlgebraTest is Test {

    // KAVA testnet
    // pool init code hash: 0xc65e01e65f37c1ec2735556a24a9c10e4c33b2613ad486dd8209d465524bc3f4
    // commit: cec544dbea25a9c884f236f1518e66ac6df2e0c1;
    address wEthAddress = address(0x9D8D5A31E3e46D39D379Da2762fb143c7869a769);
    address AlgebraPoolDeployerAddress = address(0x03592F961d3e8eA6E284347ec5d84dC6A0Ed41e1);
    address AlgebraFactoryAddress = address(0x2dfC313b6cAeFe8bDFfef816BeD4C976287F6083);
    address QuoterAddress = address(0x6D1D9932BC8A6190BD6559f2786cfeBe63c44DE5);
    address SwapRouterAddress = address(0xAD776e0A7596430D3107eB1eA986622c455C4a0A);
    address NonfungibleTokenPositionDescriptorAddress = address(0x678161abA75673c7B0368dc2907F13379Bc5069f);
    address NonfungiblePositionManagerAddress = address(0x80bBD8C91612eEc110a24091cf5C4DaA5D0Fe7A7);
    address AlgebraInterfaceMulticallAddress = address(0xcfC30f0074f54015D7481b36b3490e710e7602Dc);
    address AlgebraLimitFarmingAddress = address(0x3e61E3F9A75E859A7B1B59C41e1d5FBa6F3a7Bc7);
    address AlgebraEternalFarmingAddress = address(0x43c5c0756fA7F466915370D81abE32eB1aF48494);
    address FarmingCenterAddress = address(0x09c82656190654b02eE3D4BdB7598084Bc93Cf2D);

    IAlgebraFactory factory;
    ISwapRouter router;
    IWETH weth;

    FaucetERC20d6 usdc;
    Vara vara;

    constructor() {
        router = ISwapRouter(SwapRouterAddress);
        weth = IWETH(wEthAddress);
        factory = IAlgebraFactory(AlgebraFactoryAddress);

        usdc = new FaucetERC20d6("USDC", "USDC", 0);
        vara = new Vara();

        usdc.mint(address(this), 10_000_000e6);
        vara.mint(address(this), 10_000_000e18);
    }
}

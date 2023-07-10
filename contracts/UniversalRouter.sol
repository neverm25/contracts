// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {IERC20} from "contracts/interfaces/IERC20.sol";
import {ISwapRouter} from "contracts/interfaces/ISwapRouter.sol";
import {IUniswapV2Router} from "contracts/interfaces/IUniswapV2Router.sol";
import {INonfungiblePositionManager} from "contracts/interfaces/INonfungiblePositionManager.sol";
import {IAlgebraPool} from "contracts/interfaces/IAlgebraPool.sol";
import {IPair} from "contracts/interfaces/IPair.sol";
import {IPairFactory} from "contracts/interfaces/IPairFactory.sol";
import {IAlgebraFactory} from "contracts/interfaces/IAlgebraFactory.sol";

import {SqrtPrice} from "contracts/libraries/SqrtPrice.sol";
import {IQuoter} from 'contracts/interfaces/IQuoter.sol';
import {IRouter} from 'contracts/interfaces/IRouter.sol';
import {LiquidityAmounts} from 'contracts/libraries/LiquidityAmounts.sol';
//import "forge-std/console2.sol";

contract UniversalRouter is IUniswapV2Router, IRouter {
    bool public isAlgebraMode;
    IUniswapV2Router uniswapRouter;
    ISwapRouter algebraRouter;
    INonfungiblePositionManager algebraPositionManager;
    IPairFactory pairFactory;
    IAlgebraFactory algebraFactory;
    IQuoter quoter;
    address public routerAddress;
    int24 public DefaultTickLower = - 60;
    int24 public DefaultTickUpper = 60;

    constructor(
        bool _isAlgebraMode,
        address _uniswapRouter,
        address _algebraRouter,
        address _algebraPositionManager,
        address _quoter
    ){
        algebraPositionManager = INonfungiblePositionManager(_algebraPositionManager);
        isAlgebraMode = _isAlgebraMode;
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
        pairFactory = IPairFactory(uniswapRouter.factory());
        algebraFactory = pairFactory.algebraFactory();
        algebraRouter = ISwapRouter(_algebraRouter);
        routerAddress = _isAlgebraMode ? _algebraRouter : _uniswapRouter;
        quoter = IQuoter(_quoter);
    }
    function factory() external view returns (address){
        return uniswapRouter.factory();
    }

    function weth() external view returns (address){
        return uniswapRouter.weth();
    }

    function WETH() external view returns (address){
        return uniswapRouter.weth();
    }

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline) external returns (uint[] memory amounts) {
        address tokenIn = routes[0].from;
        address tokenOut = routes[0].to;
        return swapExactTokensForTokens(tokenIn, tokenOut, amountIn, amountOutMin, deadline);
    }

    function swapExactTokensForTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMinimum, uint256 deadline) public returns (uint256[] memory amounts){
        IERC20 token = IERC20(tokenIn);
        require(token.balanceOf(msg.sender) >= amountIn,
            string(abi.encodePacked("swapExactTokensForTokens: insufficient balance for: ", token.symbol())));

        require(token.allowance(msg.sender, address(this)) >= amountIn,
            string(abi.encodePacked("swapExactTokensForTokens: insufficient allowance for: ", token.symbol())));

        if (isAlgebraMode) {
            return swapExactTokensForTokensAlgebra(tokenIn, tokenOut, amountIn, amountOutMinimum, deadline);
        } else {
            return swapExactTokensForTokensUniswap(tokenIn, tokenOut, amountIn, amountOutMinimum, deadline);
        }
    }

    function swapExactTokensForTokensAlgebra(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline
    ) internal returns (uint256[] memory amounts){
        uint256[] memory _amounts = new uint256[](2);
        require(false, "//TODO: swapExactTokensForTokensAlgebra");
        //return algebraRouter.exactInputSingle(ISwapRouter.ExactInputSingleParams(tokenIn, tokenOut, address(this), deadline, amountIn, amountOutMinimum, 0));
        return _amounts;
    }

    function swapExactTokensForTokensUniswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline
    ) internal returns (uint256[] memory amounts){
        uint256[] memory _amounts = new uint256[](2);
        IUniswapV2Router.route[] memory routes = new IUniswapV2Router.route[](1);
        routes[0] = IUniswapV2Router.route(tokenIn, tokenOut, false);
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMinimum, routes, address(this), deadline);
        return _amounts;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMinimum,
        uint256 amountBMinimum,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity){

        require(IERC20(tokenA).balanceOf(msg.sender) >= amountADesired, "addLiquidity: insufficient balance for tokenA.");
        require(IERC20(tokenB).balanceOf(msg.sender) >= amountBDesired, "addLiquidity: insufficient balance for tokenB.");

        require(IERC20(tokenA).allowance(msg.sender, address(this)) >= amountADesired, "addLiquidity: insufficient allowance for tokenA.");
        require(IERC20(tokenB).allowance(msg.sender, address(this)) >= amountBDesired, "addLiquidity: insufficient allowance for tokenB.");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        if (isAlgebraMode) {
            IERC20(tokenA).approve(address(algebraPositionManager), amountADesired);
            IERC20(tokenB).approve(address(algebraPositionManager), amountBDesired);
            (uint tokenId, uint128 liquidityU128) = addLiquidityAlgebra(tokenA, tokenB, stable, amountADesired, amountBDesired, amountAMinimum, amountBMinimum, to, deadline);
            liquidity = uint(liquidityU128);
        } else {
            IERC20(tokenA).approve(address(uniswapRouter), amountADesired);
            IERC20(tokenB).approve(address(uniswapRouter), amountBDesired);
            liquidity = addLiquidityUniswap(tokenA, tokenB, amountADesired, amountBDesired, amountAMinimum, amountBMinimum, to, deadline);
        }
        return (0, 0, liquidity);
    }

    function addLiquidityAlgebra(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMinimum,
        uint256 amountBMinimum,
        address to,
        uint256 deadline
    ) internal returns (uint256 tokenId, uint128 liquidity){
        // sort tokens:

        (address token0, address token1) = sortTokens(tokenA, tokenB);

        address pool = algebraCratePool(tokenA, tokenB, stable, amountADesired, amountBDesired);

        INonfungiblePositionManager.MintParams memory params =
                            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                tickLower: DefaultTickLower,
                tickUpper: DefaultTickUpper,
                amount0Desired: amountADesired,
                amount1Desired: amountBDesired,
                amount0Min: amountAMinimum,
                amount1Min: amountBMinimum,
                recipient: to,
                deadline: deadline
            });

        (uint256 _tokenId,uint128 _liquidity, uint256 _amount0, uint256 _amount1) =
                            algebraPositionManager.mint(params);

        return (_tokenId, _liquidity);

    }

    function algebraCratePool(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountA,
        uint256 amountB) internal returns (address poolAddress)
    {
        poolAddress = pairFactory.pairFor(tokenA, tokenB, stable);
        if (poolAddress == address(0)) {
            poolAddress = pairFactory.createPair(tokenA, tokenB, stable);
            uint160 sqrtPriceX96 = SqrtPrice.getSqrtPrice(amountA, amountB);
            IAlgebraPool(poolAddress).initialize(sqrtPriceX96);
        }
        return poolAddress;
    }

    function addLiquidityUniswap(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMinimum,
        uint256 amountBMinimum,
        address to,
        uint256 deadline
    ) internal returns (uint liquidity){
        require(false, "//TODO: addLiquidityUniswap");
        liquidity = 0;
        return liquidity;
    }

    function addLiquidityETH(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMinimum,
        uint256 amountETHMinimum,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity){
        IERC20 _token = IERC20(token);
        require(_token.balanceOf(msg.sender) >= amountTokenDesired,
            string(abi.encodePacked("addLiquidityETH: insufficient balance for token: ", _token.symbol())));

        require(_token.allowance(msg.sender, address(this)) >= amountTokenDesired,
            string(abi.encodePacked("addLiquidityETH: insufficient allowance for token: ", _token.symbol())));

        if (isAlgebraMode) {
            return addLiquidityETHAlgebra(token, stable, amountTokenDesired, amountTokenMinimum, amountETHMinimum, to, deadline);
        } else {
            return addLiquidityETHUniswap(token, stable, amountTokenDesired, amountTokenMinimum, amountETHMinimum, to, deadline);
        }
    }

    function addLiquidityETHAlgebra(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMinimum,
        uint256 amountETHMinimum,
        address to,
        uint256 deadline
    ) internal returns (uint256 amountToken, uint256 amountETH, uint256 liquidity){
        require(false, "//TODO: needs implementation");
        return (0, 0, 0);
    }

    function addLiquidityETHUniswap(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMinimum,
        uint256 amountETHMinimum,
        address to,
        uint256 deadline
    ) internal returns (uint256 amountToken, uint256 amountETH, uint256 liquidity){
        require(false, "//TODO: needs implementation");
        return (0, 0, 0);
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH){
        require(false, "//TODO: needs implementation");
        return (0, 0);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH){
        require(false, "//TODO: needs implementation");
        return (0, 0);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external {
        require(false, "//TODO: needs implementation");
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external {
        require(false, "//TODO: needs implementation");
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external {
        require(false, "//TODO: needs implementation");
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'Router: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Router: ZERO_ADDRESS');
    }

    function pairFor(address tokenA, address tokenB, bool stable) public override(IRouter, IUniswapV2Router) view returns (address pair) {
        return pairFactory.pairFor(tokenA, tokenB, stable);
    }

    function isPair(address pair) public view returns (bool) {
        return pairFactory.isPair(pair);
    }

    function metadata(address tokenA, address tokenB, bool stable) external view returns
    (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1)
    {
        return metadata(pairFor(tokenA, tokenB, stable));
    }

    function metadata(address pool) public view returns
    (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1)
    {
        require(pool != address(0), "pool is zero address");
        (t0, t1, st,) = pairFactory.getPairInfo(pool);
        if (isAlgebraMode) {
            (dec0, dec1) = (IERC20(t0).decimals(), IERC20(t1).decimals());
            r0 = IERC20(t0).balanceOf(pool);
            r1 = IERC20(t1).balanceOf(pool);
        } else {
            return IPair(pool).metadata();
        }
    }

}
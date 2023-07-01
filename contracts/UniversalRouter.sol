// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;
import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/ISwapRouter.sol";
import "contracts/interfaces/IUniswapV2Router.sol";
contract UniversalRouter is IUniswapV2Router{
    bool public isAlgebraMode;
    IUniswapV2Router uniswapRouter;
    ISwapRouter algebraRouter;
    address public routerAddress;
    constructor(bool _isAlgebraMode, address _uniswapRouter, address _algebraRouter){
        isAlgebraMode = _isAlgebraMode;
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
        algebraRouter = ISwapRouter(_algebraRouter);
        routerAddress = _isAlgebraMode ? _algebraRouter : _uniswapRouter;
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
        require( token.balanceOf(msg.sender) >= amountIn,
            string(abi.encodePacked("swapExactTokensForTokens: insufficient balance for: ", token.symbol())) );

        require( token.allowance(msg.sender, address(this)) >= amountIn,
            string(abi.encodePacked("swapExactTokensForTokens: insufficient allowance for: ", token.symbol()))  );

        if( isAlgebraMode ){
            return swapExactTokensForTokensAlgebra(tokenIn, tokenOut, amountIn, amountOutMinimum, deadline);
        }else{
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
        IERC20 _tokenA = IERC20(tokenA);
        IERC20 _tokenB = IERC20(tokenB);

        require( _tokenA.balanceOf(msg.sender) >= amountADesired,
            string(abi.encodePacked("addLiquidity: insufficient balance for tokenA: ", _tokenA.symbol())) );
        require( _tokenB.balanceOf(msg.sender) >= amountBDesired,
            string(abi.encodePacked("addLiquidity: insufficient balance for tokenB: ", _tokenA.symbol())) );

        require( _tokenA.allowance(msg.sender, address(this)) >= amountADesired,
            string(abi.encodePacked("addLiquidity: insufficient allowance for tokenA: ", _tokenA.symbol()))  );
        require( _tokenB.allowance(msg.sender, address(this)) >= amountBDesired,
            string(abi.encodePacked("addLiquidity: insufficient allowance for tokenB: ", _tokenB.symbol()))  );

        if( isAlgebraMode ){
            return addLiquidityAlgebra(tokenA, tokenB, amountADesired, amountBDesired, amountAMinimum, amountBMinimum, to, deadline);
        }else{
            return addLiquidityUniswap(tokenA, tokenB, amountADesired, amountBDesired, amountAMinimum, amountBMinimum, to, deadline);
        }
    }
    function addLiquidityAlgebra(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMinimum,
        uint256 amountBMinimum,
        address to,
        uint256 deadline
    ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity){
        require(false, "//TODO: addLiquidityAlgebra");
        return (0,0,0);
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
    ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity){
        require(false, "//TODO: addLiquidityUniswap");
        return (0,0,0);
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
        require( _token.balanceOf(msg.sender) >= amountTokenDesired,
            string(abi.encodePacked("addLiquidityETH: insufficient balance for token: ", _token.symbol())) );

        require( _token.allowance(msg.sender, address(this)) >= amountTokenDesired,
            string(abi.encodePacked("addLiquidityETH: insufficient allowance for token: ", _token.symbol()))  );

        if( isAlgebraMode ){
            return addLiquidityETHAlgebra(token, stable, amountTokenDesired, amountTokenMinimum, amountETHMinimum, to, deadline);
        }else{
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
        require(false,"//TODO: needs implementation");
        return (0,0,0);
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
        require(false,"//TODO: needs implementation");
        return (0,0,0);
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
        return(0,0);
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
        return(0,0);
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external{
        require(false, "//TODO: needs implementation");
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external{
        require(false, "//TODO: needs implementation");
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external{
        require(false, "//TODO: needs implementation");
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'Router: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Router: ZERO_ADDRESS');
    }
    function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
        return uniswapRouter.pairFor(tokenA, tokenB, stable);
    }
    function isPair(address pair) external view returns (bool) {
        return uniswapRouter.isPair(pair);
    }
}
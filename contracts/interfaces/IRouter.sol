// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

interface IRouter {
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function metadata(address tokenA, address tokenB, bool stable) external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
    function metadata(address pool) external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
}

pragma solidity =0.8.13;

import './AlgebraTest.sol';

contract AlgebraPairTest is AlgebraTest {
    bool useMainnetAddresses = true;
    constructor() AlgebraTest(useMainnetAddresses) {
        console2.log("AlgebraPairTest constructor");
    }
    function setUp() public {
        console2.log("AlgebraPairTest setUp");
    }
    function testMain() public{
        console2.log("testMain");
    }
}

pragma solidity =0.8.13;

import './AlgebraTest.sol';
import 'contracts/VotingEscrow.sol';
import 'contracts/Vara.sol';
import 'contracts/VeArtProxy.sol';

contract AlgebraPairTest is AlgebraTest {
    bool useMainnetAddresses = true;
    VotingEscrow escrow;
    Vara VARA;
    VeArtProxy artProxy;
    uint Amount = 5e17;
    constructor() AlgebraTest(useMainnetAddresses) {
        //console2.log("AlgebraPairTest constructor");
    }
    function setUp() public {
        VARA = new Vara();
        artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(VARA), address(artProxy));
    }
    function testCreateLock() public{
        VARA.mint(address(this), Amount);
        VARA.approve(address(escrow), Amount);
        escrow.create_lock(Amount, 4 * 365 * 86400);
        vm.roll(block.number + 1); // fwd 1 block because escrow.balanceOfNFT() returns 0 in same block
        assertGt(escrow.balanceOfNFT(1), 495063075414519385);
        assertEq(VARA.balanceOf(address(escrow)), Amount);
    }

    function testIncreaseLock() public {
        VARA.mint(address(this), Amount);
        VARA.approve(address(escrow), Amount);
        VARA.mint(address(this), Amount);
        escrow.create_lock(Amount, 4 * 365 * 86400);
        vm.roll(block.number + 1); // fwd 1 block because escrow.balanceOfNFT() returns 0 in same block
        assertGt(escrow.balanceOfNFT(1), 495063075414519385);
        assertEq(VARA.balanceOf(address(escrow)), Amount);

        VARA.approve(address(escrow), Amount);
        escrow.increase_amount(1, Amount);
        vm.expectRevert(abi.encodePacked('Can only increase lock duration'));
        escrow.increase_unlock_time(1, 4 * 365 * 86400);
        assertGt(escrow.balanceOfNFT(1), 995063075414519385);
        assertEq(VARA.balanceOf(address(escrow)), 1e18);
    }

}

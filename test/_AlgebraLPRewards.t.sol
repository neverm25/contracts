pragma solidity =0.8.13;

import "./BaseTest.sol";

contract AlgebraLPRewardsTest is BaseTest {
    VotingEscrow escrow;
    GaugeFactory gaugeFactory;
    BribeFactory bribeFactory;
    Voter voter;
    Gauge gauge;

    function setUp() public {
        useAlgebra();
        deployOwners();
        deployCoins();
        mintStables();

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2 * TOKEN_1M; // use 1/2 for veNFT position
        amounts[1] = TOKEN_1M;
        mintVara(owners, amounts);

        // give owner1 veVARA
        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(VARA), address(artProxy));
        VARA.approve(address(escrow), TOKEN_1M);
        escrow.create_lock(TOKEN_1M, 4 * 365 * 86400);

        deployPairFactoryAndRouter();
        deployPairWithOwner(address(owner));
        deployPairWithOwner(address(owner2));
    }

    function testLPsEarnEqualVaraBasedOnVeVara() public {
        console2.log("testLPsEarnEqualVaraBasedOnVeVara");

    }
}

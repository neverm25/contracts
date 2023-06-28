import { ethers } from "ethers";

const MAINNET_CHAIN_ID = 2222;
const TESTNET_CHAIN_ID = 2221;
const HARDHAT_CHAIN_ID = 31337;

function toWei(n: string | number) {
  return ethers.utils.parseEther(n.toString());
}

const mainnet_config = {
  WETH: "0xc86c7C0eFbd6A49B35E8714C5f59D99De09A225b",
  USDC: "0xfA9343C3897324496A05fC75abeD6bAC29f8A40f",
  USDC_DECIMALS: 6,
  wKAVA_USDC: "0x5c27a0d0e6d045b5113d728081268642060f7499",
  VARA_USDC: "0x9bf1E3ee61cBe5C61E520c8BEFf45Ed4D8212a9A",
  VARA_KAVA: "0x7d8100072ba0e4da8dc6bd258859a5dc1a452e05",
  POOL2: "0xCa0d15B4BB6ad730fE40592f9E25A2E052842c92",
  teamEOA: "0x7cef2432A2690168Fb8eb7118A74d5f8EfF9Ef55",
  teamTreasure: '0x3a724E0082b0E833670cF762Ea6bd711bcBdFf37',
  teamMultisig: "0x79dE631fFb7291Acdb50d2717AE32D44D5D00732",
  emergencyCouncil: "0x7cef2432A2690168Fb8eb7118A74d5f8EfF9Ef55",
  merkleRoot: "0x6362f8fcdd558ac55b3570b67fdb1d1673bd01bd53302e42f01377f102ac80a9",
  tokenWhitelist: [],
  partnerAddrs: [

  ],
  partnerAmts: [

  ],

  // algebra config:
};

const testnet_config = {
  WETH: "0x6C2A54580666D69CF904a82D8180F198C03ece67",
  // USDC: "0x43D8814FdFB9B8854422Df13F1c66e34E4fa91fD",
  teamEOA: "0x7cef2432A2690168Fb8eb7118A74d5f8EfF9Ef55",
  teamTreasure: '0x3a724E0082b0E833670cF762Ea6bd711bcBdFf37',
  teamMultisig: '0x3a724E0082b0E833670cF762Ea6bd711bcBdFf37',
  emergencyCouncil: "0x7cef2432A2690168Fb8eb7118A74d5f8EfF9Ef55",
  merkleRoot: "0x6362f8fcdd558ac55b3570b67fdb1d1673bd01bd53302e42f01377f102ac80a9",
  tokenWhitelist: [],
  partnerAddrs: [

  ],
  partnerAmts: [

  ],
  // algebra config:

  Algebra_POOL_INIT_CODE_HASH: "0xc65e01e65f37c1ec2735556a24a9c10e4c33b2613ad486dd8209d465524bc3f4",
  Algebra_Commit: "cec544dbea25a9c884f236f1518e66ac6df2e0c1",
  Algebra_WETH: "0x9D8D5A31E3e46D39D379Da2762fb143c7869a769",
  Algebra_PoolDeployerAddress: "0x03592F961d3e8eA6E284347ec5d84dC6A0Ed41e1",
  Algebra_FactoryAddress: "0x2dfC313b6cAeFe8bDFfef816BeD4C976287F6083",
  Algebra_QuoterAddress: "0x6D1D9932BC8A6190BD6559f2786cfeBe63c44DE5",
  Algebra_SwapRouterAddress: "0xAD776e0A7596430D3107eB1eA986622c455C4a0A",
  Algebra_NonfungibleTokenPositionDescriptorAddress: "0x678161abA75673c7B0368dc2907F13379Bc5069f",
  Algebra_NonfungiblePositionManagerAddress: "0x80bBD8C91612eEc110a24091cf5C4DaA5D0Fe7A7",
  Algebra_InterfaceMulticallAddress: "0xcfC30f0074f54015D7481b36b3490e710e7602Dc",
  Algebra_LimitFarmingAddress: "0x3e61E3F9A75E859A7B1B59C41e1d5FBa6F3a7Bc7",
  Algebra_EternalFarmingAddress: "0x43c5c0756fA7F466915370D81abE32eB1aF48494",
  Algebra_FarmingCenterAddress: "0x09c82656190654b02eE3D4BdB7598084Bc93Cf2D"
};



export default function getDeploymentConfig(id:number): any {
  if( id === MAINNET_CHAIN_ID) {
    return mainnet_config
  }else if(id === TESTNET_CHAIN_ID) {
    return testnet_config
  }else if(id === HARDHAT_CHAIN_ID) {
    return testnet_config
  }
  new Error(`chain id ${id} not supported, supported are mainnet=${MAINNET_CHAIN_ID} and testnet=${TESTNET_CHAIN_ID}.`);
}

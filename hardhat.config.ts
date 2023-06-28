import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-preprocessor";
import "hardhat-abi-exporter";
import {resolve} from "path";
import {config as dotenvConfig} from "dotenv";
dotenvConfig({path: resolve(__dirname, "./.env")});
import "./hardhat.tasks.ts";
const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            forking: {
                url: "https://evm.testnet.kava.io",
                blockNumber: 5966580
            }
        },
        mainnet: {
            url: "https://evm.kava.io",
            accounts: [process.env.PRIVATE_KEY!]
        },
        testnet: {
            url: "https://evm.testnet.kava.io",
            accounts: [process.env.PRIVATE_KEY!]
        },
    },
    solidity: {
        version: "0.8.13",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    etherscan: {
        apiKey: {
            testnet: 'x',
            mainnet: 'x',
            bscTestnet: `${process.env.BSCSCAN}`
        },
        customChains: [
            {
                network: "mainnet",
                chainId: 2222,
                urls: {
                    apiURL: "https://explorer.kava.io/api",
                    browserURL: "https://explorer.kava.io"
                }
            },
            { // npx hardhat verify --list-networks
                network: "testnet",
                chainId: 2221,
                urls: {
                    apiURL: "https://explorer.testnet.kava.io/api",
                    browserURL: "https://explorer.testnet.kava.io"
                }
            }
        ]
    }
};


export default config;

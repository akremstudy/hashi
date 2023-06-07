import { expect } from "chai"
import { ethers, network } from "hardhat"

const CHAIN_ID = 1
const BLOCK_NUMBER = 12345
// Encoding data for the oracle according to tellor specs (see: https://github.com/tellor-io/dataSpecs)
const params = ethers.utils.defaultAbiCoder.encode(["uint256", "uint256"], [CHAIN_ID, BLOCK_NUMBER])
const queryData = ethers.utils.defaultAbiCoder.encode(["string", "bytes"], ["EVMHeader", params])
const queryId = ethers.utils.keccak256(queryData)
const HASH_VALUE = "0x0000000000000000000000000000000000000000000000000000000000000001"
const reportedValue = ethers.utils.defaultAbiCoder.encode(["bytes32"], [HASH_VALUE])

const setup = async () => {
  await network.provider.request({ method: "hardhat_reset", params: [] })
  const playground = await ethers.getContractFactory("TellorPlayground")
  const tellorPlayground = await playground.deploy()
  const TELLORAdapter = await ethers.getContractFactory("TellorAdapter")
  const tellorAdapter = await TELLORAdapter.deploy(tellorPlayground.address)
  return {
    tellorPlayground,
    tellorAdapter,
  }
}

const advanceTimeByMinutes = async (minutes: number) => {
  // Get the current block
  const currentBlock = await ethers.provider.getBlock("latest")
  // Calculate the time for the next block
  const nextBlockTime = currentBlock.timestamp + minutes * 60 // increase by n minutes
  // Advance time by sending a request directly to the node
  await ethers.provider.send("evm_setNextBlockTimestamp", [nextBlockTime])
  // Mine the next block for the time change to take effect
  await ethers.provider.send("evm_mine", [])
}

describe("TELLORAdapter", () => {
  describe("Constructor", () => {
    it("Successfully deploy contract", async function () {
      const { tellorPlayground, tellorAdapter } = await setup()
      expect(await tellorAdapter.deployed())
      expect(await tellorAdapter.tellor()).to.equal(tellorPlayground.address)
    })
  })

  describe("StoreHash()", () => {
    it("Stores hash", async () => {
      const { tellorPlayground, tellorAdapter } = await setup()
      // submit value to tellor oracle
      await tellorPlayground.submitValue(queryId, reportedValue, 0, queryData)
      // fails if 15 minutes have not passed
      await expect(tellorAdapter.storeHash(CHAIN_ID, BLOCK_NUMBER)).to.revertedWithCustomError(
        tellorAdapter,
        "BlockHashNotAvailable",
      )
      // advance time by 15 minutes to bypass security delay
      await advanceTimeByMinutes(15)
      // store hash
      await tellorAdapter.storeHash(CHAIN_ID, BLOCK_NUMBER)
      expect(await tellorAdapter.getHashFromOracle(CHAIN_ID, BLOCK_NUMBER)).to.equal(HASH_VALUE)
    })
  })

  describe("getHashFromOracle()", function () {
    it("Returns 0 if no header is stored", async function () {
      const { tellorAdapter } = await setup()
      expect(await tellorAdapter.getHashFromOracle(CHAIN_ID, BLOCK_NUMBER)).to.equal(
        "0x0000000000000000000000000000000000000000000000000000000000000000",
      )
    })
  })
})

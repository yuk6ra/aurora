const { ethers } = require("hardhat");

describe("DeployTest", function() {
    it("", async function () {
        const nftContractFactory = await ethers.getContractFactory("Seras");
        const nftContract = await nftContractFactory.deploy();
        await nftContract.deployed();
        console.log("Contract deployed to:", nftContract.address);
        
        for (let i=0; i<10; i++){
          let txn = await nftContract.mintNFT();
          await txn.wait();
          console.log("%d 回目", i);
        };
    
    
        console.log("Done");    
    })
})


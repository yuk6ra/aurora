const main = async () => {
    const nftContractFactory = await hre.ethers.getContractFactory("Seras");
    const nftContract = await nftContractFactory.deploy();
    await nftContract.deployed();
    console.log("Contract deployed to:", nftContract.address);

    let length = 20;
    for (let i=0; i<length; i++){
      let txn = await nftContract.mintNFT();
      await txn.wait();
      console.log("%d 回目", i);
    };

    console.log("Done");



};
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  runMain();
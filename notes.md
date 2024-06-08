
Invariants
- User can only select ram once.

Possible vulnurablities

Choosing Ram contract
- Uses a weak PRNG to select the ram Nft to be used.
- The `isRamSelected` variable is not updated meaning the ram can be selected more than once.
- An invalid tokenIdOfChallenger and tokenIdofAnyPerticipent can be passed to the increaseValue function.

RamNFT contract
- Anyone can mint the RamNft, when it is just supposed to be minted by the dussehra contract.
- If the RamNFT is transferred from a user to another it will not update the ram characteristics of the RamNFT.

Dussehra contract
- if ravanna is not killed on the specified day all the funds sent to the contract will be stuck.
- possible reentrancy in the withdraw function in the contract.
- killRavanna can be called by anyone, and if called twice it wil transfer all the funds in the contract to the organiser.

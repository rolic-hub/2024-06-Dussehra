### [S-#] TITLE (Root Cause -> Impact)

**Description:** 

**Impact:** 

**Proof of Concept:**

**Recommended Mitigation:** 


### [H-1] Weak Pseudo-Random Number Generator used in `ChoosingRam::increaseValuesOfParticipants` function.

**Description:** Hashing msg.sender, block.timestamp, block.prevrandao together creates a predictable final number. A predictable number is not a good random number. Malicious users can manipulate these values or know them ahead of time so that they can be selected as ram.

**Impact:** A user can choose which address becomes the ram. Therefore getting the funds sent to the ram.

**Proof of Concept:**
1. Validators can know ahead of time the block.timestamp and block.prevrando and use that knowledge to predict when / how to participate. See this article on prevrando [here](https://medium.com/@alexbabits/why-block-prevrandao-is-a-useless-dangerous-trap-and-how-to-fix-it-5367ed3c6dfc). 
2. Users can mine/manipulate the msg.sender value to result in their address being used to generate a random number in their favour.
3. Users can revert the `ChoosingRam::increaseValuesOfParticipants` transaction if they do not like the resulting random number.

**Recommended Mitigation:** Consider using a cryptographically provable random number generator such as Chainlink VRF.


### [H-2] `ChoosingRam::isRamSelected` is not updated when a ram is selected in the `ChoosingRam::increaseValuesOfParticipants` function

**Description:** The `isRamSelected` variable keeps track of whether a ram has been selected or not but it doesn't get updated in the `ChoosingRam::increaseValuesOfParticipants` function when a ram is selected. 

**Impact:** Functions depending on the `ChoosingRam::RamIsNotSelected` modifier will return wrong values when a ram is selected through the `ChoosingRam::increaseValuesOfParticipantsParticipants` function.
- `ChoosingRam::increaseValuesOfParticipantsParticipants` can still be called after a ram has been selected.
- `ChoosingRam::selectRamIfNotSelected` can still be called after a ram has been selected using the `ChoosingRam::increaseValuesOfParticipantsParticipants` function.
- `Dussehra::killRavana` will not run because it depends on the value of `ChoosingRam::RamIsNotSelected` modifier which is incorrect.
- `Dussehra::withdraw` will not run because it depends on the value of `ChoosingRam::RamIsNotSelected` modifier which is incorrect.

**Proof of Concept:**
<details>
<summary> Code</summary>

```javascript
  function test_IsRamSelectedNotUpdated() public Moreparticipants {
        vm.startPrank(player1);
        choosingRam.increaseValuesOfParticipants(0, 1);
        choosingRam.increaseValuesOfParticipants(0, 1);
        choosingRam.increaseValuesOfParticipants(0, 1);
        choosingRam.increaseValuesOfParticipants(0, 1);
        choosingRam.increaseValuesOfParticipants(0, 1);
        vm.stopPrank();

        assertEq(ramNFT.getCharacteristics(1).isJitaKrodhah, true);
        assertEq(ramNFT.getCharacteristics(1).isDhyutimaan, true);
        assertEq(ramNFT.getCharacteristics(1).isVidvaan, true);
        assertEq(ramNFT.getCharacteristics(1).isAatmavan, true);
        assertEq(ramNFT.getCharacteristics(1).isSatyavaakyah, true);
        assertEq(choosingRam.selectedRam(), player2);
        // ---  isRamSelected is not set to true after ram has been selected ----------
        assertNotEq(choosingRam.isRamSelected(), true);

        // ------ The function selectRamIfNotSelected still runs when a ram has been selected -------
        vm.warp(1728691200 + 1);
        vm.startPrank(organiser);
        choosingRam.selectRamIfNotSelected();
        vm.stopPrank();
        //---- The selected Ram has been changed ----------
        assertEq(choosingRam.selectedRam(), player3);
        assertEq(choosingRam.isRamSelected(), true);
    }
```
</details>

**Recommended Mitigation:** Update the `isRamSelected` variable after selecting a ram in the `ChoosingRam::increaseValuesOfParticipantsParticipants` function.

```diff
 } else if (ramNFT.getCharacteristics(tokenIdOfChallenger).isSatyavaakyah == false){
                ramNFT.updateCharacteristics(tokenIdOfChallenger, true, true, true, true, true);
                selectedRam = ramNFT.getCharacteristics(tokenIdOfChallenger).ram;
+               isRamSelected = true;
            }
```
```diff
 } else if (ramNFT.getCharacteristics(tokenIdOfAnyPerticipent).isSatyavaakyah == false){
                ramNFT.updateCharacteristics(tokenIdOfAnyPerticipent, true, true, true, true, true);
                selectedRam = ramNFT.getCharacteristics(tokenIdOfAnyPerticipent).ram;
+               isRamSelected = true;
            }
```


### [H-3] No acess control on the `RamNFT::mintRamNFT` function.

**Description:** For a user to get the RamNFT they need to call the `Dussehra::enterPeopleWhoLikeRam` function, pay the entrance fee and then mint the RamNFT and it can only be done once. But a user can bypass this by calling the `RamNFT::mintRamNFT` function directly.

**Impact:** The user can mint the RamNft without payying the entrance fee, they can mint as much RamNFT as they want, get their RamNFT to be selected as ram and collect the rewards.

**Proof of Concept:**
<details>
<summary> Code </summary>

```javascript
    function test_CanMintNftWithoutPaying() public {
        vm.startPrank(player1);
        ramNFT.mintRamNFT(player1);
        vm.stopPrank();

        assertEq(ramNFT.ownerOf(0), player1);
    }
```
</details>

**Recommended Mitigation:** Add acess control to the `RamNFT::mintRamNFT` function so it can only be called by the `Dussehra` contract.


### [H-4] If the `Dussehra::killRavana` function is not called during the Mahurat all the funds in the contract will be stuck.

**Description:** The `Dussehra::killRavana` function can only be called during the Mahurat which means any call to it before or after the Mahurat will revert.

**Impact:** If the `Dussehra::killRavana` function is not called and the Mahurat has ended then the ether in the contract will be stuck as the withdraw function only works if the `Dussehra::killRavana` function has been called.

**Proof of Concept:**
<details>
<summary>Code</summary>

```javascript
  function test_RavannaNotKilled() public Moreparticipants selectedRam {
        vm.warp(1728777669 + 1);
        vm.expectRevert(
            abi.encodeWithSelector(Dussehra__MahuratIsFinished.selector)
        );
        vm.startPrank(player2);
        dussehra.killRavana();
        vm.stopPrank();

        vm.expectRevert();
        vm.startPrank(player3);
        dussehra.withdraw();
        vm.stopPrank();
    }
```

</details>

**Recommended Mitigation:** Add a backup withdraw fuction that can remove the funds from the contract if the `Dussehra::killRavana` function is not called.

### [H-5] A user can pass the same tokenIds as parameters to the `ChoosingRam::increaseValuesOfParticipants` function.

**Description:** The `ChoosingRam::increaseValuesOfParticipants` function increases the characteristics of either RamNFT's whose tokenIds were passed and selects one as the ram if it has all it's characteristics updated, it does this based on a generated random number.

**Impact:** If the user passes the same tokenId for both parameters, then the RamNFT with that tokenId will definately be choosen.

**Proof of Concept:**
<details>
<summary>Code</summary>

```javascript
function test_SameTokenIds() public Moreparticipants {
        // valid tokenIds are 0,1,2.
        vm.startPrank(player1);
        choosingRam.increaseValuesOfParticipants(0, 0);
        choosingRam.increaseValuesOfParticipants(0, 0);
        choosingRam.increaseValuesOfParticipants(0, 0);
        choosingRam.increaseValuesOfParticipants(0, 0);
        choosingRam.increaseValuesOfParticipants(0, 0);
        vm.stopPrank();

        assertEq(ramNFT.getCharacteristics(0).isJitaKrodhah, true);
        assertEq(ramNFT.getCharacteristics(0).isDhyutimaan, true);
        assertEq(ramNFT.getCharacteristics(0).isVidvaan, true);
        assertEq(ramNFT.getCharacteristics(0).isAatmavan, true);
        assertEq(ramNFT.getCharacteristics(0).isSatyavaakyah, true);
        assertEq(choosingRam.selectedRam(), player1);
    }
```
</details>

**Recommended Mitigation:** Perform checks to stop users from providing the same tokenIds as both parameters.

### [M-1] An invalid tokenId can be passed to the `ChoosingRam::increaseValuesOfParticipants` function as the `tokenIdOfAnyPerticipent` parameter.

**Description:** The function `ChoosingRam::increaseValuesOfParticipants` performs a check to determine if a tokenId is valid, but an invalid tokenId can still be passed as a parameter.

**Impact:** The selected ram could be the zero address which would lead to funds getting stuck in the contract.

**Proof of Concept:**
<details>
<summary>Code</summary>

```javascript
     function test_InvalidTokenIds() public Moreparticipants {
        // valid tokenIds are 0,1,2.
        vm.startPrank(player1);
        choosingRam.increaseValuesOfParticipants(0, 3);
        choosingRam.increaseValuesOfParticipants(0, 3);
        choosingRam.increaseValuesOfParticipants(0, 3);
        choosingRam.increaseValuesOfParticipants(0, 3);
        choosingRam.increaseValuesOfParticipants(0, 3);
        vm.stopPrank();
    }
```
</details>

**Recommended Mitigation:** Enforce stricter constraints on the tokenIds of participants in the `ChoosingRam::increaseValuesOfParticipants` function.

```diff
- if (tokenIdOfChallenger > ramNFT.tokenCounter()) {
+ if (tokenIdOfChallenger >= ramNFT.tokenCounter()) {
            revert ChoosingRam__InvalidTokenIdOfChallenger();
        }
```
```diff
- if (tokenIdOfAnyPerticipent > ramNFT.tokenCounter()) {
+ if (tokenIdOfAnyPerticipent >= ramNFT.tokenCounter()) {
            revert ChoosingRam__InvalidTokenIdOfPerticipent();
        }
```

### [M-2] if the `Dussehra::killRavana` function is called twice all the funds in the contract are sent to the organiser.

**Description:** The `Dussehra::killRavana` function when called sets `IsRavanKilled` to true and sends half the funds in the contract to the organiser, and the remaining half is given to the selected ram.

**Impact:** If the `Dussehra::killRavana` function is called twice all the ether will be sent to the organiser and the selected ram will not get any ether.

**Proof of Concept:**
<details>
<summary>Code </summary>

```javascript
 function test_killRavanaTwice() public Moreparticipants {
        vm.warp(1728691200 + 1);
        vm.startPrank(organiser);
        choosingRam.selectRamIfNotSelected();
        vm.stopPrank();

        vm.startPrank(player2);
        dussehra.killRavana();
        vm.stopPrank();

        assertEq(dussehra.IsRavanKilled(), true);
        assertEq(address(dussehra).balance, 1.5 ether);

        vm.startPrank(player2);
        dussehra.killRavana();
        vm.stopPrank();

        assertEq(address(dussehra).balance, 0);
    }
```
</details>

**Recommended Mitigation:** 

### [L-1] Reentrancy attack in `Dussehra::withdraw` function.

**Description:** The function `Dussehra::withdraw` does not follow CEI (checks, effects, interactions).

**Recommended Mitigation:** Follow CEI

### [L-2] Transfer of the RamNft does not update the ram characteristics of the NFT. 

**Description:** If the Ram NFT is transfered the ram characteristics is not updated.

**Impact:** If the transferred NFT is selected as ram by the `ChoosingRam::selectRamIfNotSelected` function the reward will go the original owner.

**Proof of Concept:**
<details>
<summary>Code</summary>

```javascript
 function test_transferDoesNotUpdateRam() public participants {
        vm.startPrank(player1);
        ramNFT.transferFrom(player1, player4, 0);
        vm.stopPrank();

        assertEq(ramNFT.ownerOf(0), player4);
        assertNotEq(ramNFT.getCharacteristics(0).ram, player4);
    }
```
</details>

**Recommended Mitigation:** In the `RamNFT::mintRamNFT` function the ram characteristics should be set to the owner of the NFT.

```diff
         uint256 newTokenId = tokenCounter++;
          _safeMint(to, newTokenId);

     Characteristics[newTokenId] = CharacteristicsOfRam({
-           ram: to,
+           ram: ownerOf(newTokenId),
            isJitaKrodhah: false,
```
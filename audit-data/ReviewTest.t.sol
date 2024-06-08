// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CounterTest} from "../test/Dussehra.t.sol";

contract ReviewTest is CounterTest {
    error Dussehra__MahuratIsFinished();

    modifier Moreparticipants() {
        vm.startPrank(player1);
        vm.deal(player1, 1 ether);
        dussehra.enterPeopleWhoLikeRam{value: 1 ether}();
        vm.stopPrank();

        vm.startPrank(player2);
        vm.deal(player2, 1 ether);
        dussehra.enterPeopleWhoLikeRam{value: 1 ether}();
        vm.stopPrank();

        vm.startPrank(player3);
        vm.deal(player3, 1 ether);
        dussehra.enterPeopleWhoLikeRam{value: 1 ether}();
        vm.stopPrank();

        _;
    }

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

    function test_CanMintNftWithoutPaying() public {
        vm.startPrank(player1);
        ramNFT.mintRamNFT(player1);
        vm.stopPrank();

        assertEq(ramNFT.ownerOf(0), player1);
    }

    function test_transferDoesNotUpdateRam() public participants {
        vm.startPrank(player1);
        ramNFT.transferFrom(player1, player4, 0);
        vm.stopPrank();

        assertEq(ramNFT.ownerOf(0), player4);
        assertNotEq(ramNFT.getCharacteristics(0).ram, player4);
    }

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

    modifier selectedRam() {
        vm.warp(1728691200 + 1);
        vm.startPrank(organiser);
        choosingRam.selectRamIfNotSelected();
        vm.stopPrank();
        _;
    }

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
}

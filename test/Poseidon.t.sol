// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contract/Poseidon.sol";

contract PoseidonTest is Test, Poseidon {
    // Poseidon poseidon;

    function setUp() public {
        // poseidon = new Poseidon();
    }

    function testPoseidon() public {
        uint256[] memory input = new uint256[](1);
        input[0] = 1;
        uint256 gasBefore = gasleft();
        uint256[] memory output = _hash_n_to_m_no_pad(input, 4);
        uint256 gasAfter = gasleft();
        console.log("used gas: %d", gasBefore - gasAfter);
        assertEq(output[0], 15020833855946683413);
        assertEq(output[1], 2541896837400596712);
        assertEq(output[2], 5158482081674306993);
        assertEq(output[3], 15736419290823331982);
    }

    function testPoseidon2() public {
        uint256[] memory input = new uint256[](25);
        input[0] = 4088194805928112242;
        input[1] = 8140768382984964622;
        input[2] = 5816657578757942728;
        input[3] = 15334486883421136427;
        input[4] = 3055007571073132374;
        input[5] = 5599380483590759825;
        input[6] = 1057514923199238985;
        input[7] = 3527996190097743962;
        input[8] = 11862017229263766501;
        input[9] = 4299934289621495432;
        input[10] = 2128895091422473142;
        input[11] = 12758255335137981186;
        input[12] = 5420315904621164225;
        input[13] = 106443409350232187;
        input[14] = 6362855422135419825;
        input[15] = 4736094260531973232;
        input[16] = 2321920872760705857;
        input[17] = 18301143603676736896;
        input[18] = 16733716340403255659;
        input[19] = 321102552645973986;
        input[20] = 14260381720207888620;
        input[21] = 13753016218528019718;
        input[22] = 9953973515768245657;
        input[23] = 6402759260140800990;
        input[24] = 16262828528196590002;
        uint256 gasBefore = gasleft();
        uint256[] memory output = _hash_n_to_m_no_pad(input, 12);
        uint256 gasAfter = gasleft();
        console.log("used gas: %d", gasBefore - gasAfter);
        assertEq(output[0], 7135061599080748188);
        assertEq(output[1], 11471096164861650587);
        assertEq(output[2], 11294154715596677343);
        assertEq(output[3], 5800010168576418409);
        assertEq(output[4], 239138727744614693);
        assertEq(output[5], 17972373964258615322);
        assertEq(output[6], 9299160449921744509);
        assertEq(output[7], 11367124813155998363);
        assertEq(output[8], 14501251702996346986);
        assertEq(output[9], 12026939365297242312);
        assertEq(output[10], 1924463475056054991);
        assertEq(output[11], 314816855150373651);
    }
}

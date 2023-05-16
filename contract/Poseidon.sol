// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";

contract Poseidon {
    uint256 public constant HALF_N_FULL_ROUNDS = 4;
    uint256 constant N_FULL_ROUNDS_TOTAL = 2 * HALF_N_FULL_ROUNDS;
    uint256 constant N_PARTIAL_ROUNDS = 22;
    uint256 constant N_ROUNDS = N_FULL_ROUNDS_TOTAL + N_PARTIAL_ROUNDS;
    uint256 constant MAX_WIDTH = 12;
    uint256 constant WIDTH = 12;
    uint256 constant SPONGE_RATE = 8;
    uint256 constant ORDER = 18446744069414584321;
    uint256 constant MDS_MATRIX_CIRC_0 = 17;
    uint256 constant MDS_MATRIX_CIRC_1 = 15;
    uint256 constant MDS_MATRIX_CIRC_2 = 41;
    uint256 constant MDS_MATRIX_CIRC_3 = 16;
    uint256 constant MDS_MATRIX_CIRC_4 = 2;
    uint256 constant MDS_MATRIX_CIRC_5 = 28;
    uint256 constant MDS_MATRIX_CIRC_6 = 13;
    uint256 constant MDS_MATRIX_CIRC_7 = 13;
    uint256 constant MDS_MATRIX_CIRC_8 = 39;
    uint256 constant MDS_MATRIX_CIRC_9 = 18;
    uint256 constant MDS_MATRIX_CIRC_10 = 34;
    uint256 constant MDS_MATRIX_CIRC_11 = 20;

    uint256 constant MDS_MATRIX_DIAG_0 = 8;

    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_0 = 0x3cc3f892184df408;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_1 = 0xe993fd841e7e97f1;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_2 = 0xf2831d3575f0f3af;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_3 = 0xd2500e0a350994ca;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_4 = 0xc5571f35d7288633;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_5 = 0x91d89c5184109a02;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_6 = 0xf37f925d04e5667b;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_7 = 0x2d6e448371955a69;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_8 = 0x740ef19ce01398a1;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_9 = 0x694d24c0752fdf45;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_10 = 0x60936af96ee2f148;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_11 = 0xc33448feadc78f0c;

    function mod(uint256 a) internal pure returns (uint256 res) {
        assembly {
            res := mod(a, ORDER)
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 res) {
        assembly {
            res := mulmod(a, b, ORDER)
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 res) {
        assembly {
            res := addmod(a, b, ORDER)
        }
    }

    // `v[r]` allows 192 bits number.
    // `res` is 200 bits number.
    // 1118 ~ 1180 gas
    function _mds_row_shf(
        uint256 r,
        uint256[WIDTH] memory v
    ) internal pure returns (uint256 res) {
        // uint256 res = 0;
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += v[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res += v[r] * MDS_MATRIX_CIRC_0;
            res += v[(r + 1) % WIDTH] * MDS_MATRIX_CIRC_1;
            res += v[(r + 2) % WIDTH] * MDS_MATRIX_CIRC_2;
            res += v[(r + 3) % WIDTH] * MDS_MATRIX_CIRC_3;
            res += v[(r + 4) % WIDTH] * MDS_MATRIX_CIRC_4;
            res += v[(r + 5) % WIDTH] * MDS_MATRIX_CIRC_5;
            res += v[(r + 6) % WIDTH] * MDS_MATRIX_CIRC_6;
            res += v[(r + 7) % WIDTH] * MDS_MATRIX_CIRC_7;
            res += v[(r + 8) % WIDTH] * MDS_MATRIX_CIRC_8;
            res += v[(r + 9) % WIDTH] * MDS_MATRIX_CIRC_9;
            res += v[(r + 10) % WIDTH] * MDS_MATRIX_CIRC_10;
            res += v[(r + 11) % WIDTH] * MDS_MATRIX_CIRC_11;

            // res = add(res, v[r] * MDS_MATRIX_DIAG[r]);
            if (r == 0) {
                res += v[0] * 8; // 200 bits
            }
        }
    }

    // 10614 gas
    function _mds_layer(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256[WIDTH] memory new_state) {
        // for (uint256 r = 0; r < 12; r++) {
        //     new_state[r] = _mds_row_shf(r, state);
        // }
        new_state[0] = _mds_row_shf(0, state);
        new_state[1] = _mds_row_shf(1, state);
        new_state[2] = _mds_row_shf(2, state);
        new_state[3] = _mds_row_shf(3, state);
        new_state[4] = _mds_row_shf(4, state);
        new_state[5] = _mds_row_shf(5, state);
        new_state[6] = _mds_row_shf(6, state);
        new_state[7] = _mds_row_shf(7, state);
        new_state[8] = _mds_row_shf(8, state);
        new_state[9] = _mds_row_shf(9, state);
        new_state[10] = _mds_row_shf(10, state);
        new_state[11] = _mds_row_shf(11, state);
    }

    function _mds_partial_layer_init(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256[WIDTH] memory new_state) {
        new_state[0] = state[0];
        
        unchecked {
            new_state[1] = state[1] * 0x80772dc2645b280b
                + state[2] * 0xe796d293a47a64cb
                + state[3] * 0xdcedab70f40718ba
                + state[4] * 0xf4a437f2888ae909
                + state[5] * 0xf97abba0dffb6c50
                + state[6] * 0x7f8e41e0b0a6cdff
                + state[7] * 0x726af914971c1374
                + state[8] * 0x64dd936da878404d
                + state[9] * 0x85418a9fef8a9890
                + state[10] * 0x156048ee7a738154
                + state[11] * 0xd841e8ef9dde8ba0;
            new_state[2] = state[1] * 0xdc927721da922cf8
                + state[2] * 0xb124c33152a2421a
                + state[3] * 0x14a4a64da0b2668f
                + state[4] * 0xc537d44dc2875403
                + state[5] * 0x5e40f0c9bb82aab5
                + state[6] * 0x4b1ba8d40afca97d
                + state[7] * 0x1d7f8a2cce1a9d00
                + state[8] * 0x4db9a2ead2bd7262
                + state[9] * 0xd8a2eb7ef5e707ad
                + state[10] * 0x91f7562377e81df5
                + state[11] * 0x156048ee7a738154;
            new_state[3] = state[1] * 0xc1978156516879ad
                + state[2] * 0x0ee5dc0ce131268a
                + state[3] * 0x4715b8e5ab34653b
                + state[4] * 0x7f68007619fd8ba9
                + state[5] * 0x5996a80497e24a6b
                + state[6] * 0x623708f28fca70e8
                + state[7] * 0x18737784700c75cd
                + state[8] * 0xbe2e19f6d07f1a83
                + state[9] * 0xbfe85ababed2d882
                + state[10] * 0xd8a2eb7ef5e707ad
                + state[11] * 0x85418a9fef8a9890;
            new_state[4] = state[1] * 0x90e80c591f48b603
                + state[2] * 0xa9032a52f930fae6
                + state[3] * 0x1e8916a99c93a88e
                + state[4] * 0xa4911db6a32612da
                + state[5] * 0x07084430a7307c9a
                + state[6] * 0xbf150dc4914d380f
                + state[7] * 0x7fb45d605dd82838
                + state[8] * 0x02290fe23c20351a
                + state[9] * 0xbe2e19f6d07f1a83
                + state[10] * 0x4db9a2ead2bd7262
                + state[11] * 0x64dd936da878404d;
            new_state[5] = state[1] * 0x3a2432625475e3ae
                + state[2] * 0x7e33ca8c814280de
                + state[3] * 0xbba4b5d86b9a3b2c
                + state[4] * 0x2f7e9aade3fdaec1
                + state[5] * 0xad2f570a5b8545aa
                + state[6] * 0xc26a083554767106
                + state[7] * 0x862361aeab0f9b6e
                + state[8] * 0x7fb45d605dd82838
                + state[9] * 0x18737784700c75cd
                + state[10] * 0x1d7f8a2cce1a9d00
                + state[11] * 0x726af914971c1374;
            new_state[6] = state[1] * 0x00a2d4321cca94fe
                + state[2] * 0xad11180f69a8c29e
                + state[3] * 0xe76649f9bd5d5c2e
                + state[4] * 0xe7ffd578da4ea43d
                + state[5] * 0xab7f81fef4274770
                + state[6] * 0x753b8b1126665c22
                + state[7] * 0xc26a083554767106
                + state[8] * 0xbf150dc4914d380f
                + state[9] * 0x623708f28fca70e8
                + state[10] * 0x4b1ba8d40afca97d
                + state[11] * 0x7f8e41e0b0a6cdff;
            new_state[7] = state[1] * 0x77736f524010c932
                + state[2] * 0xc75ac6d5b5a10ff3
                + state[3] * 0xaf8e2518a1ece54d
                + state[4] * 0x43a608e7afa6b5c2
                + state[5] * 0xcb81f535cf98c9e9
                + state[6] * 0xab7f81fef4274770
                + state[7] * 0xad2f570a5b8545aa
                + state[8] * 0x07084430a7307c9a
                + state[9] * 0x5996a80497e24a6b
                + state[10] * 0x5e40f0c9bb82aab5
                + state[11] * 0xf97abba0dffb6c50;
            new_state[8] = state[1] * 0x904d3f2804a36c54
                + state[2] * 0xf0674a8dc5a387ec
                + state[3] * 0xdcda1344cdca873f
                + state[4] * 0xca46546aa99e1575
                + state[5] * 0x43a608e7afa6b5c2
                + state[6] * 0xe7ffd578da4ea43d
                + state[7] * 0x2f7e9aade3fdaec1
                + state[8] * 0xa4911db6a32612da
                + state[9] * 0x7f68007619fd8ba9
                + state[10] * 0xc537d44dc2875403
                + state[11] * 0xf4a437f2888ae909;
            new_state[9] = state[1] * 0xbf9b39e28a16f354
                + state[2] * 0xb36d43120eaa5e2b
                + state[3] * 0xcd080204256088e5
                + state[4] * 0xdcda1344cdca873f
                + state[5] * 0xaf8e2518a1ece54d
                + state[6] * 0xe76649f9bd5d5c2e
                + state[7] * 0xbba4b5d86b9a3b2c
                + state[8] * 0x1e8916a99c93a88e
                + state[9] * 0x4715b8e5ab34653b
                + state[10] * 0x14a4a64da0b2668f
                + state[11] * 0xdcedab70f40718ba;
            new_state[10] = state[1] * 0x3a1ded54a6cd058b
                + state[2] * 0x6f232aab4b533a25
                + state[3] * 0xb36d43120eaa5e2b
                + state[4] * 0xf0674a8dc5a387ec
                + state[5] * 0xc75ac6d5b5a10ff3
                + state[6] * 0xad11180f69a8c29e
                + state[7] * 0x7e33ca8c814280de
                + state[8] * 0xa9032a52f930fae6
                + state[9] * 0x0ee5dc0ce131268a
                + state[10] * 0xb124c33152a2421a
                + state[11] * 0xe796d293a47a64cb;
            new_state[11] = state[1] * 0x42392870da5737cf
                + state[2] * 0x3a1ded54a6cd058b
                + state[3] * 0xbf9b39e28a16f354
                + state[4] * 0x904d3f2804a36c54
                + state[5] * 0x77736f524010c932
                + state[6] * 0x00a2d4321cca94fe
                + state[7] * 0x3a2432625475e3ae
                + state[8] * 0x90e80c591f48b603
                + state[9] * 0xc1978156516879ad
                + state[10] * 0xdc927721da922cf8
                + state[11] * 0x80772dc2645b280b;
        }
    }

    // `state[i]` allows 193 bits number.
    // `new_state[i]` is 64 bits number.
    function _mds_partial_layer_fast(
        uint256[WIDTH] memory state,
        uint256 r
    ) internal pure returns (uint256[WIDTH] memory new_state) {
        uint256 d_sum = 0;
        unchecked {
            // for (uint256 i = 1; i < 12; i++) {
            //     d_sum += state[i] * FAST_PARTIAL_ROUND_W_HATS[r][i - 1];
            // }

            if (r == 0) {
                d_sum += state[1] * 0x3d999c961b7c63b0;
                d_sum += state[2] * 0x814e82efcd172529;
                d_sum += state[3] * 0x2421e5d236704588;
                d_sum += state[4] * 0x887af7d4dd482328;
                d_sum += state[5] * 0xa5e9c291f6119b27;
                d_sum += state[6] * 0xbdc52b2676a4b4aa;
                d_sum += state[7] * 0x64832009d29bcf57;
                d_sum += state[8] * 0x09c4155174a552cc;
                d_sum += state[9] * 0x463f9ee03d290810;
                d_sum += state[10] * 0xc810936e64982542;
                d_sum += state[11] * 0x043b1c289f7bc3ac;
            } else if (r == 1) {
                d_sum += state[1] * 0x673655aae8be5a8b;
                d_sum += state[2] * 0xd510fe714f39fa10;
                d_sum += state[3] * 0x2c68a099b51c9e73;
                d_sum += state[4] * 0xa667bfa9aa96999d;
                d_sum += state[5] * 0x4d67e72f063e2108;
                d_sum += state[6] * 0xf84dde3e6acda179;
                d_sum += state[7] * 0x40f9cc8c08f80981;
                d_sum += state[8] * 0x5ead032050097142;
                d_sum += state[9] * 0x6591b02092d671bb;
                d_sum += state[10] * 0x00e18c71963dd1b7;
                d_sum += state[11] * 0x8a21bcd24a14218a;
            } else if (r == 2) {
                d_sum += state[1] * 0x202800f4addbdc87;
                d_sum += state[2] * 0xe4b5bdb1cc3504ff;
                d_sum += state[3] * 0xbe32b32a825596e7;
                d_sum += state[4] * 0x8e0f68c5dc223b9a;
                d_sum += state[5] * 0x58022d9e1c256ce3;
                d_sum += state[6] * 0x584d29227aa073ac;
                d_sum += state[7] * 0x8b9352ad04bef9e7;
                d_sum += state[8] * 0xaead42a3f445ecbf;
                d_sum += state[9] * 0x3c667a1d833a3cca;
                d_sum += state[10] * 0xda6f61838efa1ffe;
                d_sum += state[11] * 0xe8f749470bd7c446;
            } else if (r == 3) {
                d_sum += state[1] * 0xc5b85bab9e5b3869;
                d_sum += state[2] * 0x45245258aec51cf7;
                d_sum += state[3] * 0x16e6b8e68b931830;
                d_sum += state[4] * 0xe2ae0f051418112c;
                d_sum += state[5] * 0x0470e26a0093a65b;
                d_sum += state[6] * 0x6bef71973a8146ed;
                d_sum += state[7] * 0x119265be51812daf;
                d_sum += state[8] * 0xb0be7356254bea2e;
                d_sum += state[9] * 0x8584defff7589bd7;
                d_sum += state[10] * 0x3c5fe4aeb1fb52ba;
                d_sum += state[11] * 0x9e7cd88acf543a5e;
            } else if (r == 4) {
                d_sum += state[1] * 0x179be4bba87f0a8c;
                d_sum += state[2] * 0xacf63d95d8887355;
                d_sum += state[3] * 0x6696670196b0074f;
                d_sum += state[4] * 0xd99ddf1fe75085f9;
                d_sum += state[5] * 0xc2597881fef0283b;
                d_sum += state[6] * 0xcf48395ee6c54f14;
                d_sum += state[7] * 0x15226a8e4cd8d3b6;
                d_sum += state[8] * 0xc053297389af5d3b;
                d_sum += state[9] * 0x2c08893f0d1580e2;
                d_sum += state[10] * 0x0ed3cbcff6fcc5ba;
                d_sum += state[11] * 0xc82f510ecf81f6d0;
            } else if (r == 5) {
                d_sum += state[1] * 0x94b06183acb715cc;
                d_sum += state[2] * 0x500392ed0d431137;
                d_sum += state[3] * 0x861cc95ad5c86323;
                d_sum += state[4] * 0x05830a443f86c4ac;
                d_sum += state[5] * 0x3b68225874a20a7c;
                d_sum += state[6] * 0x10b3309838e236fb;
                d_sum += state[7] * 0x9b77fc8bcd559e2c;
                d_sum += state[8] * 0xbdecf5e0cb9cb213;
                d_sum += state[9] * 0x30276f1221ace5fa;
                d_sum += state[10] * 0x7935dd342764a144;
                d_sum += state[11] * 0xeac6db520bb03708;
            } else if (r == 6) {
                d_sum += state[1] * 0x7186a80551025f8f;
                d_sum += state[2] * 0x622247557e9b5371;
                d_sum += state[3] * 0xc4cbe326d1ad9742;
                d_sum += state[4] * 0x55f1523ac6a23ea2;
                d_sum += state[5] * 0xa13dfe77a3d52f53;
                d_sum += state[6] * 0xe30750b6301c0452;
                d_sum += state[7] * 0x08bd488070a3a32b;
                d_sum += state[8] * 0xcd800caef5b72ae3;
                d_sum += state[9] * 0x83329c90f04233ce;
                d_sum += state[10] * 0xb5b99e6664a0a3ee;
                d_sum += state[11] * 0x6b0731849e200a7f;
            } else if (r == 7) {
                d_sum += state[1] * 0xec3fabc192b01799;
                d_sum += state[2] * 0x382b38cee8ee5375;
                d_sum += state[3] * 0x3bfb6c3f0e616572;
                d_sum += state[4] * 0x514abd0cf6c7bc86;
                d_sum += state[5] * 0x47521b1361dcc546;
                d_sum += state[6] * 0x178093843f863d14;
                d_sum += state[7] * 0xad1003c5d28918e7;
                d_sum += state[8] * 0x738450e42495bc81;
                d_sum += state[9] * 0xaf947c59af5e4047;
                d_sum += state[10] * 0x4653fb0685084ef2;
                d_sum += state[11] * 0x057fde2062ae35bf;
            } else if (r == 8) {
                d_sum += state[1] * 0xe376678d843ce55e;
                d_sum += state[2] * 0x66f3860d7514e7fc;
                d_sum += state[3] * 0x7817f3dfff8b4ffa;
                d_sum += state[4] * 0x3929624a9def725b;
                d_sum += state[5] * 0x0126ca37f215a80a;
                d_sum += state[6] * 0xfce2f5d02762a303;
                d_sum += state[7] * 0x1bc927375febbad7;
                d_sum += state[8] * 0x85b481e5243f60bf;
                d_sum += state[9] * 0x2d3c5f42a39c91a0;
                d_sum += state[10] * 0x0811719919351ae8;
                d_sum += state[11] * 0xf669de0add993131;
            } else if (r == 9) {
                d_sum += state[1] * 0x7de38bae084da92d;
                d_sum += state[2] * 0x5b848442237e8a9b;
                d_sum += state[3] * 0xf6c705da84d57310;
                d_sum += state[4] * 0x31e6a4bdb6a49017;
                d_sum += state[5] * 0x889489706e5c5c0f;
                d_sum += state[6] * 0x0e4a205459692a1b;
                d_sum += state[7] * 0xbac3fa75ee26f299;
                d_sum += state[8] * 0x5f5894f4057d755e;
                d_sum += state[9] * 0xb0dc3ecd724bb076;
                d_sum += state[10] * 0x5e34d8554a6452ba;
                d_sum += state[11] * 0x04f78fd8c1fdcc5f;
            } else if (r == 10) {
                d_sum += state[1] * 0x4dd19c38779512ea;
                d_sum += state[2] * 0xdb79ba02704620e9;
                d_sum += state[3] * 0x92a29a3675a5d2be;
                d_sum += state[4] * 0xd5177029fe495166;
                d_sum += state[5] * 0xd32b3298a13330c1;
                d_sum += state[6] * 0x251c4a3eb2c5f8fd;
                d_sum += state[7] * 0xe1c48b26e0d98825;
                d_sum += state[8] * 0x3301d3362a4ffccb;
                d_sum += state[9] * 0x09bb6c88de8cd178;
                d_sum += state[10] * 0xdc05b676564f538a;
                d_sum += state[11] * 0x60192d883e473fee;
            } else if (r == 11) {
                d_sum += state[1] * 0x16b9774801ac44a0;
                d_sum += state[2] * 0x3cb8411e786d3c8e;
                d_sum += state[3] * 0xa86e9cf505072491;
                d_sum += state[4] * 0x0178928152e109ae;
                d_sum += state[5] * 0x5317b905a6e1ab7b;
                d_sum += state[6] * 0xda20b3be7f53d59f;
                d_sum += state[7] * 0xcb97dedecebee9ad;
                d_sum += state[8] * 0x4bd545218c59f58d;
                d_sum += state[9] * 0x77dc8d856c05a44a;
                d_sum += state[10] * 0x87948589e4f243fd;
                d_sum += state[11] * 0x7e5217af969952c2;
            } else if (r == 12) {
                d_sum += state[1] * 0xbc58987d06a84e4d;
                d_sum += state[2] * 0x0b5d420244c9cae3;
                d_sum += state[3] * 0xa3c4711b938c02c0;
                d_sum += state[4] * 0x3aace640a3e03990;
                d_sum += state[5] * 0x865a0f3249aacd8a;
                d_sum += state[6] * 0x8d00b2a7dbed06c7;
                d_sum += state[7] * 0x6eacb905beb7e2f8;
                d_sum += state[8] * 0x045322b216ec3ec7;
                d_sum += state[9] * 0xeb9de00d594828e6;
                d_sum += state[10] * 0x088c5f20df9e5c26;
                d_sum += state[11] * 0xf555f4112b19781f;
            } else if (r == 13) {
                d_sum += state[1] * 0xa8cedbff1813d3a7;
                d_sum += state[2] * 0x50dcaee0fd27d164;
                d_sum += state[3] * 0xf1cb02417e23bd82;
                d_sum += state[4] * 0xfaf322786e2abe8b;
                d_sum += state[5] * 0x937a4315beb5d9b6;
                d_sum += state[6] * 0x1b18992921a11d85;
                d_sum += state[7] * 0x7d66c4368b3c497b;
                d_sum += state[8] * 0x0e7946317a6b4e99;
                d_sum += state[9] * 0xbe4430134182978b;
                d_sum += state[10] * 0x3771e82493ab262d;
                d_sum += state[11] * 0xa671690d8095ce82;
            } else if (r == 14) {
                d_sum += state[1] * 0xb035585f6e929d9d;
                d_sum += state[2] * 0xba1579c7e219b954;
                d_sum += state[3] * 0xcb201cf846db4ba3;
                d_sum += state[4] * 0x287bf9177372cf45;
                d_sum += state[5] * 0xa350e4f61147d0a6;
                d_sum += state[6] * 0xd5d0ecfb50bcff99;
                d_sum += state[7] * 0x2e166aa6c776ed21;
                d_sum += state[8] * 0xe1e66c991990e282;
                d_sum += state[9] * 0x662b329b01e7bb38;
                d_sum += state[10] * 0x8aa674b36144d9a9;
                d_sum += state[11] * 0xcbabf78f97f95e65;
            } else if (r == 15) {
                d_sum += state[1] * 0xeec24b15a06b53fe;
                d_sum += state[2] * 0xc8a7aa07c5633533;
                d_sum += state[3] * 0xefe9c6fa4311ad51;
                d_sum += state[4] * 0xb9173f13977109a1;
                d_sum += state[5] * 0x69ce43c9cc94aedc;
                d_sum += state[6] * 0xecf623c9cd118815;
                d_sum += state[7] * 0x28625def198c33c7;
                d_sum += state[8] * 0xccfc5f7de5c3636a;
                d_sum += state[9] * 0xf5e6c40f1621c299;
                d_sum += state[10] * 0xcec0e58c34cb64b1;
                d_sum += state[11] * 0xa868ea113387939f;
            } else if (r == 16) {
                d_sum += state[1] * 0xd8dddbdc5ce4ef45;
                d_sum += state[2] * 0xacfc51de8131458c;
                d_sum += state[3] * 0x146bb3c0fe499ac0;
                d_sum += state[4] * 0x9e65309f15943903;
                d_sum += state[5] * 0x80d0ad980773aa70;
                d_sum += state[6] * 0xf97817d4ddbf0607;
                d_sum += state[7] * 0xe4626620a75ba276;
                d_sum += state[8] * 0x0dfdc7fd6fc74f66;
                d_sum += state[9] * 0xf464864ad6f2bb93;
                d_sum += state[10] * 0x02d55e52a5d44414;
                d_sum += state[11] * 0xdd8de62487c40925;
            } else if (r == 17) {
                d_sum += state[1] * 0xc15acf44759545a3;
                d_sum += state[2] * 0xcbfdcf39869719d4;
                d_sum += state[3] * 0x33f62042e2f80225;
                d_sum += state[4] * 0x2599c5ead81d8fa3;
                d_sum += state[5] * 0x0b306cb6c1d7c8d0;
                d_sum += state[6] * 0x658c80d3df3729b1;
                d_sum += state[7] * 0xe8d1b2b21b41429c;
                d_sum += state[8] * 0xa1b67f09d4b3ccb8;
                d_sum += state[9] * 0x0e1adf8b84437180;
                d_sum += state[10] * 0x0d593a5e584af47b;
                d_sum += state[11] * 0xa023d94c56e151c7;
            } else if (r == 18) {
                d_sum += state[1] * 0x49026cc3a4afc5a6;
                d_sum += state[2] * 0xe06dff00ab25b91b;
                d_sum += state[3] * 0x0ab38c561e8850ff;
                d_sum += state[4] * 0x92c3c8275e105eeb;
                d_sum += state[5] * 0xb65256e546889bd0;
                d_sum += state[6] * 0x3c0468236ea142f6;
                d_sum += state[7] * 0xee61766b889e18f2;
                d_sum += state[8] * 0xa206f41b12c30415;
                d_sum += state[9] * 0x02fe9d756c9f12d1;
                d_sum += state[10] * 0xe9633210630cbf12;
                d_sum += state[11] * 0x1ffea9fe85a0b0b1;
            } else if (r == 19) {
                d_sum += state[1] * 0x81d1ae8cc50240f3;
                d_sum += state[2] * 0xf4c77a079a4607d7;
                d_sum += state[3] * 0xed446b2315e3efc1;
                d_sum += state[4] * 0x0b0a6b70915178c3;
                d_sum += state[5] * 0xb11ff3e089f15d9a;
                d_sum += state[6] * 0x1d4dba0b7ae9cc18;
                d_sum += state[7] * 0x65d74e2f43b48d05;
                d_sum += state[8] * 0xa2df8c6b8ae0804a;
                d_sum += state[9] * 0xa4e6f0a8c33348a6;
                d_sum += state[10] * 0xc0a26efc7be5669b;
                d_sum += state[11] * 0xa6b6582c547d0d60;
            } else if (r == 20) {
                d_sum += state[1] * 0x84afc741f1c13213;
                d_sum += state[2] * 0x2f8f43734fc906f3;
                d_sum += state[3] * 0xde682d72da0a02d9;
                d_sum += state[4] * 0x0bb005236adb9ef2;
                d_sum += state[5] * 0x5bdf35c10a8b5624;
                d_sum += state[6] * 0x0739a8a343950010;
                d_sum += state[7] * 0x52f515f44785cfbc;
                d_sum += state[8] * 0xcbaf4e5d82856c60;
                d_sum += state[9] * 0xac9ea09074e3e150;
                d_sum += state[10] * 0x8f0fa011a2035fb0;
                d_sum += state[11] * 0x1a37905d8450904a;
            } else if (r == 21) {
                d_sum += state[1] * 0x3abeb80def61cc85;
                d_sum += state[2] * 0x9d19c9dd4eac4133;
                d_sum += state[3] * 0x075a652d9641a985;
                d_sum += state[4] * 0x9daf69ae1b67e667;
                d_sum += state[5] * 0x364f71da77920a18;
                d_sum += state[6] * 0x50bd769f745c95b1;
                d_sum += state[7] * 0xf223d1180dbbf3fc;
                d_sum += state[8] * 0x2f885e584e04aa99;
                d_sum += state[9] * 0xb69a0fa70aea684a;
                d_sum += state[10] * 0x09584acaa6e062a0;
                d_sum += state[11] * 0x0bc051640145b19b;
            } else {
                revert("illegal fast partial round w hats");
            }

            new_state[0] = add(
                d_sum,
                state[0] * (MDS_MATRIX_CIRC_0 + MDS_MATRIX_DIAG_0)
            );

            // for (uint256 i = 1; i < 12; i++)  {
            //     new_state[i] = add(state[i], state[0] * FAST_PARTIAL_ROUND_VS[r][i - 1]);
            // }
            if (r == 0) {
                new_state[1] = add(state[1], state[0] * 0x94877900674181c3);
                new_state[2] = add(state[2], state[0] * 0xc6c67cc37a2a2bbd);
                new_state[3] = add(state[3], state[0] * 0xd667c2055387940f);
                new_state[4] = add(state[4], state[0] * 0x0ba63a63e94b5ff0);
                new_state[5] = add(state[5], state[0] * 0x99460cc41b8f079f);
                new_state[6] = add(state[6], state[0] * 0x7ff02375ed524bb3);
                new_state[7] = add(state[7], state[0] * 0xea0870b47a8caf0e);
                new_state[8] = add(state[8], state[0] * 0xabcad82633b7bc9d);
                new_state[9] = add(state[9], state[0] * 0x3b8d135261052241);
                new_state[10] = add(state[10], state[0] * 0xfb4515f5e5b0d539);
                new_state[11] = add(state[11], state[0] * 0x3ee8011c2b37f77c);
            } else if (r == 1) {
                new_state[1] = add(state[1], state[0] * 0x0adef3740e71c726);
                new_state[2] = add(state[2], state[0] * 0xa37bf67c6f986559);
                new_state[3] = add(state[3], state[0] * 0xc6b16f7ed4fa1b00);
                new_state[4] = add(state[4], state[0] * 0x6a065da88d8bfc3c);
                new_state[5] = add(state[5], state[0] * 0x4cabc0916844b46f);
                new_state[6] = add(state[6], state[0] * 0x407faac0f02e78d1);
                new_state[7] = add(state[7], state[0] * 0x07a786d9cf0852cf);
                new_state[8] = add(state[8], state[0] * 0x42433fb6949a629a);
                new_state[9] = add(state[9], state[0] * 0x891682a147ce43b0);
                new_state[10] = add(state[10], state[0] * 0x26cfd58e7b003b55);
                new_state[11] = add(state[11], state[0] * 0x2bbf0ed7b657acb3);
            } else if (r == 2) {
                new_state[1] = add(state[1], state[0] * 0x481ac7746b159c67);
                new_state[2] = add(state[2], state[0] * 0xe367de32f108e278);
                new_state[3] = add(state[3], state[0] * 0x73f260087ad28bec);
                new_state[4] = add(state[4], state[0] * 0x5cfc82216bc1bdca);
                new_state[5] = add(state[5], state[0] * 0xcaccc870a2663a0e);
                new_state[6] = add(state[6], state[0] * 0xdb69cd7b4298c45d);
                new_state[7] = add(state[7], state[0] * 0x7bc9e0c57243e62d);
                new_state[8] = add(state[8], state[0] * 0x3cc51c5d368693ae);
                new_state[9] = add(state[9], state[0] * 0x366b4e8cc068895b);
                new_state[10] = add(state[10], state[0] * 0x2bd18715cdabbca4);
                new_state[11] = add(state[11], state[0] * 0xa752061c4f33b8cf);
            } else if (r == 3) {
                new_state[1] = add(state[1], state[0] * 0xb22d2432b72d5098);
                new_state[2] = add(state[2], state[0] * 0x9e18a487f44d2fe4);
                new_state[3] = add(state[3], state[0] * 0x4b39e14ce22abd3c);
                new_state[4] = add(state[4], state[0] * 0x9e77fde2eb315e0d);
                new_state[5] = add(state[5], state[0] * 0xca5e0385fe67014d);
                new_state[6] = add(state[6], state[0] * 0x0c2cb99bf1b6bddb);
                new_state[7] = add(state[7], state[0] * 0x99ec1cd2a4460bfe);
                new_state[8] = add(state[8], state[0] * 0x8577a815a2ff843f);
                new_state[9] = add(state[9], state[0] * 0x7d80a6b4fd6518a5);
                new_state[10] = add(state[10], state[0] * 0xeb6c67123eab62cb);
                new_state[11] = add(state[11], state[0] * 0x8f7851650eca21a5);
            } else if (r == 4) {
                new_state[1] = add(state[1], state[0] * 0x11ba9a1b81718c2a);
                new_state[2] = add(state[2], state[0] * 0x9f7d798a3323410c);
                new_state[3] = add(state[3], state[0] * 0xa821855c8c1cf5e5);
                new_state[4] = add(state[4], state[0] * 0x535e8d6fac0031b2);
                new_state[5] = add(state[5], state[0] * 0x404e7c751b634320);
                new_state[6] = add(state[6], state[0] * 0xa729353f6e55d354);
                new_state[7] = add(state[7], state[0] * 0x4db97d92e58bb831);
                new_state[8] = add(state[8], state[0] * 0xb53926c27897bf7d);
                new_state[9] = add(state[9], state[0] * 0x965040d52fe115c5);
                new_state[10] = add(state[10], state[0] * 0x9565fa41ebd31fd7);
                new_state[11] = add(state[11], state[0] * 0xaae4438c877ea8f4);
            } else if (r == 5) {
                new_state[1] = add(state[1], state[0] * 0x37f4e36af6073c6e);
                new_state[2] = add(state[2], state[0] * 0x4edc0918210800e9);
                new_state[3] = add(state[3], state[0] * 0xc44998e99eae4188);
                new_state[4] = add(state[4], state[0] * 0x9f4310d05d068338);
                new_state[5] = add(state[5], state[0] * 0x9ec7fe4350680f29);
                new_state[6] = add(state[6], state[0] * 0xc5b2c1fdc0b50874);
                new_state[7] = add(state[7], state[0] * 0xa01920c5ef8b2ebe);
                new_state[8] = add(state[8], state[0] * 0x59fa6f8bd91d58ba);
                new_state[9] = add(state[9], state[0] * 0x8bfc9eb89b515a82);
                new_state[10] = add(state[10], state[0] * 0xbe86a7a2555ae775);
                new_state[11] = add(state[11], state[0] * 0xcbb8bbaa3810babf);
            } else if (r == 6) {
                new_state[1] = add(state[1], state[0] * 0x577f9a9e7ee3f9c2);
                new_state[2] = add(state[2], state[0] * 0x88c522b949ace7b1);
                new_state[3] = add(state[3], state[0] * 0x82f07007c8b72106);
                new_state[4] = add(state[4], state[0] * 0x8283d37c6675b50e);
                new_state[5] = add(state[5], state[0] * 0x98b074d9bbac1123);
                new_state[6] = add(state[6], state[0] * 0x75c56fb7758317c1);
                new_state[7] = add(state[7], state[0] * 0xfed24e206052bc72);
                new_state[8] = add(state[8], state[0] * 0x26d7c3d1bc07dae5);
                new_state[9] = add(state[9], state[0] * 0xf88c5e441e28dbb4);
                new_state[10] = add(state[10], state[0] * 0x4fe27f9f96615270);
                new_state[11] = add(state[11], state[0] * 0x514d4ba49c2b14fe);
            } else if (r == 7) {
                new_state[1] = add(state[1], state[0] * 0xf02a3ac068ee110b);
                new_state[2] = add(state[2], state[0] * 0x0a3630dafb8ae2d7);
                new_state[3] = add(state[3], state[0] * 0xce0dc874eaf9b55c);
                new_state[4] = add(state[4], state[0] * 0x9a95f6cff5b55c7e);
                new_state[5] = add(state[5], state[0] * 0x626d76abfed00c7b);
                new_state[6] = add(state[6], state[0] * 0xa0c1cf1251c204ad);
                new_state[7] = add(state[7], state[0] * 0xdaebd3006321052c);
                new_state[8] = add(state[8], state[0] * 0x3d4bd48b625a8065);
                new_state[9] = add(state[9], state[0] * 0x7f1e584e071f6ed2);
                new_state[10] = add(state[10], state[0] * 0x720574f0501caed3);
                new_state[11] = add(state[11], state[0] * 0xe3260ba93d23540a);
            } else if (r == 8) {
                new_state[1] = add(state[1], state[0] * 0xab1cbd41d8c1e335);
                new_state[2] = add(state[2], state[0] * 0x9322ed4c0bc2df01);
                new_state[3] = add(state[3], state[0] * 0x51c3c0983d4284e5);
                new_state[4] = add(state[4], state[0] * 0x94178e291145c231);
                new_state[5] = add(state[5], state[0] * 0xfd0f1a973d6b2085);
                new_state[6] = add(state[6], state[0] * 0xd427ad96e2b39719);
                new_state[7] = add(state[7], state[0] * 0x8a52437fecaac06b);
                new_state[8] = add(state[8], state[0] * 0xdc20ee4b8c4c9a80);
                new_state[9] = add(state[9], state[0] * 0xa2c98e9549da2100);
                new_state[10] = add(state[10], state[0] * 0x1603fe12613db5b6);
                new_state[11] = add(state[11], state[0] * 0x0e174929433c5505);
            } else if (r == 9) {
                new_state[1] = add(state[1], state[0] * 0x3d4eab2b8ef5f796);
                new_state[2] = add(state[2], state[0] * 0xcfff421583896e22);
                new_state[3] = add(state[3], state[0] * 0x4143cb32d39ac3d9);
                new_state[4] = add(state[4], state[0] * 0x22365051b78a5b65);
                new_state[5] = add(state[5], state[0] * 0x6f7fd010d027c9b6);
                new_state[6] = add(state[6], state[0] * 0xd9dd36fba77522ab);
                new_state[7] = add(state[7], state[0] * 0xa44cf1cb33e37165);
                new_state[8] = add(state[8], state[0] * 0x3fc83d3038c86417);
                new_state[9] = add(state[9], state[0] * 0xc4588d418e88d270);
                new_state[10] = add(state[10], state[0] * 0xce1320f10ab80fe2);
                new_state[11] = add(state[11], state[0] * 0xdb5eadbbec18de5d);
            } else if (r == 10) {
                new_state[1] = add(state[1], state[0] * 0x1183dfce7c454afd);
                new_state[2] = add(state[2], state[0] * 0x21cea4aa3d3ed949);
                new_state[3] = add(state[3], state[0] * 0x0fce6f70303f2304);
                new_state[4] = add(state[4], state[0] * 0x19557d34b55551be);
                new_state[5] = add(state[5], state[0] * 0x4c56f689afc5bbc9);
                new_state[6] = add(state[6], state[0] * 0xa1e920844334f944);
                new_state[7] = add(state[7], state[0] * 0xbad66d423d2ec861);
                new_state[8] = add(state[8], state[0] * 0xf318c785dc9e0479);
                new_state[9] = add(state[9], state[0] * 0x99e2032e765ddd81);
                new_state[10] = add(state[10], state[0] * 0x400ccc9906d66f45);
                new_state[11] = add(state[11], state[0] * 0xe1197454db2e0dd9);
            } else if (r == 11) {
                new_state[1] = add(state[1], state[0] * 0x84d1ecc4d53d2ff1);
                new_state[2] = add(state[2], state[0] * 0xd8af8b9ceb4e11b6);
                new_state[3] = add(state[3], state[0] * 0x335856bb527b52f4);
                new_state[4] = add(state[4], state[0] * 0xc756f17fb59be595);
                new_state[5] = add(state[5], state[0] * 0xc0654e4ea5553a78);
                new_state[6] = add(state[6], state[0] * 0x9e9a46b61f2ea942);
                new_state[7] = add(state[7], state[0] * 0x14fc8b5b3b809127);
                new_state[8] = add(state[8], state[0] * 0xd7009f0f103be413);
                new_state[9] = add(state[9], state[0] * 0x3e0ee7b7a9fb4601);
                new_state[10] = add(state[10], state[0] * 0xa74e888922085ed7);
                new_state[11] = add(state[11], state[0] * 0xe80a7cde3d4ac526);
            } else if (r == 12) {
                new_state[1] = add(state[1], state[0] * 0x238aa6daa612186d);
                new_state[2] = add(state[2], state[0] * 0x9137a5c630bad4b4);
                new_state[3] = add(state[3], state[0] * 0xc7db3817870c5eda);
                new_state[4] = add(state[4], state[0] * 0x217e4f04e5718dc9);
                new_state[5] = add(state[5], state[0] * 0xcae814e2817bd99d);
                new_state[6] = add(state[6], state[0] * 0xe3292e7ab770a8ba);
                new_state[7] = add(state[7], state[0] * 0x7bb36ef70b6b9482);
                new_state[8] = add(state[8], state[0] * 0x3c7835fb85bca2d3);
                new_state[9] = add(state[9], state[0] * 0xfe2cdf8ee3c25e86);
                new_state[10] = add(state[10], state[0] * 0x61b3915ad7274b20);
                new_state[11] = add(state[11], state[0] * 0xeab75ca7c918e4ef);
            } else if (r == 13) {
                new_state[1] = add(state[1], state[0] * 0xd6e15ffc055e154e);
                new_state[2] = add(state[2], state[0] * 0xec67881f381a32bf);
                new_state[3] = add(state[3], state[0] * 0xfbb1196092bf409c);
                new_state[4] = add(state[4], state[0] * 0xdc9d2e07830ba226);
                new_state[5] = add(state[5], state[0] * 0x0698ef3245ff7988);
                new_state[6] = add(state[6], state[0] * 0x194fae2974f8b576);
                new_state[7] = add(state[7], state[0] * 0x7a5d9bea6ca4910e);
                new_state[8] = add(state[8], state[0] * 0x7aebfea95ccdd1c9);
                new_state[9] = add(state[9], state[0] * 0xf9bd38a67d5f0e86);
                new_state[10] = add(state[10], state[0] * 0xfa65539de65492d8);
                new_state[11] = add(state[11], state[0] * 0xf0dfcbe7653ff787);
            } else if (r == 14) {
                new_state[1] = add(state[1], state[0] * 0x0bd87ad390420258);
                new_state[2] = add(state[2], state[0] * 0x0ad8617bca9e33c8);
                new_state[3] = add(state[3], state[0] * 0x0c00ad377a1e2666);
                new_state[4] = add(state[4], state[0] * 0x0ac6fc58b3f0518f);
                new_state[5] = add(state[5], state[0] * 0x0c0cc8a892cc4173);
                new_state[6] = add(state[6], state[0] * 0x0c210accb117bc21);
                new_state[7] = add(state[7], state[0] * 0x0b73630dbb46ca18);
                new_state[8] = add(state[8], state[0] * 0x0c8be4920cbd4a54);
                new_state[9] = add(state[9], state[0] * 0x0bfe877a21be1690);
                new_state[10] = add(state[10], state[0] * 0x0ae790559b0ded81);
                new_state[11] = add(state[11], state[0] * 0x0bf50db2f8d6ce31);
            } else if (r == 15) {
                new_state[1] = add(state[1], state[0] * 0x000cf29427ff7c58);
                new_state[2] = add(state[2], state[0] * 0x000bd9b3cf49eec8);
                new_state[3] = add(state[3], state[0] * 0x000d1dc8aa81fb26);
                new_state[4] = add(state[4], state[0] * 0x000bc792d5c394ef);
                new_state[5] = add(state[5], state[0] * 0x000d2ae0b2266453);
                new_state[6] = add(state[6], state[0] * 0x000d413f12c496c1);
                new_state[7] = add(state[7], state[0] * 0x000c84128cfed618);
                new_state[8] = add(state[8], state[0] * 0x000db5ebd48fc0d4);
                new_state[9] = add(state[9], state[0] * 0x000d1b77326dcb90);
                new_state[10] = add(state[10], state[0] * 0x000beb0ccc145421);
                new_state[11] = add(state[11], state[0] * 0x000d10e5b22b11d1);
            } else if (r == 16) {
                new_state[1] = add(state[1], state[0] * 0x00000e24c99adad8);
                new_state[2] = add(state[2], state[0] * 0x00000cf389ed4bc8);
                new_state[3] = add(state[3], state[0] * 0x00000e580cbf6966);
                new_state[4] = add(state[4], state[0] * 0x00000cde5fd7e04f);
                new_state[5] = add(state[5], state[0] * 0x00000e63628041b3);
                new_state[6] = add(state[6], state[0] * 0x00000e7e81a87361);
                new_state[7] = add(state[7], state[0] * 0x00000dabe78f6d98);
                new_state[8] = add(state[8], state[0] * 0x00000efb14cac554);
                new_state[9] = add(state[9], state[0] * 0x00000e5574743b10);
                new_state[10] = add(state[10], state[0] * 0x00000d05709f42c1);
                new_state[11] = add(state[11], state[0] * 0x00000e4690c96af1);
            } else if (r == 17) {
                new_state[1] = add(state[1], state[0] * 0x0000000f7157bc98);
                new_state[2] = add(state[2], state[0] * 0x0000000e3006d948);
                new_state[3] = add(state[3], state[0] * 0x0000000fa65811e6);
                new_state[4] = add(state[4], state[0] * 0x0000000e0d127e2f);
                new_state[5] = add(state[5], state[0] * 0x0000000fc18bfe53);
                new_state[6] = add(state[6], state[0] * 0x0000000fd002d901);
                new_state[7] = add(state[7], state[0] * 0x0000000eed6461d8);
                new_state[8] = add(state[8], state[0] * 0x0000001068562754);
                new_state[9] = add(state[9], state[0] * 0x0000000fa0236f50);
                new_state[10] = add(state[10], state[0] * 0x0000000e3af13ee1);
                new_state[11] = add(state[11], state[0] * 0x0000000fa460f6d1);
            } else if (r == 18) {
                new_state[1] = add(state[1], state[0] * 0x0000000011131738);
                new_state[2] = add(state[2], state[0] * 0x000000000f56d588);
                new_state[3] = add(state[3], state[0] * 0x0000000011050f86);
                new_state[4] = add(state[4], state[0] * 0x000000000f848f4f);
                new_state[5] = add(state[5], state[0] * 0x00000000111527d3);
                new_state[6] = add(state[6], state[0] * 0x00000000114369a1);
                new_state[7] = add(state[7], state[0] * 0x00000000106f2f38);
                new_state[8] = add(state[8], state[0] * 0x0000000011e2ca94);
                new_state[9] = add(state[9], state[0] * 0x00000000110a29f0);
                new_state[10] = add(state[10], state[0] * 0x000000000fa9f5c1);
                new_state[11] = add(state[11], state[0] * 0x0000000010f625d1);
            } else if (r == 19) {
                new_state[1] = add(state[1], state[0] * 0x000000000011f718);
                new_state[2] = add(state[2], state[0] * 0x000000000010b6c8);
                new_state[3] = add(state[3], state[0] * 0x0000000000134a96);
                new_state[4] = add(state[4], state[0] * 0x000000000010cf7f);
                new_state[5] = add(state[5], state[0] * 0x0000000000124d03);
                new_state[6] = add(state[6], state[0] * 0x000000000013f8a1);
                new_state[7] = add(state[7], state[0] * 0x0000000000117c58);
                new_state[8] = add(state[8], state[0] * 0x0000000000132c94);
                new_state[9] = add(state[9], state[0] * 0x0000000000134fc0);
                new_state[10] = add(state[10], state[0] * 0x000000000010a091);
                new_state[11] = add(state[11], state[0] * 0x0000000000128961);
            } else if (r == 20) {
                new_state[1] = add(state[1], state[0] * 0x0000000000001300);
                new_state[2] = add(state[2], state[0] * 0x0000000000001750);
                new_state[3] = add(state[3], state[0] * 0x000000000000114e);
                new_state[4] = add(state[4], state[0] * 0x000000000000131f);
                new_state[5] = add(state[5], state[0] * 0x000000000000167b);
                new_state[6] = add(state[6], state[0] * 0x0000000000001371);
                new_state[7] = add(state[7], state[0] * 0x0000000000001230);
                new_state[8] = add(state[8], state[0] * 0x000000000000182c);
                new_state[9] = add(state[9], state[0] * 0x0000000000001368);
                new_state[10] = add(state[10], state[0] * 0x0000000000000f31);
                new_state[11] = add(state[11], state[0] * 0x00000000000015c9);
            } else if (r == 21) {
                new_state[1] = add(state[1], state[0] * 0x0000000000000014);
                new_state[2] = add(state[2], state[0] * 0x0000000000000022);
                new_state[3] = add(state[3], state[0] * 0x0000000000000012);
                new_state[4] = add(state[4], state[0] * 0x0000000000000027);
                new_state[5] = add(state[5], state[0] * 0x000000000000000d);
                new_state[6] = add(state[6], state[0] * 0x000000000000000d);
                new_state[7] = add(state[7], state[0] * 0x000000000000001c);
                new_state[8] = add(state[8], state[0] * 0x0000000000000002);
                new_state[9] = add(state[9], state[0] * 0x0000000000000010);
                new_state[10] = add(state[10], state[0] * 0x0000000000000029);
                new_state[11] = add(state[11], state[0] * 0x000000000000000f);
            }
        }
    }

    function _partial_first_constant_layer(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256[WIDTH] memory new_state) {
        // for (uint256 i = 0; i < 12; i++) {
        //     new_state[i] = add(state[i], FAST_PARTIAL_FIRST_ROUND_CONSTANT[i]);
        // }
        new_state[0] = add(state[0], FAST_PARTIAL_FIRST_ROUND_CONSTANT_0);
        new_state[1] = add(state[1], FAST_PARTIAL_FIRST_ROUND_CONSTANT_1);
        new_state[2] = add(state[2], FAST_PARTIAL_FIRST_ROUND_CONSTANT_2);
        new_state[3] = add(state[3], FAST_PARTIAL_FIRST_ROUND_CONSTANT_3);
        new_state[4] = add(state[4], FAST_PARTIAL_FIRST_ROUND_CONSTANT_4);
        new_state[5] = add(state[5], FAST_PARTIAL_FIRST_ROUND_CONSTANT_5);
        new_state[6] = add(state[6], FAST_PARTIAL_FIRST_ROUND_CONSTANT_6);
        new_state[7] = add(state[7], FAST_PARTIAL_FIRST_ROUND_CONSTANT_7);
        new_state[8] = add(state[8], FAST_PARTIAL_FIRST_ROUND_CONSTANT_8);
        new_state[9] = add(state[9], FAST_PARTIAL_FIRST_ROUND_CONSTANT_9);
        new_state[10] = add(state[10], FAST_PARTIAL_FIRST_ROUND_CONSTANT_10);
        new_state[11] = add(state[11], FAST_PARTIAL_FIRST_ROUND_CONSTANT_11);
    }

    function _getRoundConstant(uint256 index) private pure returns (uint256) {
        if (index == 0) return 0xb585f766f2144405;
        else if (index == 1) return 0x7746a55f43921ad7;
        else if (index == 2) return 0xb2fb0d31cee799b4;
        else if (index == 3) return 0x0f6760a4803427d7;
        else if (index == 4) return 0xe10d666650f4e012;
        else if (index == 5) return 0x8cae14cb07d09bf1;
        else if (index == 6) return 0xd438539c95f63e9f;
        else if (index == 7) return 0xef781c7ce35b4c3d;
        else if (index == 8) return 0xcdc4a239b0c44426;
        else if (index == 9) return 0x277fa208bf337bff;
        else if (index == 10) return 0xe17653a29da578a1;
        else if (index == 11) return 0xc54302f225db2c76;
        else if (index == 12) return 0x86287821f722c881;
        else if (index == 13) return 0x59cd1a8a41c18e55;
        else if (index == 14) return 0xc3b919ad495dc574;
        else if (index == 15) return 0xa484c4c5ef6a0781;
        else if (index == 16) return 0x308bbd23dc5416cc;
        else if (index == 17) return 0x6e4a40c18f30c09c;
        else if (index == 18) return 0x9a2eedb70d8f8cfa;
        else if (index == 19) return 0xe360c6e0ae486f38;
        else if (index == 20) return 0xd5c7718fbfc647fb;
        else if (index == 21) return 0xc35eae071903ff0b;
        else if (index == 22) return 0x849c2656969c4be7;
        else if (index == 23) return 0xc0572c8c08cbbbad;
        else if (index == 24) return 0xe9fa634a21de0082;
        else if (index == 25) return 0xf56f6d48959a600d;
        else if (index == 26) return 0xf7d713e806391165;
        else if (index == 27) return 0x8297132b32825daf;
        else if (index == 28) return 0xad6805e0e30b2c8a;
        else if (index == 29) return 0xac51d9f5fcf8535e;
        else if (index == 30) return 0x502ad7dc18c2ad87;
        else if (index == 31) return 0x57a1550c110b3041;
        else if (index == 32) return 0x66bbd30e6ce0e583;
        else if (index == 33) return 0x0da2abef589d644e;
        else if (index == 34) return 0xf061274fdb150d61;
        else if (index == 35) return 0x28b8ec3ae9c29633;
        else if (index == 36) return 0x92a756e67e2b9413;
        else if (index == 37) return 0x70e741ebfee96586;
        else if (index == 38) return 0x019d5ee2af82ec1c;
        else if (index == 39) return 0x6f6f2ed772466352;
        else if (index == 40) return 0x7cf416cfe7e14ca1;
        else if (index == 41) return 0x61df517b86a46439;
        else if (index == 42) return 0x85dc499b11d77b75;
        else if (index == 43) return 0x4b959b48b9c10733;
        else if (index == 44) return 0xe8be3e5da8043e57;
        else if (index == 45) return 0xf5c0bc1de6da8699;
        else if (index == 46) return 0x40b12cbf09ef74bf;
        else if (index == 47) return 0xa637093ecb2ad631;
        else if (index == 312) return 0x475cd3205a3bdcde;
        else if (index == 313) return 0x18a42105c31b7e88;
        else if (index == 314) return 0x023e7414af663068;
        else if (index == 315) return 0x15147108121967d7;
        else if (index == 316) return 0xe4a3dff1d7d6fef9;
        else if (index == 317) return 0x01a8d1a588085737;
        else if (index == 318) return 0x11b4c74eda62beef;
        else if (index == 319) return 0xe587cc0d69a73346;
        else if (index == 320) return 0x1ff7327017aa2a6e;
        else if (index == 321) return 0x594e29c42473d06b;
        else if (index == 322) return 0xf6f31db1899b12d5;
        else if (index == 323) return 0xc02ac5e47312d3ca;
        else if (index == 324) return 0xe70201e960cb78b8;
        else if (index == 325) return 0x6f90ff3b6a65f108;
        else if (index == 326) return 0x42747a7245e7fa84;
        else if (index == 327) return 0xd1f507e43ab749b2;
        else if (index == 328) return 0x1c86d265f15750cd;
        else if (index == 329) return 0x3996ce73dd832c1c;
        else if (index == 330) return 0x8e7fba02983224bd;
        else if (index == 331) return 0xba0dec7103255dd4;
        else if (index == 332) return 0x9e9cbd781628fc5b;
        else if (index == 333) return 0xdae8645996edd6a5;
        else if (index == 334) return 0xdebe0853b1a1d378;
        else if (index == 335) return 0xa49229d24d014343;
        else if (index == 336) return 0x7be5b9ffda905e1c;
        else if (index == 337) return 0xa3c95eaec244aa30;
        else if (index == 338) return 0x0230bca8f4df0544;
        else if (index == 339) return 0x4135c2bebfe148c6;
        else if (index == 340) return 0x166fc0cc438a3c72;
        else if (index == 341) return 0x3762b59a8ae83efa;
        else if (index == 342) return 0xe8928a4c89114750;
        else if (index == 343) return 0x2a440b51a4945ee5;
        else if (index == 344) return 0x80cefd2b7d99ff83;
        else if (index == 345) return 0xbb9879c6e61fd62a;
        else if (index == 346) return 0x6e7c8f1a84265034;
        else if (index == 347) return 0x164bb2de1bbeddc8;
        else if (index == 348) return 0xf3c12fe54d5c653b;
        else if (index == 349) return 0x40b9e922ed9771e2;
        else if (index == 350) return 0x551f5b0fbe7b1840;
        else if (index == 351) return 0x25032aa7c4cb1811;
        else if (index == 352) return 0xaaed34074b164346;
        else if (index == 353) return 0x8ffd96bbf9c9c81d;
        else if (index == 354) return 0x70fc91eb5937085c;
        else if (index == 355) return 0x7f795e2a5f915440;
        else if (index == 356) return 0x4543d9df5476d3cb;
        else if (index == 357) return 0xf172d73e004fc90d;
        else if (index == 358) return 0xdfd1c4febcc81238;
        else if (index == 359) return 0xbc8dfb627fe558fc;
        revert("illegal index");
    }

    // `state[i]` allows 200 bits number.
    // `new_state[i]` is 64 bits number.
    // 26743 gas (Can be improved to 469 gas if all are expanded to inline.)
    function _constant_layer(
        uint256[WIDTH] memory state,
        uint256 round_ctr
    ) internal pure returns (uint256[WIDTH] memory new_state) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     new_state[i] = add(state[i], ALL_ROUND_CONSTANTS[i + WIDTH * round_ctr]);
            // }
            uint256 base_index = WIDTH * round_ctr;
            new_state[0] = add(state[0], _getRoundConstant(base_index));
            new_state[1] = add(state[1], _getRoundConstant(base_index + 1));
            new_state[2] = add(state[2], _getRoundConstant(base_index + 2));
            new_state[3] = add(state[3], _getRoundConstant(base_index + 3));
            new_state[4] = add(state[4], _getRoundConstant(base_index + 4));
            new_state[5] = add(state[5], _getRoundConstant(base_index + 5));
            new_state[6] = add(state[6], _getRoundConstant(base_index + 6));
            new_state[7] = add(state[7], _getRoundConstant(base_index + 7));
            new_state[8] = add(state[8], _getRoundConstant(base_index + 8));
            new_state[9] = add(state[9], _getRoundConstant(base_index + 9));
            new_state[10] = add(state[10], _getRoundConstant(base_index + 10));
            new_state[11] = add(state[11], _getRoundConstant(base_index + 11));
        }
    }

    // `x` allows 64 bits number.
    // `x7` is 192 bits number.
    // 64 gas
    function _sbox_monomial(uint256 x) internal pure returns (uint256 x7) {
        uint256 x3;
        unchecked {
            x3 = x * x * x; // 192 bits
        }
        x3 = mod(x3); // 64 bits

        unchecked {
            x7 = x3 * x3 * x; // 192 bits
        }
    }

    // 2250 gas (Can be improved to 1192 gas if all are expanded to inline.)
    function _sbox_layer(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256[WIDTH] memory new_state) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     new_state[i] = _sbox_monomial(state[i]);
            // }
            new_state[0] = _sbox_monomial(state[0]);
            new_state[1] = _sbox_monomial(state[1]);
            new_state[2] = _sbox_monomial(state[2]);
            new_state[3] = _sbox_monomial(state[3]);
            new_state[4] = _sbox_monomial(state[4]);
            new_state[5] = _sbox_monomial(state[5]);
            new_state[6] = _sbox_monomial(state[6]);
            new_state[7] = _sbox_monomial(state[7]);
            new_state[8] = _sbox_monomial(state[8]);
            new_state[9] = _sbox_monomial(state[9]);
            new_state[10] = _sbox_monomial(state[10]);
            new_state[11] = _sbox_monomial(state[11]);
        }
    }

    function _permute(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256[WIDTH] memory) {
        // first full rounds
        state = _mds_layer(_sbox_layer(_constant_layer(state, 0)));
        state = _mds_layer(_sbox_layer(_constant_layer(state, 1)));
        state = _mds_layer(_sbox_layer(_constant_layer(state, 2)));
        state = _mds_layer(_sbox_layer(_constant_layer(state, 3)));

        // partial rounds
        state = _partial_first_constant_layer(state);
        state = _mds_partial_layer_init(state);

        state[0] = _sbox_monomial(state[0]) + 0x74cb2e819ae421ab;
        state = _mds_partial_layer_fast(state, 0);
        state[0] = _sbox_monomial(state[0]) + 0xd2559d2370e7f663;
        state = _mds_partial_layer_fast(state, 1);
        state[0] = _sbox_monomial(state[0]) + 0x62bf78acf843d17c;
        state = _mds_partial_layer_fast(state, 2);
        state[0] = _sbox_monomial(state[0]) + 0xd5ab7b67e14d1fb4;
        state = _mds_partial_layer_fast(state, 3);
        state[0] = _sbox_monomial(state[0]) + 0xb9fe2ae6e0969bdc;
        state = _mds_partial_layer_fast(state, 4);
        state[0] = _sbox_monomial(state[0]) + 0xe33fdf79f92a10e8;
        state = _mds_partial_layer_fast(state, 5);
        state[0] = _sbox_monomial(state[0]) + 0x0ea2bb4c2b25989b;
        state = _mds_partial_layer_fast(state, 6);
        state[0] = _sbox_monomial(state[0]) + 0xca9121fbf9d38f06;
        state = _mds_partial_layer_fast(state, 7);
        state[0] = _sbox_monomial(state[0]) + 0xbdd9b0aa81f58fa4;
        state = _mds_partial_layer_fast(state, 8);
        state[0] = _sbox_monomial(state[0]) + 0x83079fa4ecf20d7e;
        state = _mds_partial_layer_fast(state, 9);
        state[0] = _sbox_monomial(state[0]) + 0x650b838edfcc4ad3;
        state = _mds_partial_layer_fast(state, 10);
        state[0] = _sbox_monomial(state[0]) + 0x77180c88583c76ac;
        state = _mds_partial_layer_fast(state, 11);
        state[0] = _sbox_monomial(state[0]) + 0xaf8c20753143a180;
        state = _mds_partial_layer_fast(state, 12);
        state[0] = _sbox_monomial(state[0]) + 0xb8ccfe9989a39175;
        state = _mds_partial_layer_fast(state, 13);
        state[0] = _sbox_monomial(state[0]) + 0x954a1729f60cc9c5;
        state = _mds_partial_layer_fast(state, 14);
        state[0] = _sbox_monomial(state[0]) + 0xdeb5b550c4dca53b;
        state = _mds_partial_layer_fast(state, 15);
        state[0] = _sbox_monomial(state[0]) + 0xf01bb0b00f77011e;
        state = _mds_partial_layer_fast(state, 16);
        state[0] = _sbox_monomial(state[0]) + 0xa1ebb404b676afd9;
        state = _mds_partial_layer_fast(state, 17);
        state[0] = _sbox_monomial(state[0]) + 0x860b6e1597a0173e;
        state = _mds_partial_layer_fast(state, 18);
        state[0] = _sbox_monomial(state[0]) + 0x308bb65a036acbce;
        state = _mds_partial_layer_fast(state, 19);
        state[0] = _sbox_monomial(state[0]) + 0x1aca78f31c97c876;
        state = _mds_partial_layer_fast(state, 20);
        state[0] = _sbox_monomial(state[0]) + 0x0000000000000000;
        state = _mds_partial_layer_fast(state, 21);

        // second full rounds
        state = _mds_layer(_sbox_layer(_constant_layer(state, 26)));
        state = _mds_layer(_sbox_layer(_constant_layer(state, 27)));
        state = _mds_layer(_sbox_layer(_constant_layer(state, 28)));
        state = _mds_layer(_sbox_layer(_constant_layer(state, 29)));

        return state;
    }

    function permute(
        uint256[WIDTH] memory state
    ) external pure returns (uint256[WIDTH] memory new_state) {
        state = _permute(state);
        for (uint256 i = 0; i < WIDTH; i++) {
            new_state[i] = mod(state[i]);
        }
    }

    // Require each input[i] is less than 2^256 - 2^64.
    function _hash_n_to_m_no_pad(
        uint256[] memory input,
        uint256 num_outputs
    ) internal pure returns (uint256[] memory output) {
        uint256 num_full_round = input.length / SPONGE_RATE;
        uint256 last_round = input.length % SPONGE_RATE;

        uint256[WIDTH] memory state;
        for (uint256 i = 0; i < num_full_round; i++) {
            for (uint256 j = 0; j < SPONGE_RATE; j++) {
                state[j] = input[i * SPONGE_RATE + j];
            }
            state = _permute(state);
        }
        for (uint256 j = 0; j < last_round; j++) {
            state[j] = input[num_full_round * SPONGE_RATE + j];
        }
        state = _permute(state);

        output = new uint256[](num_outputs);
        for (uint256 j = 0; j < num_outputs; j++) {
            output[j] = mod(state[j]);
        }
    }

    function hash_n_to_m_no_pad(
        uint256[] memory input,
        uint256 num_outputs
    ) external pure returns (uint256[] memory output) {
        for (uint256 i = 0; i < input.length; i++) {
            input[i] = mod(input[i]);
        }
        output = _hash_n_to_m_no_pad(input, num_outputs);
    }
}

pragma solidity =0.6.6;

import '../interfaces/IUniswapV2Pair.sol';
import './uniswap/FixedPoint.sol';
import './SafeMath.sol';
import './RayBase.sol';
import './Daily.sol';

library RayCalculator {

    using SafeMath for uint;
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;
    using Daily for Daily.DailyList;
    using Daily for Daily.DailyItem;

    uint private constant SEVEN = 7;
    uint private constant THREE = 3;
    uint private constant TEN = 10;
    uint16  private constant MAX_UINT16 = 0xFFFF;
    uint32 private constant MAX_UINT32 = 0xFFFFFFFF;

    function powerOfRay(uint amount, address pair) internal view returns (uint power) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
        FixedPoint.uq112x112 memory rayOfPerUsdt = FixedPoint.fraction(reserve1, reserve0);

        power = amount
        .mul(RayBase.POWER_BASE)
        .div(uint(rayOfPerUsdt.mul(RayBase.RAY_POW).decode144()))
        .div(RayBase.POWER_PRICE);

        uint powerT = power.div(RayBase.POWER_BASE);

        // 算力满送
        if (powerT >= 10000) {
            power = power.mul(115).div(100);
        } else if (powerT >= 5000) {
            power = power.mul(112).div(100);
        } else if (powerT >= 1000) {
            power = power.mul(110).div(100);
        } else if (powerT >= 500) {
            power = power.mul(108).div(100);
        } else if (powerT >= 200) {
            power = power.mul(105).div(100);
        } else if (powerT >= 100) {
            power = power.mul(103).div(100);
        }
    }

    function mine(
        uint32 dts,
        uint32 uLastDts,
        uint uPower,
        uint nPower,
        Daily.DailyList storage uPowerList,
        Daily.DailyList storage nPowerList
    ) internal view returns (uint value) {
        require(nPower > 0 && uPower > 0, RayBase.M_MINE_EMPTY);

        uint base;
        uint denominator;
        uint nPowerT;
        uint uPowerT;
        uint32 cycles;
        uint32 lastCycles = MAX_UINT32;
        uint32 fromDts;

        if(dts < RayBase.MINE_EXPIRE) {
            fromDts = 0;
        } else {
            fromDts = dts - RayBase.MINE_EXPIRE;
        }

        if (fromDts < uLastDts) {
            fromDts = uLastDts;
        }
        value = 0;

        for (uint32 i = fromDts; i < dts; i++) {
            if ((nPowerT = nPower.sub(scanInvalid(nPowerList, i, RayBase.POWER_EXPIRE))) > 0) {
                cycles = i / RayBase.CUT_CYCLE;
                if (cycles != lastCycles) {
                    lastCycles = cycles;

                    // 算数优化 分子 0.3 => 3. 0.7 => 7;
                    base = SEVEN ** cycles * RayBase.RAY_TOTAL_WITH_DEC * THREE;

                    // 算数优化 分母 3 => 0.3, 7 => 0.7
                    denominator = RayBase.CUT_CYCLE * TEN ** cycles * TEN;
                }
                uPowerT = uPower.sub(scanInvalid(uPowerList, i, RayBase.POWER_EXPIRE));
                value += base * uPowerT / nPowerT / denominator;
            }
        }
    }


    function unmined(uint32 dts) internal pure returns (uint){
        uint base;
        uint denominator;
        uint32 cycles = dts / RayBase.CUT_CYCLE;
        uint32 mDays;

        uint value = 0;

        for (uint32 i = 0; i <= cycles; i++) {

            mDays = RayBase.CUT_CYCLE;
            if (i == cycles) {
                mDays = dts % RayBase.CUT_CYCLE;
            }

            // 算数优化 分子 0.3 => 3. 0.7 => 7;
            base = SEVEN ** i * RayBase.RAY_TOTAL_WITH_DEC * THREE;

            // 算数优化 分母 3 => 0.3, 7 => 0.7
            denominator = RayBase.CUT_CYCLE * TEN ** i * TEN;

            value += base * mDays / denominator;
        }
        return RayBase.RAY_TOTAL_WITH_DEC - value;
    }

    function addPower(Daily.DailyList storage dl, uint power, uint32 dts) internal {
        if (dl.size > 0) {
            Daily.DailyItem storage item = dl.last();
            if (item.dts == dts) {
                item.addValue(power);
                return;
            }
        }
        if (dl.cap == 0) {
            dl.cap = uint16(RayBase.POWER_LIST_CAP);
        }
        dl.push(power, dts);
    }

    function rmExpire(Daily.DailyList storage dl, uint32 dts) internal returns (uint){
        (uint cutValue, uint16 count) = scanAndCountExpire(dl, dts, RayBase.POWER_EXPIRE_LIST);
        while (count > 0) {
            dl.shift();
            count --;
        }
        return cutValue;
    }

    function scanInvalid(Daily.DailyList storage dl, uint32 dts, uint32 expire) internal view returns (uint cutValue) {
        cutValue = 0;
        bool next = true;
        uint16 cursor = 0;
        Daily.DailyItem storage item;
        while (next) {
            (item, cursor) = dl.next(cursor);
            if (next = (cursor != MAX_UINT16 && dts > item.dts && dts - item.dts >= expire)) {
                cutValue += item.value;
            }
        }
        next = true;
        cursor = 0;
        while (next) {
            (item, cursor) = dl.nextR(cursor);
            if (next = (cursor != MAX_UINT16 && dts < item.dts)) {
                cutValue += item.value;
            }
        }
    }

    function scanAndCountExpire(Daily.DailyList storage dl, uint32 dts, uint32 expire) internal view returns (uint cutValue, uint16 count) {
        (count,cutValue) = (0, 0);
        bool next = true;
        uint16 cursor = 0;
        Daily.DailyItem storage item;
        while (next) {
            (item, cursor) = dl.next(cursor);
            if (next = (cursor != MAX_UINT16 && dts > item.dts && dts - item.dts >= expire)) {
                count ++;
                cutValue += item.value;
            }
        }
    }
}

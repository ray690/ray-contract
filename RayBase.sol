pragma solidity =0.6.6;

library RayBase {

    // ray名称
    string  internal constant NAME = "Ray";

    // ray标识
    string internal constant SYMBOL = "Ray";

    // ray总量
    uint internal constant RAY_TOTAL = 21000000;

    // ray精度
    uint8 internal constant RAY_DECIMALS = 6;

    // ray精度乘数
    uint internal constant RAY_POW = 10 ** uint(RAY_DECIMALS);

    // ray包含精度总量
    uint internal constant RAY_TOTAL_WITH_DEC = RAY_TOTAL * RAY_POW;

    // 出币递减周期（天）
    uint32 internal constant CUT_CYCLE = 600;

    // 收益提取有效期（天），过期销毁
    uint32  internal constant MINE_EXPIRE = 2;

    // 算力价格(USDT)
    uint internal constant POWER_PRICE = 10;

    // 单位算力在合约中的值
    uint8 internal constant POWER_DEC = 12;

    // 单位算力在合约中的值
    uint internal constant POWER_BASE = 10 ** uint(POWER_DEC);

    // 算力有效期
    uint32  internal constant POWER_EXPIRE = 300;

    // 算力在状态变量中保留的有效期，过期不再记录
    uint32  internal constant POWER_EXPIRE_LIST = POWER_EXPIRE + MINE_EXPIRE;

    // 算力列表数组额定容量
    uint32  internal constant POWER_LIST_CAP = POWER_EXPIRE + MINE_EXPIRE + 8;

    // 创世算力限额
    uint  internal  constant CREATION_POWER = 60000 * POWER_BASE;

    // GMT+8时区偏移秒数
    uint internal constant GMT_8_OFFSET =  8 * 3600;

    // 信息：身份认证不通过
    string internal constant M_AUTHENTICATION = "AUTHENTICATION";

    // 信息：没有收益可以提取
    string internal constant M_MINE_EMPTY = "MINE_EMPTY";

    // 信息：收益提取时间未到
    string internal constant M_MINE_NOT_YET = "MINE_NOT_YET";

    // 信息：创世算力已发完
    string internal constant M_CREATION_POWER_OUT = "CREATION_POWER_OUT";

    function zeroGmt8(uint ts) pure internal returns (uint utc8Ts){
        ts = ts + GMT_8_OFFSET;
        utc8Ts = ts - ts % 86400 - GMT_8_OFFSET;
    }

    function daysBetween(uint from, uint to) pure internal returns (uint32 dts){
        dts = uint32((to - from) / 86400);
    }
}

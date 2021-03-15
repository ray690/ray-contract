pragma solidity =0.6.6;

import './RayBase.sol';

library Daily {

    struct DailyItem {
        uint value;
        uint32 dts;
    }

    struct DailyList {
        DailyItem[310] items;
        uint16 cap;
        uint16 size;
        uint16 bot;
        uint16 top;
    }

    function addValue(DailyItem storage item, uint value) internal {
        item.value += value;
    }

    function first(DailyList storage dl) internal view returns (DailyItem storage item) {
        item = dl.items[dl.bot];
    }

    function last(DailyList storage dl) internal view returns (DailyItem storage item){
        item = dl.items[dl.top - 1];
    }

    function push(DailyList storage dl, DailyItem memory item) internal {
        if (dl.top == 0) {
            dl.top = 1;
        } else {
            if (dl.top == dl.cap) {
                dl.top = 0;
            }
            if (dl.bot == dl.top) {
                dl.bot++;
                if (dl.bot == dl.cap) {
                    dl.bot = 0;
                }
            }
            dl.top++;
        }
        dl.items[dl.top - 1] = item;
        if (dl.size < dl.cap) {
            dl.size++;
        }
    }

    function push(DailyList storage dl, uint value, uint32 dts) internal {
        (uint16 bot,uint16 top, uint16 cap, uint16 size) = (dl.bot, dl.top, dl.cap, dl.size);

        if (top == 0) {
            top = 1;
        } else {
            if (top == cap) {
                top = 0;
            }
            if (bot == top) {
                bot++;
                if (bot == cap) {
                    bot = 0;
                }
            }
            top++;
        }
        DailyItem storage item = dl.items[top - 1];
        item.value = value;
        item.dts = dts;
        if (size < cap) {
            dl.size = size + 1;
        }
        (dl.bot, dl.top) = (bot, top);
    }

    function shift(DailyList storage dl) internal {
        if (dl.size > 0) {
            dl.bot++;
            if (dl.bot == dl.top) {
                dl.bot = 0;
                dl.top = 0;
            } else if (dl.bot == dl.cap) {
                dl.bot = 0;
            }
            dl.size --;
        }
    }

    function next(DailyList storage dl, uint16 i) internal view returns (DailyItem storage item, uint16 cursor){
        uint16 ii = dl.bot + i;
        if (i >= dl.size) {
            cursor = 0xFFFF;
            ii = 0;
        } else {
            if (ii >= dl.cap) {
                ii -= dl.cap;
            }
            cursor = i + 1;
        }
        item = dl.items[ii];
    }

    function nextR(DailyList storage dl, uint16 i) internal view returns (DailyItem storage item, uint16 cursor){
        uint16 ii;
        if (i >= dl.size) {
            cursor = 0xFFFF;
            ii = 0;
        } else {
            if (i >= dl.top) {
                ii = dl.cap + dl.top - i - 1;
            } else {
                ii = ii = dl.top - i - 1;
            }
            cursor = i + 1;
        }
        item = dl.items[ii];
    }

}

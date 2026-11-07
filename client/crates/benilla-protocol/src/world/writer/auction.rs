//! The auction house sends. Each carries the auctioneer guid, and the server re-checks the 5 yd
//! range on each (`GetCheckedAuctionHouseForAuctioneer`). Sell, bid and cancel answer
//! `SMSG_AUCTION_COMMAND_RESULT`, but some refusals are silent: a zero bid or duration, an
//! unaffordable bid or cancel cut, and a list request while one is in flight.

use anyhow::Result;

use crate::messages::{self, opcode};

use super::WorldWriter;

impl WorldWriter {
    /// Greet an auctioneer; the reply, carrying the `AuctionHouse.dbc` id, opens the window.
    pub fn auction_hello(&mut self, auctioneer: u64) -> Result<()> {
        self.send(
            opcode::MSG_AUCTION_HELLO,
            &messages::auction_hello(auctioneer),
        )
    }

    /// Ask a Browse page; unset filters are [`messages::auction_filter`]'s sentinels, no sort rides
    /// the wire, and `list_from` pages by [`messages::AUCTION_PAGE_SIZE`].
    pub fn auction_list_items(
        &mut self,
        auctioneer: u64,
        list_from: u32,
        searched_name: &str,
        level_min: u8,
        level_max: u8,
        slot_id: u32,
        main_category: u32,
        sub_category: u32,
        quality: u32,
        usable: u8,
    ) -> Result<()> {
        self.send(
            opcode::CMSG_AUCTION_LIST_ITEMS,
            &messages::auction_list_items(
                auctioneer,
                list_from,
                searched_name,
                level_min,
                level_max,
                slot_id,
                main_category,
                sub_category,
                quality,
                usable,
            ),
        )
    }

    /// Ask a page of our own auctions (`CMSG_AUCTION_LIST_OWNER_ITEMS`).
    pub fn auction_list_owner_items(&mut self, auctioneer: u64, list_from: u32) -> Result<()> {
        self.send(
            opcode::CMSG_AUCTION_LIST_OWNER_ITEMS,
            &messages::auction_list_owner_items(auctioneer, list_from),
        )
    }

    /// Ask a Bid tab page (`CMSG_AUCTION_LIST_BIDDER_ITEMS`). `auction_ids` is a refresh set, not
    /// a filter: the server lists those first, then every auction we are the current bidder on.
    pub fn auction_list_bidder_items(
        &mut self,
        auctioneer: u64,
        list_from: u32,
        auction_ids: &[u32],
    ) -> Result<()> {
        self.send(
            opcode::CMSG_AUCTION_LIST_BIDDER_ITEMS,
            &messages::auction_list_bidder_items(auctioneer, list_from, auction_ids),
        )
    }

    /// List an item; `etime_minutes` is 120, 480 or 1440, and the deposit is charged at once.
    pub fn auction_sell_item(
        &mut self,
        auctioneer: u64,
        item_guid: u64,
        bid: u32,
        buyout: u32,
        etime_minutes: u32,
    ) -> Result<()> {
        self.send(
            opcode::CMSG_AUCTION_SELL_ITEM,
            &messages::auction_sell_item(auctioneer, item_guid, bid, buyout, etime_minutes),
        )
    }

    /// Bid on an auction; a `price` at or above a nonzero buyout is the buyout.
    pub fn auction_place_bid(
        &mut self,
        auctioneer: u64,
        auction_id: u32,
        price: u32,
    ) -> Result<()> {
        self.send(
            opcode::CMSG_AUCTION_PLACE_BID,
            &messages::auction_place_bid(auctioneer, auction_id, price),
        )
    }

    /// Cancel one of our auctions; the deposit is forfeit, and with a bid the seller pays 5%.
    pub fn auction_remove_item(&mut self, auctioneer: u64, auction_id: u32) -> Result<()> {
        self.send(
            opcode::CMSG_AUCTION_REMOVE_ITEM,
            &messages::auction_remove_item(auctioneer, auction_id),
        )
    }
}

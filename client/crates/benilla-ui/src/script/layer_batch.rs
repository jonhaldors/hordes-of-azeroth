//! A layer batch's End (`0x7731a0`): the texture quads of one batch
//! ([`crate::order::quad_batch`]), in the order it filled, sorted by texture handle with the CRT
//! `qsort` (`0x73f727`, [`crate::crt::qsort_with_stack`]; width `0x1c`, comparator `0x7731c0`: the
//! records' first dwords subtracted). The handle is the first dword (`0x772fd0` → `0x770700`): the device texture
//! `[[region+0xcc]+0x140]` of the region's texture object, which regions showing one texture
//! share ([`super::texel`]). The sort is not stable, so a batch of one texture comes out in the
//! CRT's own order, two quads reversed.
//!
//! Deviation: the handle's value is the address of a `CGxTex` (`SMemAlloc(0x54)`, `0x594a96`),
//! which benilla cannot reproduce; each texture ranks instead by a creation stamp, one global
//! sequence number taken when its cache key is first created and taken anew once its last region
//! has let go of it ([`super::texel::Texels`]). On a heap that grows as it allocates, a later
//! device texture sits at a higher address, so the stamp orders textures as their addresses do,
//! as far as anything deterministic can: it parts from them where the heap reuses a freed block
//! or the device recycles a pooled texture of the same size (`0x448531`).

/// One texture quad of the extract: its index in the list, its batch and its texture's rank.
pub(super) struct BatchQuad {
    pub(super) index: usize,
    pub(super) batch: (u64, u64),
    /// The creation stamp ([`super::texel::Texels::stamp`]).
    pub(super) rank: u64,
}

/// Sort every batch of `quads` (in list order, so each batch's run is contiguous) as `0x7731a0`
/// does: each batch's quads trade places and keys, so the list stays ascending.
pub(super) fn sort_batches(
    out: &mut [ExtractedQuad],
    quads: &[BatchQuad],
    memo: &mut BatchSortMemo,
) {
    let mut scratch = Scratch::default();
    let mut sorted = 0;
    for run in quads.chunk_by(|a, b| a.batch == b.batch) {
        // Distinct keys in order are where the CRT leaves them; ties it reorders even sorted.
        if run.windows(2).all(|w| w[0].rank < w[1].rank) {
            continue;
        }
        sort_batch(out, run, &mut scratch, memo.slot(sorted));
        sorted += 1;
    }
    memo.perms.truncate(sorted);
}

#[derive(Clone, Default)]
pub(crate) struct BatchSortMemo {
    perms: Vec<KeyedPerm>,
}

#[derive(Clone, Default)]
struct KeyedPerm {
    keys: Vec<u64>,
    perm: Vec<usize>,
}

impl BatchSortMemo {
    fn slot(&mut self, k: usize) -> &mut KeyedPerm {
        if self.perms.len() <= k {
            self.perms.resize_with(k + 1, KeyedPerm::default);
        }
        &mut self.perms[k]
    }
}

/// The buffers a frame's batch sorts share, allocated once and only if a batch needs sorting.
#[derive(Default)]
struct Scratch {
    stack: Vec<(usize, usize)>,
    zs: Vec<u128>,
    placed: Vec<bool>,
}

fn sort_batch(
    out: &mut [ExtractedQuad],
    run: &[BatchQuad],
    sc: &mut Scratch,
    memo: &mut KeyedPerm,
) {
    let same_keys =
        memo.keys.len() == run.len() && memo.keys.iter().zip(run).all(|(&k, q)| k == q.rank);
    if !same_keys {
        memo.keys.clear();
        memo.keys.extend(run.iter().map(|q| q.rank));
        // `perm[k]` is the original index now at `k`; the comparator `0x7731c0` orders the keys.
        memo.perm.clear();
        memo.perm.extend(0..memo.keys.len());
        let keys = &memo.keys;
        crate::crt::qsort_with_stack(&mut memo.perm, &mut sc.stack, |&a, &b| {
            keys[a].cmp(&keys[b]) as i32
        });
    }
    let perm = &memo.perm;
    if perm.iter().enumerate().all(|(k, &p)| k == p) {
        return;
    }
    sc.zs.clear();
    sc.zs.extend(run.iter().map(|q| out[q.index].z));
    // Apply `new[k] = old[perm[k]]` cycle by cycle, then hand the keys back in order.
    sc.placed.clear();
    sc.placed.resize(run.len(), false);
    for start in 0..run.len() {
        let mut k = start;
        while !sc.placed[k] {
            sc.placed[k] = true;
            let next = perm[k];
            if next == start {
                break;
            }
            out.swap(run[k].index, run[next].index);
            k = next;
        }
    }
    for (q, &z) in run.iter().zip(&sc.zs) {
        out[q.index].z = z;
    }
}

use super::ExtractedQuad;

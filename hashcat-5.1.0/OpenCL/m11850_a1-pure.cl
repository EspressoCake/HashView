/**
 * Author......: See docs/credits.txt
 * License.....: MIT
 */

//#define NEW_SIMD_CODE

#include "inc_vendor.cl"
#include "inc_hash_constants.h"
#include "inc_hash_functions.cl"
#include "inc_types.cl"
#include "inc_common.cl"
#include "inc_scalar.cl"
#include "inc_hash_streebog512.cl"

__kernel void m11850_mxx (KERN_ATTR_BASIC ())
{
  /**
   * modifier
   */

  const u64 gid = get_global_id (0);
  const u64 lid = get_local_id (0);
  const u64 lsz = get_local_size (0);

  /**
   * shared lookup table
   */

  #ifdef REAL_SHM

  __local u64a s_sbob_sl64[8][256];

  for (MAYBE_VOLATILE u32 i = lid; i < 256; i += lsz)
  {
    s_sbob_sl64[0][i] = sbob_sl64[0][i];
    s_sbob_sl64[1][i] = sbob_sl64[1][i];
    s_sbob_sl64[2][i] = sbob_sl64[2][i];
    s_sbob_sl64[3][i] = sbob_sl64[3][i];
    s_sbob_sl64[4][i] = sbob_sl64[4][i];
    s_sbob_sl64[5][i] = sbob_sl64[5][i];
    s_sbob_sl64[6][i] = sbob_sl64[6][i];
    s_sbob_sl64[7][i] = sbob_sl64[7][i];
  }

  barrier (CLK_LOCAL_MEM_FENCE);

  #else

  __constant u64a (*s_sbob_sl64)[256] = sbob_sl64;

  #endif

  if (gid >= gid_max) return;

  /**
   * base
   */

  const u32 pw_len = pws[gid].pw_len & 255;

  u32 w[64] = { 0 };

  for (int i = 0, idx = 0; i < pw_len; i += 4, idx += 1)
  {
    w[idx] = swap32_S (pws[gid].i[idx]);
  }

  const u32 salt_len = salt_bufs[salt_pos].salt_len;

  u32 s[64] = { 0 };

  for (int i = 0, idx = 0; i < salt_len; i += 4, idx += 1)
  {
    s[idx] = swap32_S (salt_bufs[salt_pos].salt_buf[idx]);
  }

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < il_cnt; il_pos++)
  {
    const u32 comb_len = combs_buf[il_pos].pw_len;

    u32 c[64];

    #ifdef _unroll
    #pragma unroll
    #endif
    for (int idx = 0; idx < 64; idx++)
    {
      c[idx] = swap32_S (combs_buf[il_pos].i[idx]);
    }

    switch_buffer_by_offset_1x64_be_S (c, pw_len);

    #ifdef _unroll
    #pragma unroll
    #endif
    for (int i = 0; i < 64; i++)
    {
      c[i] |= w[i];
    }

    streebog512_hmac_ctx_t ctx;

    streebog512_hmac_init (&ctx, c, pw_len + comb_len, s_sbob_sl64);

    streebog512_hmac_update (&ctx, s, salt_len);

    streebog512_hmac_final (&ctx);

    const u32 r0 = l32_from_64_S (ctx.opad.h[0]);
    const u32 r1 = h32_from_64_S (ctx.opad.h[0]);
    const u32 r2 = l32_from_64_S (ctx.opad.h[1]);
    const u32 r3 = h32_from_64_S (ctx.opad.h[1]);

    COMPARE_M_SCALAR (r0, r1, r2, r3);
  }
}

__kernel void m11850_sxx (KERN_ATTR_BASIC ())
{
  /**
   * modifier
   */

  const u64 gid = get_global_id (0);
  const u64 lid = get_local_id (0);
  const u64 lsz = get_local_size (0);

  /**
   * shared lookup table
   */

  #ifdef REAL_SHM

  __local u64a s_sbob_sl64[8][256];

  for (MAYBE_VOLATILE u32 i = lid; i < 256; i += lsz)
  {
    s_sbob_sl64[0][i] = sbob_sl64[0][i];
    s_sbob_sl64[1][i] = sbob_sl64[1][i];
    s_sbob_sl64[2][i] = sbob_sl64[2][i];
    s_sbob_sl64[3][i] = sbob_sl64[3][i];
    s_sbob_sl64[4][i] = sbob_sl64[4][i];
    s_sbob_sl64[5][i] = sbob_sl64[5][i];
    s_sbob_sl64[6][i] = sbob_sl64[6][i];
    s_sbob_sl64[7][i] = sbob_sl64[7][i];
  }

  barrier (CLK_LOCAL_MEM_FENCE);

  #else

  __constant u64a (*s_sbob_sl64)[256] = sbob_sl64;

  #endif

  if (gid >= gid_max) return;

  /**
   * digest
   */

  const u32 search[4] =
  {
    digests_buf[digests_offset].digest_buf[DGST_R0],
    digests_buf[digests_offset].digest_buf[DGST_R1],
    digests_buf[digests_offset].digest_buf[DGST_R2],
    digests_buf[digests_offset].digest_buf[DGST_R3]
  };

  /**
   * base
   */

  const u32 pw_len = pws[gid].pw_len & 255;

  u32 w[64] = { 0 };

  for (int i = 0, idx = 0; i < pw_len; i += 4, idx += 1)
  {
    w[idx] = swap32_S (pws[gid].i[idx]);
  }

  const u32 salt_len = salt_bufs[salt_pos].salt_len;

  u32 s[64] = { 0 };

  for (int i = 0, idx = 0; i < salt_len; i += 4, idx += 1)
  {
    s[idx] = swap32_S (salt_bufs[salt_pos].salt_buf[idx]);
  }

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < il_cnt; il_pos++)
  {
    const u32 comb_len = combs_buf[il_pos].pw_len;

    u32 c[64];

    #ifdef _unroll
    #pragma unroll
    #endif
    for (int idx = 0; idx < 64; idx++)
    {
      c[idx] = swap32_S (combs_buf[il_pos].i[idx]);
    }

    switch_buffer_by_offset_1x64_be_S (c, pw_len);

    #ifdef _unroll
    #pragma unroll
    #endif
    for (int i = 0; i < 64; i++)
    {
      c[i] |= w[i];
    }

    streebog512_hmac_ctx_t ctx;

    streebog512_hmac_init (&ctx, c, pw_len + comb_len, s_sbob_sl64);

    streebog512_hmac_update (&ctx, s, salt_len);

    streebog512_hmac_final (&ctx);

    const u32 r0 = l32_from_64_S (ctx.opad.h[0]);
    const u32 r1 = h32_from_64_S (ctx.opad.h[0]);
    const u32 r2 = l32_from_64_S (ctx.opad.h[1]);
    const u32 r3 = h32_from_64_S (ctx.opad.h[1]);

    COMPARE_S_SCALAR (r0, r1, r2, r3);
  }
}
